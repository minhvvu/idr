# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets

import threading

from flask import Flask
from flask_sockets import Sockets
import json
import time
import numpy as np

import tsnex
import utils


app = Flask(__name__)
sockets = Sockets(app)


@sockets.route('/tsnex/load_dataset')
def do_load_dataset(ws):
    while not ws.closed:
        datasetName = ws.receive()
        if datasetName:
            if datasetName.upper() in ['MNIST']:
                X, y = tsnex.load_dataset()

                metadata = {
                    'n_total': X.shape[0],
                    'original_dim': X.shape[1],
                    'reduced_dim': 2,
                    'shape_X': X.shape,
                    'type_X': X.dtype.name,
                    'shape_y': y.shape,
                    'type_y': y.dtype.name
                }

                utils.set_dataset_metadata(metadata)
                utils.set_ndarray(name='X_original', arr=X)
                utils.set_ndarray(name='y_original', arr=y)

                ws.send(json.dumps(metadata))
            else:
                ws.send("Dataset {} is not supported".format(datasetName))


@sockets.route('/tsnex/do_embedding')
def do_embedding(ws):
    """ Endpoint to hold all dataframes of the intermediate results
    """
    while not ws.closed:
        message = ws.receive()
        if message:
            client_iteration = int(message)
            if client_iteration == 0:
                do_boostrap(ws) # TODO add more client params: max_iter, ...
            else:
                pass
        else:
            pass # subscription message in client websocket connection


def do_boostrap(ws):
    """ Util function to do boostrap for setting up the two threads:
        + A thread do embedding and publish the intermediate result to redis
        + A second thread subscribes a channel on redis
            to read the intermediate result and send it to client
    """
    # if client does not specify the hyper-params, use the default one
    print("[BOOSTRAP] Setup Thread for TSNEX and PUB/SUB")

    utils.set_server_status()

    X = utils.get_X()
    print("Input data: ", X.shape)
    max_iter = utils.initial_server_status['max_iter']

    # start a thread to do embedding
    t1 = threading.Thread(
        name='tsnex_gradient_descent',
        target=tsnex.boostrap_do_embedding,
        args=(X, max_iter, )) # specific that `args` is a tuple
    t1.start()

    # start a thread to listen to the intermediate result
    t2 = threading.Thread(
        name='pubsub_from_redis',
        target=run_send_to_client,
        args=(ws,))
    t2.start()


def run_send_to_client(ws):
    """ Main loop of the thread that read the subscribed data
        and turn it into a json object and send back to client.
        The returned message is a dataframe in `/tsnex/do_embedding` route
    """
    print("[PUBSUB] Thread to read subscribed data is starting ... ")
    while True:
        X_embedded = utils.get_subscribed_data()
        if X_embedded is not None:
            y = utils.get_y()
            raw_points = [{
                'id': str(i),
                'x': float(X_embedded[i][0]),
                'y': float(X_embedded[i][1]),
                'label': str(y[i])
            } for i in range(y.shape[0])]
        
            if not ws.closed:
                utils.pause_server()
                ws.send(json.dumps(raw_points))

        status = utils.get_server_status(['tick_frequence'])
        time.sleep(status['tick_frequence'])



@sockets.route('/tsnex/continue_server')
def continue_server(ws):
    while not ws.closed:
        message = ws.receive()
        if message:
            # status = utils.get_server_status(fields=['client_iter'])
            # print("Current_it: client = {}, server = {}" \
            #     .format(message, status['client_iter']))
            utils.continue_server()
            

@sockets.route('/tsnex/moved_points')
def client_moved_points(ws):
    while not ws.closed:
        message = ws.receive()
        if message:
            moved_points = json.loads(message)
            n_moved = len(moved_points)

            X_embedded = utils.get_X_embedded()
            n_points = X_embedded.shape[0]

        #     new_X = []
        #     new_y = []
        #     moved_ids = []

        #     for i in range(n_moved):
        #         point = moved_points[i]
        #         point_id = int(point['id'])
        #         point_x = float(point['x'])
        #         point_y = float(point['y'])

        #         moved_ids.append(point_id)
        #         new_X.append([point_x, point_y])
        #         new_y.append(y[point_id])

        #     for i in range(n_points):
        #         if i not in moved_ids:
        #             new_X.append(X[i, :])
        #             new_y.append(y[i])

        #     new_X = np.array(new_X)
        #     new_y = np.array(new_y)

        #     X_projected = do_embedding(new_X, n_iter=400, continuous=True)
        #     set_dataset_to_db(X_projected, new_y)
        #     print("Update new embedding from moved points OK")


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
