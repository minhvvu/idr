# tsnex_flask_socket.py
# using: https://github.com/kennethreitz/flask-sockets

from flask import Flask
from flask_sockets import Sockets


app = Flask(__name__)
sockets = Sockets(app)

all_data = []

@sockets.route('/echo')
def echo_socket(ws):
    while not ws.closed:
        message = ws.receive()
        all_data.append(message)
        print("Receive msg: ", message)
        print("All data: ", all_data)
        ws.send(message)


@app.route('/')
def hello():
    print("All data we have: ", all_data)
    return 'Hello World!'


if __name__ == "__main__":
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler
    app.debug = True
    server = pywsgi.WSGIServer(('', 5000), app, handler_class=WebSocketHandler)
    server.serve_forever()