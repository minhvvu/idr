# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets

import threading

from flask import Flask
from flask_sockets import Sockets
import json
import time
import queue
import numpy as np

import tsnex
import utils

# flask-socket application
app = Flask(__name__)
sockets = Sockets(app)

# Shared states between threads
shared_states = {
    # interactive data from client will be put in a queue
    # this queue will be shared will a thread running tsne code
    # so that tsne can take into account of client interation.
    'interaction_data': queue.Queue(),

    # thread to run tsne
    'thread_tsnex': None,

    # thread to send intermediate data to client
    'thread_pubsub': None
}



@sockets.route('/tsnex/load_dataset')
def do_load_dataset(ws):
    """ Socket endpoint to receive command to load a dataset
    """
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
    """ Socket endpoint to hold all dataframes of the intermediate results
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
    # note to inject a queue containing the interaction_data
    t1 = threading.Thread(
        name='tsnex_gradient_descent',
        target=tsnex.boostrap_do_embedding,
        args=(X, max_iter, shared_states['interaction_data'], ))
    t1.start()
    shared_states['thread_tsnex'] = t1

    # start a thread to listen to the intermediate result
    t2 = threading.Thread(
        name='pubsub_from_redis',
        target=run_send_to_client,
        args=(ws,)) # specific that `args` is a tuple
    t2.start()
    shared_states['thread_pubsub'] = t2


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

        status = utils.get_server_status(['tick_frequence', 'should_break'])
        if (status['should_break']):
            break
        else:
            time.sleep(status['tick_frequence'])


@sockets.route('/tsnex/continue_server')
def continue_server(ws):
    """ Socket endpoint to receive command to continue server after being paused.
    """
    while not ws.closed:
        message = ws.receive()
        if message:
            # status = utils.get_server_status(fields=['client_iter'])
            # print("Synchronizing current_it: client = {}, server = {}" \
            #     .format(message, status['client_iter']))
            utils.continue_server()
            

@sockets.route('/tsnex/moved_points')
def client_moved_points(ws):
    """ Socket endpoint to receive the moved points from client interaction.
    """
    while not ws.closed:
        message = ws.receive()
        if message:
            moved_points = json.loads(message)
            moved_ids = [int(p['id']) for p in moved_points]
            moved_coordinates = [
                [float(p['x']), float(p['y'])] for p in moved_points
            ]

            X_embedded = utils.get_X_embedded()
            n_points = X_embedded.shape[0]
            n_moved = len(moved_points)

            # pull the indexes of moved points to top of the list of all points
            new_indexes = moved_ids + \
                [i for i in range(n_points) if i not in moved_ids]

            # # store the newly ordered label
            # y = utils.get_y()
            # new_y = y[new_indexes]
            # utils.set_ndarray(name='y_original', arr=new_y)

            # update new coordonates
            new_X_embedded = X_embedded # [new_indexes]
            #new_X_embedded[0:n_moved] = moved_coordinates
            new_X_embedded[moved_ids] = moved_coordinates

            # share new embedded data with TSNEX
            shared_states['interaction_data'].put({
                'n_moved': n_moved,
                'new_embedding': new_X_embedded
            })

            # let TSNEX continue to run
            utils.continue_server()


@sockets.route('/tsnex/reset')
def reset_data(ws):
    """ Socket endpoint to reset the data on server.
    """
    while not ws.closed:
        message = ws.receive()
        if message and message == "ConfirmReset":
            print("[Reset]Receive Reset command from client. Do reset!")

            # set a flag to denote it's time to break all running thread
            utils.update_server_status({'should_break': True})

            # let the tsnex thread to jump out of waiting status
            utils.continue_server()
            
            # stop all threads
            print("[Reset]Stopping the running threads ... ")
            if (shared_states['thread_tsnex']):
                shared_states['thread_tsnex'].join(timeout=1)
            if (shared_states['thread_pubsub']):
                shared_states['thread_pubsub'].join(timeout=1)
            time.sleep(2.5)
            print("[Reset]Threads stopped")
            
            # clean interaction data in queue
            print("[Reset]Cleaning data ... ")
            while not shared_states['interaction_data'].empty():
                shared_states['interaction_data'].get()

            # flush all data in redis
            utils.clean_data()

            print("[Reset]Done!")


@app.route('/')
def hello():
    """ Show index page if access socket server from browser
    """
    return "Root of socket server. Default URI for client: ws://localhost:5000"


def runserver(port=5000):
    """ Starting point to run development socket server
        with auto reset when code changed.
    """
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
