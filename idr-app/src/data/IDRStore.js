//IDRStore.js

import Immutable from 'immutable';
import { ReduceStore } from 'flux/utils';
import IDRActionTypes from './IDRActionTypes';
import IDRDispatcher from './IDRDispatcher';
import Counter from './Counter';
import Todo from './Todo';

class IDRStore extends ReduceStore {

  constructor() {
    super(IDRDispatcher);
  }

  getInitialState() {
    return Immutable.OrderedMap();
  }

  reduce(state, action) {
    switch (action.type) {

      case IDRActionTypes.ADD_TODO:
        if (!action.text) {
          return state;
        }

        const id = Counter.increment();
        return state.set(id, new Todo({
          id,
          text: action.text,
          complete: false
        }));

      default:
        return state;
    }
  }

}

// using only one Store
export default new IDRStore();