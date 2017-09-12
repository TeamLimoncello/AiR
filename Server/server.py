import datetime
import re
from flask import Flask, Response, request, logging
import json
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
        date = datetime.datetime.strptime(raw_date,'%Y-%M-%d')
    except (KeyError, ValueError):
        return send_json({'code': 1, 'string': 'Bad Date'}, 400)
    try:
        raw_flight = request.form['flightNumber']
        flight_num = re.match(r'([0-9A-Z]{2})([A-Z]?)([0-9]{1,4})([A-Za-z]?)',raw_flight)
        if flight_num is None:
            raise ValueError('Invalid flight number')
    except (KeyError, ValueError):
        return send_json({'code': 2, 'string': 'Bad flight number'}, 400)
    return send_json({'flight': flight_num.groups(), 'date': str(date)})


@app.route('/api/v1/fetch/<ref_id>')
def fetch(ref_id):
    return 'fetch %s' % ref_id


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