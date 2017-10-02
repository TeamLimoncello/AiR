from datetime import datetime
import re
import secrets

import requests
from celery import Celery, group as celery_group
from flask import Flask, Response, request, g
import json
import os
import sqlite3
from PIL import Image
from io import BytesIO

from server import flight_data, tile_geometry
from server.tile_geometry import frange

app = Flask(__name__)
app.config['APPLICATION_ROOT'] = '/api/v1'

app.config.update(
    CELERY_BROKER_URL='pyamqp://guest@localhost//',
    CELERY_RESULT_BACKEND='rpc://'
)


def make_celery(app):
    """
    Make the celery instance with the correct configuration.
    :param app: The Flask App instance
    :return: The celery instance created
    """

    celery = Celery(app.import_name, backend=app.config['CELERY_RESULT_BACKEND'],
                    broker=app.config['CELERY_BROKER_URL'])
    celery.conf.update(app.config)
    TaskBase = celery.Task

    class ContextTask(TaskBase):
        abstract = True

        def __call__(self, *args, **kwargs):
            with app.app_context():
                return TaskBase.__call__(self, *args, **kwargs)

    celery.Task = ContextTask
    return celery

#Create the celery instance
celery = make_celery(app)


@app.route('/api/v1/')
def foo():
    '''
    Metadata about the API.
    :return: The current API version
    '''
    obj = {
        'version': '1.0',
    }
    return send_json(obj)


@app.route('/api/v1/register', methods=['POST'])
def register():
    """
    Register a flight.
    POST data: date (YYYY-MM-DD)
               flightNumber (IATA AAA1111[a])
    :return: The passenger/device's ID.
    """
    try:
        raw_date = request.form['date']
        datetime.strptime(raw_date, '%Y-%m-%d')
    except (KeyError, ValueError):
        return send_json({'code': 1, 'string': 'Bad Date'}, 400)
    try:
        raw_flight = request.form['flightNumber']
        flight_num = re.match(r'([A-Z]{3})([0-9]{1,4})([A-Za-z]?)',
                              raw_flight)
        if flight_num is None:
            raise ValueError('Invalid flight number')
    except (KeyError, ValueError):
        return send_json({'code': 2, 'string': 'Bad flight number'}, 400)
    db = get_db()
    while True:
        id = str(secrets.token_urlsafe(12))
        app.logger.info(str(id))
        c = db.execute('SELECT COUNT(*) FROM flightIDs WHERE id=?', [id])
        if c.fetchone()[0] is 0:
            break
    db.execute('INSERT INTO flightIDs (id, flightCode, date) VALUES (?,?,?)',
               [id, raw_flight, raw_date])
    db.commit()
    load_data.delay(id)
    return send_string(id)


