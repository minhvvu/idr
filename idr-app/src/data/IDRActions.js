//IDRActions.js

import IDRActionTypes from './IDRActionTypes';
import IDRDispatcher from './IDRDispatcher';

const Actions = {

  // each function is an action
  addTodo(text) {
    IDRDispatcher.dispatch({
      type: IDRActionTypes.ADD_TODO,
      text,
    });
  },

  refreshDataset(dataset) {
    IDRDispatcher.dispatch({
        type: IDRActionTypes.REFRESH_DATASET,
        dataset,
    });
  },

  movePoint(id, delta) {
    IDRDispatcher.dispatch({
      type: IDRActionTypes.MOVE_POINT,
      id,
      delta,
    });
  }

};

export default Actions;