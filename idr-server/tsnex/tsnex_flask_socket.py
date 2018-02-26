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
import datasets

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
        datasetName = 'COIL20'
        if datasetName:
            X, y, labels = datasets.load_dataset(datasetName)
            metadata = {
                'n_total': X.shape[0],
                'original_dim': X.shape[1],
                'reduced_dim': 2,
                'shape_X': X.shape,
                'type_X': X.dtype.name,
                'shape_y': y.shape,
                'type_y': y.dtype.name
            }
            utils.clean_data() # In dev mode: flush all data in redis
            utils.set_dataset_metadata(metadata)
            utils.set_ndarray(name='X_original', arr=X)
            utils.set_ndarray(name='y_original', arr=y)
            utils.set_to_db(key='labels', str_value=json.dumps(labels))
            ws.send(json.dumps(metadata))


@sockets.route('/tsnex/do_embedding')
def do_embedding(ws):
    """ Socket endpoint to hold all dataframes of the intermediate results
    """
    while not ws.closed:
        message = ws.receive()
        if message:
            client_iteration = int(message)
            if client_iteration == 0:
                do_boostrap(ws)
                

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

    # start a thread to do embedding
    # note to inject a queue containing the interaction_data
    t1 = threading.Thread(
        name='tsnex_gradient_descent',
        target=tsnex.boostrap_do_embedding,
        args=(X, shared_states['interaction_data'], ))
    t1.start()
    shared_states['thread_tsnex'] = t1

    # start a thread to listen to the intermediate result
    t2 = threading.Thread(
        name='pubsub_from_redis',
        target=run_send_to_client,
        args=(ws,))  # specific that `args` is a tuple
    t2.start()
    shared_states['thread_pubsub'] = t2


def run_send_to_client(ws):
    """ Main loop of the thread that read the subscribed data
        and turn it into a json object and send back to client.
        The returned message is a dataframe in `/tsnex/do_embedding` route
    """
    print("[PUBSUB] Thread to read subscribed data is starting ... ")
    while True:
        fixed_data = utils.get_from_db(key='fixed_points')
        fixed_ids = []
        if fixed_data:
            fixed_points = json.loads(fixed_data)
            fixed_ids = [int(id) for id in fixed_points.keys()]

        subscribedData = utils.get_subscribed_data()
        if subscribedData is not None:
            if not ws.closed:
                # pause server and wait until client receives new data
                # if user does not pause client, a `continous` command
                # will be sent automatically to continue server
                utils.pause_server()

                # prepare the `embedding` in subscribedData
                # do not need to touch the other fields
                X_embedded = subscribedData['embedding']
                gradients = subscribedData['gradients']
                idx = np.argsort(gradients)[::-1]
                y = utils.get_y()
                labels = json.loads(utils.get_from_db(key='labels'))
                raw_points = [{
                    'id': str(i),
                    'x': float(X_embedded[i][0]),
                    'y': float(X_embedded[i][1]),
                    'z': float(gradients[i]),
                    'label': labels[i],
                    'fixed': i in fixed_ids
                } for i in idx]
                subscribedData['embedding'] = raw_points
                ws.send(json.dumps(subscribedData))

        status = utils.get_server_status(['tick_frequence', 'stop'])
        if status['stop'] is True:
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
        If there exsits the old moved points from the previous interaction,
        we should merge them together.
    """
    while not ws.closed:
        message = ws.receive()
        if message:
            new_moved_points = json.loads(message)
            fixed_data = utils.get_from_db(key='fixed_points')
            fixed_points = json.loads(fixed_data) if fixed_data else {}

            for p in new_moved_points:
                pid = p['id']  # for fixed_points dict, key is string
                pos = [float(p['x']), float(p['y'])]
                fixed_points[pid] = pos

            shared_states['interaction_data'].put({
                'fixed_ids': [int(k) for k in fixed_points.keys()],
                'fixed_pos': list(fixed_points.values())
            })

            utils.set_to_db('fixed_points', json.dumps(fixed_points))
            utils.continue_server()


@sockets.route('/tsnex/reset')
def reset_data(ws):
    """ Socket endpoint to reset the data on server.
    """
    while not ws.closed:
        message = ws.receive()
        if message and message == "ConfirmReset":
            do_reset()


def do_reset():
    print("[Reset]Receive Reset command from client. Do reset!")

    # set a flag to denote it's time to break all running thread
    utils.update_server_status({'stop': True})

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
