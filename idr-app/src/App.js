import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';

import data from './test_data.js';
import Chart from './components/chart';

class App extends Component {
  render() {
    return (
      <div className="App">
        <p>IDR Interactive Dimensionality Reduction</p>
        <Chart data={data} />
      </div>
    );
  }
}

export default App;
