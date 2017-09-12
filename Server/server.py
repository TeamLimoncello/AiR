from flask import Flask, Response
import json
app = Flask(__name__)


@app.route('/')
def foo():
    obj = {
        'version': '0.1',
    }
    return send_json(obj)


def send_json(data):
    return Response(response=json.dumps(data),
                    status=200,
                    mimetype="application/json")