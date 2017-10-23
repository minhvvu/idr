import React, { Component } from 'react';
import SocketIOClient from 'socket.io-client';

import './App.css';

import Chart from './components/chart';

class App extends Component {

  constructor(props) {
    super(props);   
    this.state = {data: []};
    this.connectSocket();

    this.movePoint = this.movePoint.bind(this);
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
        this.setState({data: json});
        this.forceUpdate();
    });

    this.socket.on('client_move_ok', (msg) => {
        console.log('Server update client moving', msg);
    });
  }

  movePoint(id, newX, newY) {
    console.log("Client move point: ", id);
    this.socket.emit('inform_client_move', {id:id, x:newX, y:newY});
  }

  render() {
    return (
      <div className="App">
        <p>IDR Interactive Dimensionality Reduction</p>
        <Chart data={this.state.data} movePoint={this.movePoint} />
      </div>
    );
}
}

export default App;
