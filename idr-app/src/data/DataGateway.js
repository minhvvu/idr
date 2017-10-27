import SocketIOClient from 'socket.io-client';

class DataGateway {

  constructor() {
  }

  connectSocket() {
    const serverUrl = 'http://127.0.0.1:9990';
    this.socket = SocketIOClient(serverUrl);
    console.log("Client Connect: ", serverUrl);

    this.socket.on('connect', () => {
        console.log("Client Connected!");
        this.socket.emit('request_initial_data');
    }).on('initial_data', (json) => {
        console.log("Server initial data: ", json.length);
        //TODO do st with new data
    });

    this.socket.on('client_move_ok', (msg) => {
        console.log('Server update client moving', msg);
    });
  }
}

export default new DataGateway();