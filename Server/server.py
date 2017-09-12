from flask import Flask, Response, request
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
    return send_json(request.form)


@app.route('/api/v1/fetch/<ref_id>')
def fetch(ref_id):
    return 'fetch %s' % ref_id


@app.route('/api/v1/inc/<ref_id>')
def inc(ref_id):
    return 'inc %s' % ref_id


def send_json(data):
    return Response(response=json.dumps(data),
                    status=200,
                    mimetype="application/json")