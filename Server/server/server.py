from datetime import datetime
import re
import secrets

from celery import Celery
from flask import Flask, Response, request, g
import json
import os
import sqlite3
from PIL import Image
from io import BytesIO

from server import flight_data, tile_geometry

app = Flask(__name__)
app.config['APPLICATION_ROOT'] = '/api/v1'

app.config.update(
    CELERY_BROKER_URL='pyamqp://guest@localhost//',
    CELERY_RESULT_BACKEND='rpc://'
)


def make_celery(app):
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


celery = make_celery(app)


@app.route('/api/v1/')
def foo():
    obj = {
        'version': '0.2',
    }
    return send_json(obj)


@app.route('/api/v1/register', methods=['POST'])
def register():
    try:
        raw_date = request.form['date']
        datetime.strptime(raw_date, '%Y-%M-%d')
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
    db = get_db()
    c = db.execute('SELECT flightIDs.flightCode AS flightCode, date, '
                   'dataReady, invalid, path, origin, destination, '
                   'originCode, destinationCode, progress '
                   'FROM flightIDs INNER JOIN flightPaths '
                   'ON flightIDs.flightCode = flightPaths.flightCode '
                   'WHERE id=?',
                   [ref_id])
    flight = c.fetchone()
    if flight is None:
        return '', 403
    if flight['invalid']:
        return '', 404
    if not flight['dataReady']:
        return send_json({'progress': flight['progress']}, 503)
    csv_path = map(lambda row: row.split(','), flight["path"].split('\n'))
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
            }
    tiles = db.execute('SELECT file, alat, along, blat, blong)'
                       'FROM tiles WHERE flightID=?',
                       [ref_id]).fetchall()
    return send_json({
        'meta': {
            'flightCode': flight['flightCode'],
            'date': flight['date'],
            'origin': flight['origin'],
            'originCode': flight['originCode'],
            'destination': flight['destination'],
            'destinationCode': flight['destinationCode'],
        },
        'path': flight["path"],
        "landmarks": [
            {
                'name': 'Clifton Suspension Bridge',
                'lat': 51.4549,
                'long': -2.6278,
                'model_name': 'CliftonSuspensionBridge'
            },
            {
                'name': 'Eiffel Tower',
                'lat': 48.8584,
                'long': 2.2945,
                'model_name': 'EiffelTower'
            },
            {
                'name': 'Colosseum',
                'lat': 41.8902,
                'long': 12.4922,
                'model_name': 'Colosseum'
            },
            {
                'name': 'Arc De Triomphe',
                'lat': 48.8738,
                'long': 2.2950,
                'model_name': 'ArcDeTriomphe'
            },
            {
                'name': 'Leaning Tower of Pisa',
                'lat': 43.7230,
                'long': 10.3966,
                'model_name': 'Pisa'
            },
            {
                'name': "St Peter's Basilica",
                'lat': 41.9022,
                'long': 12.4539,
                'model_name': 'Basilica'
            }
        ],
        "cities": list(cities.values()),
        "tiles": [
            {
                'alat': tile['alat'],
                'along': tile['along'],
                'blat': tile['blat'],
                'blong': tile['blong'],
                'image': '/api/v1/tile/{}/{}.jpg'
                    .format(ref_id, tile['file']),
            } for tile in tiles
        ]
    })


@app.route('/api/v1/tile/<ref_id>/<filename>')
def image(ref_id, filename):
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
    return 'reload %s' % ref_id


@app.route('/api/v1/refetch/<ref_id>')
def refetch(ref_id):
    return


def send_json(data, code=200):
    return Response(response=json.dumps(data),
                    status=code,
                    mimetype="application/json")


def send_string(string, code=200):
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
    db = get_db()
    with app.open_resource('schema.sql', mode='r') as f:
        db.cursor().executescript(f.read())
    for f in os.listdir('imgs/'):
        if f != 'img.jpg':
            os.remove(f)
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
    with connect_db() as db:
        path = flight_data.load_flight(db, flight_id)
        points = tile_geometry.generate_points(path)
        grouped_points = tile_geometry.group_points(points)
        for i, group in enumerate(grouped_points):
            progress = 0.2 + 0.8 * i / len(group)
            db.execute(
                'UPDATE flightIDs SET progress=? WHERE flightCode=?',
                [progress, flight_id])
            bounds = tile_geometry.mercator_bounds(group)
            image = tile_geometry.fetch_group_image(group)
            save_image(db, flight_id, image, *bounds)
        db.execute('UPDATE flightIDs SET dataReady=1 WHERE id=?', [flight_id])
        db.commit()
        db.close()
    return flight_id


def save_image(db, flight_id, image, alat, along, blat, blong):
    while True:
        file = str(secrets.token_urlsafe(24))
        app.logger.info(str(id))
        c = db.execute('SELECT COUNT(*) FROM tiles WHERE file=?', [file])
        if c.fetchone()[0] is 0:
            break
    db.execute('INSERT INTO tiles (file, id, alat, along, blat, blong)'
               'VALUES (?,?,?,?,?,?)',
               [file, flight_id, alat, along, blat, blong])
    image.save('imgs/{}.jpg'.format(file))
