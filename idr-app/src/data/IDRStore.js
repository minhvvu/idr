//IDRStore.js

// import Immutable from 'immutable';
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
    // return Immutable.Map();
    //TODO Think about immutable state
    return [];
  }

  reduce(state, action) {
    switch (action.type) {
      case IDRActionTypes.REFRESH_DATASET:
        // state = action.dataset.map( (item, index, _) => {
        //   index: new Datapoint({
        //     id: index,
        //     x_val: item.x,
        //     y_val: item.y,
        //     x: 0,
        //     y: 0
        //   })}
        // );
        // return state;
        return action.dataset;

      default:
        return state;
    }
  }

}

// using only one Store
export default new IDRStore();