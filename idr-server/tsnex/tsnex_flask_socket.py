# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets
# TODO: Think about to use Flask-SocketIO (must change client too)

from flask import Flask
from flask_sockets import Sockets
import json
import time

from utils import ConsumerQueue, get_dataset_from_db, set_dataset_to_db
from tsnex import test_embedding, load_dataset


app = Flask(__name__)
sockets = Sockets(app)

conQueue = ConsumerQueue("ConsumerQueue in Websocket")


@sockets.route('/tsnex/get_data')
def get_data(ws):

    while not ws.closed:
        message = ws.receive()
        print("Receive msg: ", message)
        if message is not None:  # client subscription
            get_data_iterative(ws)


def get_data_iterative(ws):
    def auto_send():
        X = conQueue.pop()
        if X is not None:
            # if conQueue.dataCount % 5 == 0:
            raw_data = [
                {
                    'id': str(i),
                    'x': float(X[i][0]),
                    'y': float(X[i][1]),
                    'label': str(y[i])
                } for i in range(len(y))
            ]
            if not ws.closed:
                ws.send(json.dumps(raw_data))
            else:
                print("SOCKET DIE")

    conQueue.registerCallback(auto_send)

    X, y = load_dataset()
    print("Load dataset OK: X.shape={}, y.shape={}".format(X.shape, y.shape))

    X_projected = test_embedding(X)
    set_dataset_to_db(X_projected, y)
    print("Update new embedding Ok")
    

@sockets.route('/tsnex/pause_server')
def pause_server(ws):
    while not ws.closed:
        message = ws.receive()
        if message is not None:
            print("Pause server command: ", message)
            conQueue.togglePause()
            # TODO: can not pause server
            # because this code is in separated request with `get_data`


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
