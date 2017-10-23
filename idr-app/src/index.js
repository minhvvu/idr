import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

import AppContainer from './containers/AppContainer';
import IDRActions from './data/IDRActions';

ReactDOM.render(<App />, document.getElementById('root'));

// ReactDOM.render(
//   <AppContainer />, document.getElementById('todoapp')
// );

// IDRActions.addTodo('My first Task');
// IDRActions.addTodo('HelloWorld');
// IDRActions.addTodo('Fix me');

registerServiceWorker();
