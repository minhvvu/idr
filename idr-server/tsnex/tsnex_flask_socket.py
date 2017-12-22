# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets

from flask import Flask
from flask_sockets import Sockets
import json
import numpy as np

app = Flask(__name__)
sockets = Sockets(app)

all_data = []


@sockets.route('/tsnex/get_data')
def echo_socket(ws):
    while not ws.closed:
        message = ws.receive()
        print("Receive msg: ", message)

        n = np.random.randint(2, 10)
        x = np.random.randn(n)
        y = np.random.randn(n)
        raw_data = [{'id': i, 'x': x[i], 'y': y[i]} for i in range(n)]
        all_data.append(raw_data)

        ws.send(json.dumps(raw_data))

    print("Connection CLOSED")


@app.route('/')
def hello():
    return "All data in server:\n" + ', '.join(map(str, all_data))


def runserver(port=5000):
    from gevent.wsgi import WSGIServer
    from geventwebsocket.handler import WebSocketHandler

    from werkzeug.serving import run_with_reloader

    @run_with_reloader
    def run_server():
        print('Starting server at: 127.0.0.1:%s' % port)

        app.debug = True
        server = WSGIServer(('', port), app, handler_class=WebSocketHandler)
        server.serve_forever()

    run_server()


if __name__ == "__main__":
    runserver(port=5000)