@app.route('/api/v1/fetch/<ref_id>')
def fetch(ref_id):
    """
    Get the progress of a given ID.
    :param ref_id: The passenger/device ID.
    :return: 403 if flight unrecognised.
             404 if flight is not a valid flight.
             503 if the data is not all ready, 200 if data is, with following content as JSON:
                meta: flightCode,date,departureTime,origin,originCode,originLat,originLong,destination,destinationCode,
                      destinationLat,destinationLong
                path: flightpath as CSV
                landmarks: [(name,lat,long,model_name,description,height,established)]
                cities: cites with their weather.
                progress: a number from 0 to 1, where 1 means all ready (status 200), 0 means nothing ready (and so no
                          other fields are present), all else meaning tiles are still loading (status 503).
                tiles: [(alat,along,blat,blong,image,tag)]. If progress != 200, there are still more to load.

    """
    db = get_db()
    c = db.execute('SELECT flightIDs.flightCode AS flightCode, date, '
                   'tiles, loaded, invalid, path, origin, destination, '
                   'originCode, destinationCode, departureTime, '
                   'originLat, originLong, destinationLat, destinationLong '
                   'FROM flightIDs LEFT JOIN flightPaths '
                   'ON flightIDs.flightCode = flightPaths.flightCode '
                   'WHERE id=?',
                   [ref_id])
    flight = c.fetchone()
    if flight is None:
        return '', 403
    if flight['invalid']:
        return flight['invalid'], 404
    if flight['tiles'] == None:
        return send_json({'progress': 0}, 503)
    progress = flight['loaded'] / flight['tiles']
    csv_path = map(lambda row: row.split(','), flight["path"].rstrip().split('\n'))
    cities = {}
    for i, row in enumerate(csv_path):
        try:
            csv_lat = row[1]
            csv_long = row[2]
        except IndexError:
            print('Error at {}'.format(i))
        d = db.execute('SELECT id, name, lat, long, population, name_en '
                       'FROM cities WHERE (lat - ?) BETWEEN (-1) AND 1 AND (long - ?) BETWEEN (-1) AND 1',
                       [csv_lat, csv_long])
        for city in d.fetchall():
            cities[city['id']] = {
                'name': city['name'],
                'lat': city['lat'],
                'long': city['long'],
                'population': city['population'],
                'name_en': city['name_en'],
                'weather': {}
            }
    if progress == 1.0:
        tiles = db.execute('SELECT file, alat, along, blat, blong, tag '
                           'FROM tiles WHERE id=?',
                           [ref_id]).fetchall()
    else:
        tiles = []
    return send_json({
        'meta': {
            'flightCode': flight['flightCode'],
            'date': flight['date'],
            'departureTime': flight['departureTime'],
            'origin': flight['origin'],
            'originCode': flight['originCode'],
            'originLat': flight['originLat'],
            'originLong': flight['originLong'],
            'destination': flight['destination'],
            'destinationCode': flight['destinationCode'],
            'destinationLat': flight['destinationLat'],
            'destinationLong': flight['destinationLong'],
        },
        'path': flight["path"],
        "landmarks": [
            {
                'name': 'Clifton Suspension Bridge',
                'lat': 51.4549,
                'long': -2.6278,
                'model_name': 'CliftonSuspensionBridge',
                'description': "The Clifton Suspension Bridge is a suspension bridge spanning the Avon Gorge and the "
                               + "River Avon, linking Clifton in Bristol to Leigh Woods in North Somerset. ",
                'height': '75m',
                'established': 'June 21, 1831'
            },
            {
                'name': 'Eiffel Tower',
                'lat': 48.858222,
                'long': 2.2945,
                'model_name': 'EiffelTower',
                'description': "The Eiffel Tower is a wrought iron lattice tower on the Champ de Mars in Paris, "
                               + "France. It is named after the engineer Gustave Eiffel, whose company designed and "
                               + "built the tower. ",
                'height': '300m',
                'established': "1889-03-31"
            },
            {
                'name': 'Colosseum',
                'lat': 41.8902,
                'long': 12.4922,
                'model_name': 'Colosseum',
                'description': "The Colosseum or Coliseum is an oval "
                              + "amphitheatre in the centre of the city of Rome, Italy. Built of concrete and sand, "
                              + "it is the largest amphitheatre ever built. The Colosseum is situated just east of the "
                              + "Roman Forum. Construction began under the emperor Vespasian in AD 72, "
                              + "and was completed in AD 80 under his successor and heir Titus. Further modifications "
                              + "were made during the reign of Domitian (81–96). These three emperors are known as the "
                              + "Flavian dynasty, and the amphitheatre was named in Latin for its association with "
                              + "their family name (Flavius). ",
                'height': '48m',
                'established': '80AD'
            },
            {
                'name': 'Leaning Tower of Pisa',
                'lat': 43.7230,
                'long': 10.3966,
                'model_name': 'Pisa',
                'description': "The Leaning Tower of Pisa (Italian: Torre pendente di Pisa) or simply the Tower of "
                               + "Pisa (Torre di Pisa) is the campanile, or freestanding bell tower, of the cathedral "
                               + "of the Italian city of Pisa, known worldwide for its unintended tilt. ",
                'height': '56m',
                'established': '1372'
            },
            {
                'name': "St Peter's Basilica",
                'lat': 41.9022,
                'long': 12.4539,
                'model_name': 'Basilica',
                'description': "The Papal Basilica of St. Peter in the Vatican, or simply St. Peter's Basilica, "
                               + "is an Italian Renaissance church in Vatican City, the papal enclave within the city "
                               + "of Rome. ",
                'height': '137m',
                'established': '1506'
            }
        ],
        "cities": get_weather(list(cities.values())),
        "progress": progress,
        "tiles": [
            {
                'alat': tile['alat'],
                'along': tile['along'],
                'blat': tile['blat'],
                'blong': tile['blong'],
                'image': '/api/v1/tile/{}/{}.jpg'
                    .format(ref_id, tile['file']),
                'tag': tile['tag'],
            } for tile in tiles
        ]
    }, code=(200 if progress == 1.0 else 503))


