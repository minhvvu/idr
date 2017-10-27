//Counter.js

let _counter = 1;

// simple counter for proving unique ids

const Counter = {
  increment () {
    return 'id-' + String(_counter++);
  }
};

export default Counter;