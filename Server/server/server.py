import datetime
import re
import secrets

from flask import Flask, Response, request, g
import json
import os
import sqlite3

app = Flask(__name__)
app.config['APPLICATION_ROOT'] = '/api/v1'


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
        datetime.datetime.strptime(raw_date, '%Y-%M-%d')
    except (KeyError, ValueError):
        return send_json({'code': 1, 'string': 'Bad Date'}, 400)
    try:
        raw_flight = request.form['flightNumber']
        flight_num = re.match(r'([0-9A-Z]{2})([A-Z]?)([0-9]{1,4})([A-Za-z]?)', raw_flight)
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
    db.execute('INSERT INTO flightIDs (id, flightCode, date) VALUES (?,?,?)', (id, raw_flight, raw_date))
    db.commit()
    return send_json({'id': id})


@app.route('/api/v1/fetch/<ref_id>')
def fetch(ref_id):
    db = get_db()
    c = db.execute('SELECT flightCode, date FROM flightIDs WHERE id=?', (ref_id,))
    flight = c.fetchone()
    if flight is None:
        return '', 403
    return send_json({'id': ref_id, 'flightCode': flight["flightCode"], 'date': flight["date"]})


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
