# utils.py
# ConsumerQueue a Singleton class that holds the intermediate data
# produced by TSNE in each iteration

import queue
import json
import numpy as np
import redis


# redis database to store the dataset and the intermediate results
redis_db = redis.StrictRedis(host='localhost', port=6379, db=0)

# prefix key to store data in redis
KEY_PREFIX = 'tsnex_demo01_'

# channel name for store intermediate data in redis
DATA_CHANNEL = 'tsnex_X_embedding'

# publish/subscribe object in redis
pubsub = redis_db.pubsub()
pubsub.subscribe(DATA_CHANNEL)


# status object to store some server infos
server_status = {
    'tick_frequence': 0.5,
    'n_jump': 5,
    'current_it': 0,
    'ready': True
}

# dataset meta data
dataset_meta_data = {
    'n_total': 0,
    'original_dim': 0,
    'reduced_dim': 0,
    'shape_X': [0, 0],
    'type_X': None,
    'shape_y': [0],
    'type_y': None
}


def publish_data(X):
    """ Push intermediate result into a redis channel
    """
    data_str = X.ravel().tostring()
    # note that float data type is written as float32
    redis_db.publish(DATA_CHANNEL, data_str)


def get_subscribed_data():
    """ Get subscribled from published channel in redis
    """
    msg = pubsub.get_message()
    if msg is None or msg['type'] != 'message':
        return None

    data_str = msg['data']
    n_total = dataset_meta_data['n_total']
    reduced_dim = dataset_meta_data['reduced_dim']
    data_obj = np.fromstring(data_str, dtype=np.float32)
    data_arr = data_obj.reshape([n_total, reduced_dim])
    return data_arr


def set_to_db(key, str_value):
    """ Set binary string value into redis by key
    """
    redis_db.set(KEY_PREFIX + key, str_value)


def get_from_db(key):
    """ Get binary string value from redis by key
    """
    return redis_db.get(KEY_PREFIX + key)


def set_ndarray(name, arr):
    """ Set numpy ndarray to key name in redis
    """
    set_to_db(key=name, str_value=arr.ravel().tostring())


def get_ndarray(name, arr_shape, arr_type):
    """ Get numpy ndarray from redis by key and reshape
    """
    arr_str = get_from_db(key=name)
    return np.fromstring(arr_str, dtype=np.dtype(arr_type)) \
        .reshape(arr_shape)


def get_X():
    """ Util function to get original X
    """
    return get_ndarray(name='X_original',
        arr_shape=dataset_meta_data['shape_X'],
        arr_type=dataset_meta_data['type_X'])


def get_y():
    """ Util function to get original y
    """
    return get_ndarray(name='y_original',
        arr_shape=dataset_meta_data['shape_y'],
        arr_type=dataset_meta_data['type_y'])


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


def set_server_status(statusObj=None):
    if statusObj is None:
        statusObj = server_status
    set_to_db(key='status', str_value=json.dumps(statusObj))


def get_server_status():
    status = get_from_db(key='status')
    return json.loads(status)


def set_ready_status(ready):
    statusObj = get_server_status()
    statusObj['ready'] = ready
    set_server_status(statusObj)


def get_ready_status():
    statusObj = get_server_status()
    return statusObj['ready']


def increase_iteration():
    statusObj = get_server_status()
    statusObj['current_it'] += 1
    set_server_status(statusObj)


def get_current_iteration():
    statusObj = get_server_status()
    return statusObj['current_it']


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
