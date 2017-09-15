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
import time

from server import flight_aware_interface

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
        'version': '0.1',
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
        c = db.execute('SELECT COUNT(*) FROM flightIDs WHERE id=?', (id,))
        if c.fetchone()[0] is 0:
            break
    db.execute('INSERT INTO flightIDs (id, flightCode, date) VALUES (?,?,?)',
               (id, raw_flight, raw_date))
    db.commit()
    load_data.delay(id)
    return send_string(id)


@app.route('/api/v1/fetch/<ref_id>')
def fetch(ref_id):
    db = get_db()
    c = db.execute('SELECT flightIDs.flightCode AS flightCode, date, '
                   'dataReady, invalid, path, origin, destination, '
                   'originCode, destinationCode '
                   'FROM flightIDs INNER JOIN flightPaths '
                   'ON flightIDs.flightCode = flightPaths.flightCode '
                   'WHERE id=?',
                   (ref_id,))
    flight = c.fetchone()
    if flight is None:
        return '', 403
    if flight['invalid']:
        return '', 404
    if not flight['dataReady']:
        return send_json({'progress': 0}, 503)
    csv_path = map(lambda row: row.split(','), flight["path"].split('\n'))
    cities = {}
    for i, row in enumerate(csv_path):
        try:
            csv_lat = row[1]
            csv_long = row[2]
        except IndexError:
            print('Error at {}'.format(i))
        d = db.execute('SELECT id, name, lat, long, population, name_en '
                       'FROM cities WHERE (lat - ?) BETWEEN (-1) AND 1 AND  (long - ?) BETWEEN (-1) AND 1',
                       (csv_lat, csv_long))
        for city in d.fetchall():
            cities[city['id']] = {
                'name': city['name'],
                'lat': city['lat'],
                'long': city['long'],
                'population': city['population'],
                'name_en': city['name_en']
            }
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
        "cities": list(cities.values()),
        "tiles": [
            {
                'alat': 0,
                'along': 0,
                'blat': 1,
                'blong': 1,
                'image': '/api/v1/tile/' + ref_id + '/img.jpg',
            },
        ]
    })


@app.route('/api/v1/tile/<ref_id>/<filename>')
def image(ref_id, filename):
    db = get_db()
    c = db.execute('SELECT flightCode, date FROM flightIDs WHERE id=?',
                   (ref_id,))
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
    with open('parsed_cities.json') as raw:
        json_data = json.loads(raw.read())
        for city in json_data:
            if city['population'] is None:
                continue
            db.execute('INSERT OR REPLACE INTO cities '
                       '(name, population, lat, long, name_en) '
                       'VALUES (?, ?, ?, ?, ? )',
                       (city['name'],
                        city['population'],
                        city['lat'],
                        city['long'],
                        city['name_en'],))
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
    result = flight_aware_interface.cache(flight_id)
    with get_db() as db:
        db.execute('UPDATE flightIDs SET dataReady=1 WHERE id=?', (flight_id,))
        db.commit()
    return flight_id
