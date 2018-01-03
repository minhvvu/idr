# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets

from flask import Flask
from flask_sockets import Sockets
import json
import time

from tsnex import test_embedding

app = Flask(__name__)
sockets = Sockets(app)

all_data = []


@sockets.route('/tsnex/get_data')
def get_data(ws):
    while not ws.closed:
        message = ws.receive()
        print("Receive msg: ", message)

        # n = np.random.randint(10, 20)
        # x = np.random.randn(n)
        # y = np.random.randn(n)
        # raw_data = [{'id': str(i), 'x': x[i], 'y': y[i]} for i in range(n)]

        X_iter, y = test_embedding()
        n_iter = X_iter.shape[-1]
        for i in range(n_iter):
            X = X_iter[..., i]
            raw_data = [
                {
                    'id': str(i),
                    'x': float(X[i][0]),
                    'y': float(X[i][1]),
                    'label': str(y[i])
                } for i in range(len(y))
            ]
            if (i % 5 == 0):
                ws.send(json.dumps(raw_data))
                print("Iteration: ", i)
                time.sleep(0.2)

    print("Connection CLOSED")


@sockets.route('/tsnex/moved_points')
def client_moved_points(ws):
    while not ws.closed:
        message = ws.receive()
        print("Client moved points: ", message)
        if (message is not None):
            moved_points = json.loads(message)
            print("Parsed json: ", moved_points)


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
