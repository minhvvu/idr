import sys
import queue
import json
import numpy as np
import redis
from sklearn import datasets
from sklearn.utils import shuffle

# status object to store some server infos
initial_server_status = {
    # time in second to sleep while waiting the data being sent to client
    'tick_frequence': 0.005,

    # number of iterations that we skip sending data to client
    'n_jump': 10,

    # the current iteration in client, server_iter = client_iter * n_jump
    'client_iter': 0,

    # max number of server iterations, not used
    'max_iter': 1000,

    # number of nearest neighbors for each selected point
    'n_neighbors': 10,

    # accumulate the info of early_exaggeration state
    'accumulate': False,

    # calculate the measurement after each iteration
    'measure': True,

    # hard-fix position of client selected points
    'hard_move': True,

    # use pagerank to find the most influential points
    'use_pagerank': True,

    # share grandient of moved points to its neighbors
    'share_grad': False,

    # client does not stop server
    'ready': True,

    # need to stop all running threads to clean data
    'stop': False
}


def load_dataset(name='MNIST-SMALL'):
    """ Some available dataset: MNIST_small, COIL-20
    """
    name = 'MNIST'
    if name == 'COIL20':
        return load_coil20()
    elif name.startswith('MNIST'):
        return load_mnist_mini() if name.endswith('SMALL') else load_mnist_full()


def load_coil20():
    import scipy.io
    mat = scipy.io.loadmat("../data/COIL20.mat")
    X = mat['X']
    y = mat['Y'][:, 0]
    print("COIL-20: X.shape={}, len(y)={}".format(X.shape, len(y)))
    return X, y


def load_mnist_mini():
    dataset = datasets.load_digits()
    X, y = shuffle(dataset.data, dataset.target, random_state=0)
    print("MNIST mini: X.shape={}, len(y)={}".format(X.shape, len(y)))
    return X, y


def load_mnist_full(n_samples=6000):
    from sklearn.datasets import fetch_mldata
    dataset = fetch_mldata('MNIST original', data_home='../data/')
    X, y = shuffle(dataset.data, dataset.target, n_samples=n_samples, random_state=0)
    print("MNIST full with n_samples = {}: X.shape={}, len(y)={}"
          .format(n_samples, X.shape, len(y)))
    print("Label count: ", np.unique(y, return_counts=True))
    return X, y


# redis database to store the dataset and the intermediate results
redis_db = redis.StrictRedis(host='localhost', port=6379, db=0)

# prefix key to store data in redis
KEY_PREFIX = 'tsnex_demo01_'


def set_to_db(key, str_value):
    """ Set binary string value into redis by key
    """
    redis_db.set(KEY_PREFIX + key, str_value)


def get_from_db(key):
    """ Get binary string value from redis by key
    """
    return redis_db.get(KEY_PREFIX + key)


def clean_data():
    """ Util function to flush all keys of the current db
    """
    redis_db.flushdb()


# channel name for store intermediate data in redis
DATA_CHANNEL = 'tsnex_X_embedding'

# publish/subscribe object in redis
pubsub = redis_db.pubsub()
pubsub.subscribe(DATA_CHANNEL)


def set_server_status():
    """ Set status object to redis.
    """
    set_to_db(key='status', str_value=json.dumps(initial_server_status))


def update_server_status(userStatusObj):
    """ Update the existed server status object in redis.
        It merges the user-defined status object and the old one.
        http://treyhunner.com/2016/02/how-to-merge-dictionaries-in-python/
    """
    oldStatusStr = get_from_db(key='status')
    if oldStatusStr:
        oldStatusObj = json.loads(oldStatusStr)
        mergeObj = {**oldStatusObj, **userStatusObj}
        set_to_db(key='status', str_value=json.dumps(mergeObj))


def get_dict_from_db(key, fields=[]):
    """ Get a python dict object from redis.
        Return the required fields or all dict if the fields are not specified.
    """
    dataStr = get_from_db(key=key)
    dataObj = json.loads(dataStr)
    if not fields:
        return dataObj
    else:
        return {field: dataObj[field] for field in fields}


def get_server_status(fields=[]):
    """ Get server status object from redis.
    """
    return get_dict_from_db(key='status', fields=fields)


def get_ready_status():
    """ Get a `ready` flag in a server status object.
        This flag controls wherether the computational loop will continue or not
    """
    statusObj = get_server_status(fields=['ready'])
    return statusObj['ready']


def pause_server():
    """ After sending one dataframe containing the intermediate result to client,
        the server is paused in order to wait for the next command from client.
        The client can pause for a while to interact with the result,
        or it will send automatically an ACK to make the server to continue.
    """
    status = get_server_status(fields=['client_iter'])
    next_client_iter = status['client_iter'] + 1
    update_server_status({
        'client_iter': next_client_iter,
        'ready': False
    })


def continue_server():
    """ Util function to set a `ready` flag of server status object to True
        in order to make the computational loop continue running
    """
    update_server_status({'ready': True})


# Skeleton dataset meta data.
# The actual metatdata will be filled when the dataset being loaded.
skeleton_dataset_metadata = {
    'n_total': 0,
    'original_dim': 0,
    'reduced_dim': 0,
    'shape_X': [0, 0],
    'type_X': None,
    'shape_y': [0],
    'type_y': None
}


def set_dataset_metadata(metadata):
    """ Set dataset meta object to redis
    """
    set_to_db(key='metadata', str_value=json.dumps(metadata))


def get_dataset_metadata(fields=[]):
    """ Get meta data from redis and return the required fields
    """
    return get_dict_from_db(key='metadata', fields=fields)


def publish_data(data):
    """ Push intermediate result into a redis channel
    """
    redis_db.publish(DATA_CHANNEL, json.dumps(data))


def get_subscribed_data():
    """ Get subscribled from published channel in redis
    """
    msg = pubsub.get_message()
    if not msg or msg['type'] != 'message':
        return None

    data_obj = json.loads(msg['data'])
    embedding_str = data_obj['embedding'].encode('latin-1')
    data_obj['embedding'] = \
        np.fromstring(embedding_str, dtype=np.float32).reshape(-1, 2)
    return data_obj


# Utils function to get/set numpy ndarray

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


# Utils function for get dataset

def get_X():
    """ Util function to get original X
    """
    metadata = get_dataset_metadata(['shape_X', 'type_X'])
    return get_ndarray(name='X_original',
                       arr_shape=metadata['shape_X'],
                       arr_type=metadata['type_X'])


def get_y():
    """ Util function to get original y
    """
    metadata = get_dataset_metadata(['shape_y', 'type_y'])
    return get_ndarray(name='y_original',
                       arr_shape=metadata['shape_y'],
                       arr_type=metadata['type_y'])


def print_progress(i, n):
    """ Print processbar like:
        [=================================================] 99%
    """
    # percent = int(100.0 * i / n)
    # n_gap = int(percent / 2)
    sys.stdout.write('\r')
    # sys.stdout.write("[%s] %d%%" % ('=' * n_gap, percent))
    sys.stdout.write("[%s] (%d)" % ('=' * int(i / 50), i))
    sys.stdout.flush()
