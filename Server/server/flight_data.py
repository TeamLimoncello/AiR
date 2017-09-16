import time
import re
import requests
from pyproj import Geod


fa_api_key = 'd499582d8f88245d34324afa83107671b67cbc33'
fa_url = 'https://flightxml.flightaware.com/json/FlightXML3/'
fa_username = 'lewisbell999'


def fa_get_request(link, params):
    response = requests.get(fa_url + link,
                            params=params,
                            auth=(fa_username, fa_api_key))
    if response.status_code not in range(200,299):
        raise IOError('error: {}'.format(response.text))
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
    try:
        return result['AirlineFlightSchedulesResult']['flights'][0]
    except IndexError:
        return None


def get_this_flight(raw_flight, flight_date):
    flight_num = re.match(r'([A-Z]{3})([0-9]{1,4})([A-Za-z]?)',
                          raw_flight)
    result = fa_get_request('AirlineFlightSchedules', {
        'end_date': str(flight_date.timestamp() + 86400),
        'start_date': str(flight_date.timestamp()),
        'airline': flight_num[1],
        'flightno': flight_num[2],
        'howMany': 1,
    })
    try:
        return result['AirlineFlightSchedulesResult']['flights'][0]
    except IndexError:
        return None


def flight_ident(flight):
    return str(flight['ident']) + "@" + str(flight['departuretime'])


def get_flight_path(ident):
    result = fa_get_request('GetFlightTrack', {'ident': ident})
    if result is None:
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
    flight_code, flight_date = flight_id_query
    existing_path = db.execute(
        'SELECT path FROM flightPaths '
        'WHERE flightCode=? AND expires>?',
        [flight_code, int(time.time())]
    ).fetchone()
    if existing_path:
        return existing_path["path"]
    past_flight = get_flight_history(flight_code)
    if past_flight is None:
        db.execute(
            'UPDATE flightIDs SET progress=0.05 WHERE flightCode=?',
            [flight_code])
        db.commit()
        # do some fancy (Geod.npts from pyproj) interpolation:
        # flighttime/2min data points. Assume constant speed
        this_flight = get_this_flight(flight_code, flight_date)
        if this_flight is None:
            db.execute(
                'UPDATE flightIDs SET invalid=1 WHERE id=?',
                [flight_id])
            return
        db.execute(
            'UPDATE flightIDs SET progress=0.1 WHERE flightCode=?',
            [flight_code])
        db.commit()
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
                'UPDATE flightIDs SET invalid=1 WHERE id=?',
                [flight_id])
            raise NameError(flight_id)
    else:
        db.execute(
            'UPDATE flightIDs SET progress=0.1 WHERE flightCode=?',
            [flight_code])
        db.commit()
        ident = flight_ident(past_flight)
        path = print_flight_path(process_flight_path(get_flight_path(ident)))
        origin = openflights_post_request({
            'icao': past_flight["origin"],
            'db': 'airports',
        })['airports'][0]
        destination = openflights_post_request({
            'icao': past_flight["destination"],
            'db': 'airports',
        })['airports'][0]

    db.execute(
        'INSERT OR REPLACE INTO flightPaths '
        '(flightCode, origin, originCode, destination, destinationCode, expires, path) '
        'VALUES (?,?,?,?,?,?,?)',
        [flight_code, origin['name'], origin['iata'], destination['name'], destination['iata'],
         int(time.time()+2592000), path])
    db.commit()
    return path

