# flask with socket-io

from flask import Flask
from flask_socketio import SocketIO, emit
import random
import simple_mds as test


app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app)

APP_CHANNEL = 'OCI-MDS'


@socketio.on('connect')
def client_connect():
    print("Client connected")
    emit('hello', {'data': 'Hello from Flask server'})


@socketio.on('request_initial_data')
def get_initial_data():
    scatter_data = test.iris_pca()
    emit('initial_data', scatter_data, json=True)


@socketio.on('inform_client_move')
def client_move(p):
    print("Client move: ", p)
    p['random_color'] = "#%06X" % random.randint(0, 256**3 - 1)
    emit('client_move_ok', p, json=True)


if __name__ == '__main__':
    socketio.run(app,
                 host='127.0.0.1',
                 port=9990,
                 debug=True)
