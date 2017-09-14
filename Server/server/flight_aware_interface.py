import time
import sqlite3
import re
import requests

api_key = 'd499582d8f88245d34324afa83107671b67cbc33'
base_url = 'https://flightxml.flightaware.com/json/FlightXML3/'
username = 'lewisbell999'


def get_request(params, link):
    response = requests.get(base_url+link, params=params, auth=(username, api_key))
    if response.status_code not in range(200,299):
        return 'error: %s' % response.text
    return response.json()


def get_flight_history(raw_flight):
    flight_num = re.match(r'([A-Z]{3})([0-9]{1,4})([A-Za-z]?)',
                          raw_flight)

    params = {
        'end_date': str(int(time.time()-86400)),
        #seconds in a week = 604,800
        'start_date': str(int(time.time()-86400*8)),
        'flightno': flight_num[2],
        'airline': flight_num[1],
        'howMany': 1
    }
    result = get_request(params, 'AirlineFlightSchedules')
    print(result['AirlineFlightSchedulesResult'])
    try:
        return (result['AirlineFlightSchedulesResult']['flights'][0]['ident'] + "@"
                + str(result['AirlineFlightSchedulesResult']['flights'][0]['departuretime']))
    except IndexError:
        return None


def get_flight_path(flight_num):
    ident = get_flight_history(flight_num)
    if ident is None:
        return None
    params = {'ident': ident}
    result = get_request(params,'GetFlightTrack')
    if result is None:
        return None
    return result['GetFlightTrackResult']['tracks']

def process_flight_path(json_path):
    initial = json_path[0]["timestamp"]
    recent = 0
    points = []
    prev = json_path[0]

    def convert(point, initial):
        return {
            "latitude": point["latitude"],
            "longitude": point["longitude"],
            "altitude": point["altitude"],
            "timestamp": point["timestamp"] - initial,
        }

    for json_point in json_path[1:]:
        if json_point["timestamp"] > recent + 180:
            points.append(convert(prev, initial))
            recent = prev["timestamp"]
        prev = json_point
    points.append(convert(json_path[-1], initial))
    return points


def print_flight_path(path):
    csv = ''
    for point in path:
        csv += (str(point['timestamp']) + ','
                   + str(point['latitude']) + ','
                   + str(point['longitude']) + ','
                   + str(point['altitude']) + '\n')
    return csv


def cache(flight_id):
    db = sqlite3.connect('database.db')
    c = db.execute('SELECT path FROM flightPaths WHERE flightCode=? AND expires>?', (flight_id, int(time.time()),))
    result = c.fetchone()
    if result is not None:
        return result['path']
    path = print_flight_path(process_flight_path(get_flight_path(flight_id)))
    db.execute('INSERT OR REPLACE INTO flightPaths (flightCode, expires, path) VALUES (?,?,?)', (flight_id,int(time.time()+2592000), path))
    db.commit()
    db.close()
    return path

