# tsnex_server.py
# minh, 20/12/2017

from flask import Flask
from flask_socketio import SocketIO, emit

app = Flask(__name__)
app.config['SECREST_KEY'] = 'tsnex'
socketio = SocketIO(app)


@app.route('/')
def index():
    return "Hello from flask-socket-io"


@socketio.on('connect')
def on_connect():
    print("Client connected", "TODO: get client info, session id")


@socketio.on('disconnect')
def on_disconnect():
    print("Client disconnect", "TODO: get info")


if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=5000, debug=True)