@app.route('/api/v1/tile/<ref_id>/<filename>')
def serve_image(ref_id, filename):
    """
    Serve a requested image, if it is assigned to the given user.
    :param ref_id: The passenger/device ID.
    :param filename: The image file name.
    :return: The image as a response.
    """
    db = get_db()
    c = db.execute('SELECT flightCode, date FROM flightIDs WHERE id=?',
                   [ref_id])
    flight = c.fetchone()
    if flight is None:
        return '', 403
    im = Image.open('./imgs/' + filename)
    io = BytesIO()
    im.save(io, format='JPEG')
    return Response(io.getvalue(), mimetype='image/jpeg')


@app.route('/api/v1/reload/<ref_id>')
def reload(ref_id):
    """
    Should trigger reload of weather data; as yet does nothing.
    :param ref_id: The passenger/device ID.
    :return: Success code, no meaningful content.
    """
    return 'reload %s' % ref_id


@app.route('/api/v1/refetch/<ref_id>')
def refetch(ref_id):
    """

    Should fetch reloaded weather data; as yet does nothing.
    :param ref_id: The passenger/device ID.
    :return: Success code, no meaningful content.
    """
    return


def send_json(data, code=200):
    """
    Send a response as JSON.
    :param data: A JSON-serialisable object.
    :param code: A status code, default 200 Success.
    :return: The response, json-encoded and with a JSON MIME type.
    """
    return Response(response=json.dumps(data),
                    status=code,
                    mimetype="application/json")


def send_string(string, code=200):
    """
    Send a response as a string.
    :param string: A string to send.
    :param code: A status code, default 200 Success.
    :return: The response, with a plain text MIME type.
    """
    return Response(response=string,
                    status=code,
                    mimetype="text/plain")


def connect_db():
    """Connects to the specific database."""
    rv = sqlite3.connect(os.path.join(app.root_path, 'database.db'))
    rv.row_factory = sqlite3.Row
    return rv


def get_db():
    """Opens a new database connection if there is none yet for the
    current application context.
    """
    if not hasattr(g, 'sqlite_db'):
        g.sqlite_db = connect_db()
    return g.sqlite_db


def init_db():
    """
    Set up the database, clearing any data and loading the data for cities.
    """
    db = get_db()
    with app.open_resource('schema.sql', mode='r') as f:
        db.cursor().executescript(f.read())
    for f in os.listdir('imgs/'):
        if f != 'img.jpg':
            os.remove('imgs/' + f)
    with open('server/parsed_cities.json') as raw:
        json_data = json.loads(raw.read())
        for city in json_data:
            if city['population'] is None:
                continue
            db.execute('INSERT OR REPLACE INTO cities '
                       '(name, population, lat, long, name_en) '
                       'VALUES (?, ?, ?, ?, ? )',
                       [city['name'],
                        city['population'],
                        city['lat'],
                        city['long'],
                        city['name_en']])
    db.commit()


@app.cli.command('initdb')
def initdb_command():
    """Initializes the database."""
    init_db()
    print('Initialized the database.')


@app.teardown_appcontext
def close_db(error):
    """Closes the database again at the end of the request."""
    if hasattr(g, 'sqlite_db'):
        g.sqlite_db.close()


