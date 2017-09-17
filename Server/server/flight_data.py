import time
from datetime import datetime
import re
import requests
from pyproj import Geod


fa_api_key = 'e460788778fda62e665483a4abf1c46486e41851'
fa_url = 'https://flightxml.flightaware.com/json/FlightXML3/'
fa_username = 'xsanda'


def fa_get_request(link, params):
    response = requests.get(fa_url + link,
                            params=params,
                            auth=(fa_username, fa_api_key))
    if response.status_code not in range(200,299):
        print('error {}: {}'.format(response.status_code, response.text))
        return None
    return response.json()


def openflights_post_request(data):
    link = 'https://openflights.org/php/apsearch.php'
    response = requests.post(link, data=data)
    if response.status_code not in range(200,299):
        raise IOError('error: %s' % response.text)
    return response.json()


def get_flight_history(raw_flight):
    flight_num = re.match(r'([A-Z]{3})([0-9]{1,4})([A-Za-z]?)',
                          raw_flight)
    result = fa_get_request('AirlineFlightSchedules', {
        'start_date': str(int(time.time()-86400*8)),
        'end_date': str(int(time.time()-86400)),
        'airline': flight_num[1],
        'flightno': flight_num[2],
        'howMany': 1,
    })
    if result is None:
        return None
    try:
        return result['AirlineFlightSchedulesResult']['flights'][0]
    except IndexError:
        return None


def get_this_flight(raw_flight, flight_date):
    flight_num = re.match(r'([A-Z]{3})([0-9]{1,4})([A-Za-z]?)',
                          raw_flight)
    result = fa_get_request('AirlineFlightSchedules', {
        'end_date': str(int(flight_date.timestamp()) + 86400),
        'start_date': str(int(flight_date.timestamp())),
        'airline': flight_num[1],
        'flightno': flight_num[2],
        'howMany': 1,
    })
    if result is None:
        print(flight_date)
        print(str(int(flight_date.timestamp())))
        return None
    try:
        return result['AirlineFlightSchedulesResult']['flights'][0]
    except IndexError:
        return None


def flight_ident(flight):
    return str(flight['ident']) + "@" + str(flight['departuretime'])


def get_flight_path(ident):
    result = fa_get_request('GetFlightTrack', {'ident': ident})
    if result is None or "GetFlightTrackResult" not in result:
        return None
    return result['GetFlightTrackResult']['tracks']


def process_flight_path(json_path):
    initial = json_path[0]["timestamp"]
    recent = 0
    points = []
    prev = json_path[0]

    def convert(point):
        return {
            "latitude": point["latitude"],
            "longitude": point["longitude"],
            "altitude": point["altitude"],
            "timestamp": point["timestamp"] - initial,
        }

    for json_point in json_path[1:]:
        if json_point["timestamp"] > recent + 180:
            points.append(convert(prev))
            recent = prev["timestamp"]
        prev = json_point
    points.append(convert(json_path[-1]))
    return points


def print_flight_path(path):
    csv = ''
    for point in path:
        csv += (str(point['timestamp']) + ','
                + str(point['latitude']) + ','
                + str(point['longitude']) + ','
                + str(point['altitude']) + '\n')
    return csv


def load_flight(db, flight_id):
    flight_id_query = db.execute(
        'SELECT flightCode, date FROM flightIDs WHERE id=?',
        [flight_id]).fetchone()
    if not flight_id_query:
        raise NameError(flight_id)
    flight_code, raw_date = flight_id_query
    flight_date = datetime.strptime(raw_date, '%Y-%m-%d')
    existing_path = db.execute(
        'SELECT path FROM flightPaths '
        'WHERE flightCode=? AND expires>?',
        [flight_code, int(time.time())]
    ).fetchone()
    if existing_path:
        return existing_path["path"]
    past_flight = get_flight_history(flight_code)
    if past_flight is None:
        # do some fancy (Geod.npts from pyproj) interpolation:
        # flighttime/2min data points. Assume constant speed
        this_flight = get_this_flight(flight_code, flight_date)
        if this_flight is None:
            db.execute(
                'UPDATE flightIDs SET invalid=? WHERE id=?',
                ["No flight for given day", flight_id])
            db.commit()
            return
        origin = this_flight['origin']
        destination = this_flight['destination']
        duration = this_flight['arrivaltime'] - this_flight['departuretime']
        try:
            origin_data = openflights_post_request({
                'icao': origin,
                'db': 'airports',
            })['airports'][0]
            destination_data = openflights_post_request({
                'icao': destination,
                'db': 'airports',
            })['airports'][0]
            points = Geod().npts(
                float(origin_data['y']),
                float(destination_data['y']),
                float(origin_data['x']),
                float(destination_data['x']),
                float(duration/180),
            )
            path = ''
            for i, (long,lat) in enumerate(points):
                path += '{},{},{},{}\n'.format(
                    duration/len(points), lat, long, 350)
        except (IndexError, KeyError) as a:
            db.execute(
                'UPDATE flightIDs SET invalid=? WHERE id=?',
                ["Unable to prepare flight path for this flight", flight_id])
            db.commit()
            raise NameError(flight_id)
    else:
        ident = flight_ident(past_flight)
        path = print_flight_path(process_flight_path(get_flight_path(ident)))
        this_flight = get_this_flight(flight_code, flight_date)
        if this_flight is None:
            db.execute(
                'UPDATE flightIDs SET invalid=? WHERE id=?',
                ["No flight for given day", flight_id])
            db.commit()
            return
        origin = openflights_post_request({
            'icao': this_flight["origin"],
            'db': 'airports',
        })['airports'][0]
        destination = openflights_post_request({
            'icao': this_flight["destination"],
            'db': 'airports',
        })['airports'][0]

    departure_time = this_flight['departuretime']

    db.execute('UPDATE flightIDs SET departureTime=? WHERE id=?',
               [departure_time, flight_id])
    db.execute(
        'INSERT OR REPLACE INTO flightPaths '
        '(flightCode, origin, originCode, originLat, originLong, '
        'destination, destinationCode, destinationLat, destinationLong, expires, path) '
        'VALUES (?,?,?,?,?,?,?,?,?,?,?)',
        [flight_code, origin['name'], origin['iata'], origin['y'], origin['x'],
         destination['name'], destination['iata'], destination['y'], destination['x'],
         int(time.time()+2592000), path])
    db.commit()
    return path
