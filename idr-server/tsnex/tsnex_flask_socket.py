# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets
# TODO: Think about to use Flask-SocketIO (must change client too)

from flask import Flask
from flask_sockets import Sockets
import json
import time
import numpy as np

from utils import ConsumerQueue, get_dataset_from_db, set_dataset_to_db
import utils
from tsnex import do_embedding, load_dataset
import tsnex

app = Flask(__name__)
sockets = Sockets(app)

conQueue = ConsumerQueue("ConsumerQueue in Websocket")


@sockets.route('/tsnex/load_dataset')
def do_load_dataset(ws):
    while not ws.closed:
        datasetName = ws.receive()
        if datasetName is not None:
            if datasetName.upper() in ['MNIST']:
                X, y = tsnex.load_dataset()
                result = {
                    'shape_X': X.shape,
                    'shape_y': y.shape
                }

                utils.set_dataset_to_db(X, y)
                ws.send(json.dumps(result))
            else:
                ws.send("Dataset {} is not supported".format(datasetName))


@sockets.route('/tsnex/get_data_xxx')
def get_data(ws):

    while not ws.closed:
        message = ws.receive()
        print("Receive msg: ", message)
        if message is not None:  # client subscription
            if message.startswith("ACK"):
                if message == "ACK=False":
                    conQueue.pauseServer()
            else:
                get_data_iterative(ws)


def get_data_iterative(ws):
    n_sent = 0

    def auto_send():
        X = conQueue.pop()
        if X is not None:
            raw_data = [
                {
                    'id': str(i),
                    'x': float(X[i][0]),
                    'y': float(X[i][1]),
                    'label': str(y[i])
                } for i in range(len(y))
            ]
            nonlocal n_sent
            if not ws.closed and n_sent < 10:
                ws.send(json.dumps(raw_data))
                n_sent += 1
            else:
                pass

    conQueue.registerCallback(auto_send)

    X, y = load_dataset()

    X_projected = do_embedding(X, n_iter=400, continuous=False)
    set_dataset_to_db(X_projected, y)
    print("Update new embedding Ok")


@sockets.route('/tsnex/continue_server')
def continue_server(ws):
    while not ws.closed:
        message = ws.receive()
        if message is not None and message == "ACK=True":
            utils.set_ready_status(ready=True)
            

@sockets.route('/tsnex/moved_points')
def client_moved_points(ws):
    while not ws.closed:
        message = ws.receive()
        if (message is not None):
            moved_points = json.loads(message)
            n_moved = len(moved_points)

            X, y = get_dataset_from_db()
            n_points = X.shape[0]
            print("Get previous embedding from Redis: X.shape={}, y.shape={}".format(
                X.shape, y.shape))

            new_X = []
            new_y = []
            moved_ids = []

            for i in range(n_moved):
                point = moved_points[i]
                point_id = int(point['id'])
                point_x = float(point['x'])
                point_y = float(point['y'])

                moved_ids.append(point_id)
                new_X.append([point_x, point_y])
                new_y.append(y[point_id])

            for i in range(n_points):
                if i not in moved_ids:
                    new_X.append(X[i, :])
                    new_y.append(y[i])

            new_X = np.array(new_X)
            new_y = np.array(new_y)

            X_projected = do_embedding(new_X, n_iter=400, continuous=True)
            set_dataset_to_db(X_projected, new_y)
            print("Update new embedding from moved points OK")


@app.route('/')
def hello():
    return "Root of socket server. Default URI for client: ws://localhost:5000"


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