@celery.task
def load_data(flight_id):
    """
    Cache the data, and then start to load the images.
    :param flight_id:
    :return:
    """
    with connect_db() as db:
        path = flight_data.load_flight(db, flight_id)

        if path is None:
            return

        far_tiler = tile_geometry.Tiler(512)
        tiler = tile_geometry.Tiler(512, radius=1)
        night_tiler = tile_geometry.Tiler(
            zoom=4096, radius=1.5,
            params='LAYERS=ddl.simS3seriesNighttimeLightsGlob.brightness&STYLES=boxfill%2Fgreyscale'
        )
        points = tiler.generate_points(path)
        far_points = far_tiler.generate_points(path) - points
        points = tiler.zoom_by(8, points)
        night_points = night_tiler.generate_points(path)
        grouped_points = tile_geometry.group_points(points)
        far_grouped_points = tile_geometry.group_points(far_points)
        night_grouped_points = tile_geometry.group_points(night_points)
        count = len(grouped_points) + len(night_grouped_points) + len(far_grouped_points)
        db.execute('UPDATE flightIDs SET tiles=? WHERE id=?', [count, flight_id])
        db.commit()
        celery_group(load_group.s(
            flight_id, group, tiler.serialize(), 'day'
        ) for group in grouped_points)()
        celery_group(load_group.s(
            flight_id, group, far_tiler.serialize(), 'day'
        ) for group in far_grouped_points)()
        celery_group(load_group.s(
            flight_id, group, night_tiler.serialize(), 'night'
        ) for group in night_grouped_points)()


def get_weather(cities):
    """
    Get the weather data for each city.
    :param cities: A list of city objects.
    :return: A list of city objects, with the weather set.
    """
    # weather = json.loads(requests.get('http://api.openweathermap.org/data/2.5/forecast', params={
    #     'lat': 48.843186,
    #     'lon': 2.353233,
    #     'appid': '726bacce48baa919814ae45e1306d76c'
    # }).json())['list'][0]
    weather = {
        'main': {
            'temp': 285.15
        },
        'weather': {
            'description': 'Sunny Intervals'
        }
    }
    for city in cities:
        city['weather'] = {
            'temperature': weather['main']['temp']-273.15,
            'weather': weather['weather']['description']
        }
    return cities


@celery.task
def load_group(flight_id, group, tiling, tag):
    """
    Load the imagery for a line of tiles.
    :param flight_id: The flight ID to store the imagery inder.
    :param group: The group of images: (x0,x1,y)
    :param tiling: The parameters of the tiler, decomposed to allow for serialisation.
    :param tag: A tag for the images.
    """
    db = get_db()
    tiler = tile_geometry.Tiler(*tiling)
    bounds = tiler.mercator_bounds(group)
    image = tiler.fetch_group_image(group)
    save_image(db, flight_id, image, *bounds, tag)
    db.execute(
        'UPDATE flightIDs SET loaded=loaded+1 WHERE id=?',
        [flight_id])
    db.commit()
    try:
        db.close()
    except sqlite3.ProgrammingError:
        pass


def save_image(db, flight_id, image, alat, along, blat, blong, tag):
    """
    Save an image file for a map tile.
    :param db: An open database connection.
    :param flight_id: The flight ID to attribute the imagery to.
    :param image: The image itself.
    :param alat: The min latitude of the image.
    :param along: The min longitude of the image.
    :param blat: The max latitude of the image.
    :param blong: The max longitude of the image.
    :param tag: A tag for the image.
    """
    while True:
        file = str(secrets.token_urlsafe(24))
        app.logger.info(str(id))
        c = db.execute('SELECT COUNT(*) FROM tiles WHERE file=?', [file])
        if c.fetchone()[0] is 0:
            break
    db.execute('INSERT INTO tiles (file, id, alat, along, blat, blong, tag)'
               'VALUES (?,?,?,?,?,?,?)',
               [file, flight_id, alat, along, blat, blong, tag])
    db.commit()
    image.save('imgs/{}.jpg'.format(file))
