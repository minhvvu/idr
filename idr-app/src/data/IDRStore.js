//IDRStore.js

import Immutable from 'immutable';
import { ReduceStore } from 'flux/utils';
import IDRActionTypes from './IDRActionTypes';
import IDRDispatcher from './IDRDispatcher';
import Counter from './Counter';
import Todo from './Todo';
import Datapoint from './Datapoint';

class IDRStore extends ReduceStore {

  constructor() {
    super(IDRDispatcher);
  }

  getInitialState() {
    return Immutable.OrderedMap();
  }

  reduce(state, action) {
    switch (action.type) {
      case IDRActionTypes.REFRESH_DATASET:
        console.log("Before: ", state);
        action.dataset.forEach( (item, index, _) => {
          state.set(index, new Datapoint({
            id: index,
            x_val: item.x,
            y_val: item.y,
            x: 0,
            y: 0
          }) );
        });
        console.log("After: ", state);
        return state;

      default:
        return state;
    }
  }

}

// using only one Store
export default new IDRStore();