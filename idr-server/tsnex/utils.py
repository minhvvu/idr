# utils.py
# ConsumerQueue a Singleton class that holds the intermediate data
# produced by TSNE in each iteration

import queue
import json
import numpy as np

import redis
redis_db = redis.StrictRedis(host='localhost', port=6379, db=0)

KEY_PREFIX = 'tsnex_demo01_'

server_status = {
    'current_it': 0,
    'ready': True
}


def set_to_db(key, str_value):
    redis_db.set(KEY_PREFIX + key, str_value)


def get_from_db(key):
    return redis_db.get(KEY_PREFIX + key)


def set_dataset_to_db(X, y):
    meta_data = {
        'shape_X': X.shape,
        'type_X': X.dtype.name,
        'shape_y': y.shape,
        'type_y': y.dtype.name
    }

    meta_str = json.dumps(meta_data)
    X_str = X.ravel().tostring()
    y_str = y.ravel().tostring()

    set_to_db(key='meta', str_value=meta_str)
    set_to_db(key='X', str_value=X_str)
    set_to_db(key='y', str_value=y_str)


def get_dataset_from_db():
    meta_str = get_from_db(key='meta')
    X_str = get_from_db(key='X')
    y_str = get_from_db(key='y')

    meta_obj = json.loads(meta_str)
    type_X = np.dtype(meta_obj['type_X'])
    type_y = np.dtype(meta_obj['type_y'])

    X = np.fromstring(X_str, dtype=type_X).reshape(meta_obj['shape_X'])
    y = np.fromstring(y_str, dtype=type_y).reshape(meta_obj['shape_y'])

    return X, y


def set_server_status(statusObj):
    set_to_db(key='status', str_value=json.dump(statusObj))

def get_server_status():
    status = get_from_db(key='status')
    return json.loads(status)


class ConsumerQueue(object):
    """ A queue that stores all intermediate result of TSNE
        Each element in queue is waiting to be sent to client
        Singleton implementation from:
        http://python-3-patterns-idioms-test.readthedocs.io/en/latest/Singleton.html
    """

    __instance = None

    callback = None
    dataQueue = queue.Queue()
    dataCount = 0

    ready = True

    def __new__(cls, val):
        if ConsumerQueue.__instance is None:
            ConsumerQueue.__instance = object.__new__(cls)

        ConsumerQueue.__instance.val = val
        return ConsumerQueue.__instance

    def registerCallback(self, callback):
        print("Register callback: ", callback)
        self.callback = callback

    def push(self, item):
        self.dataQueue.put(item)
        self.dataCount += 1
        if self.callback is not None:
            self.callback()
        else:
            print("[Error] Callback is not available")

    def pop(self):
        value = self.dataQueue.get() if not self.dataQueue.empty() else None
        return value

    def pauseServer(self):
        self.ready = False

    def continueServer(self):
        self.ready = True

    def isReady(self):
        return self.ready
