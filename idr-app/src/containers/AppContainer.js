//AppContainer.js

import AppView from '../views/AppView';
import {Container} from 'flux/utils';
import IDRStore from '../data/IDRStore';

function getStores() {
  return [
    IDRStore
  ];
}

function getState() {
  return {
    dataset: IDRStore.getState(),
  };
}

export default Container.createFunctional(
  AppView, getStores, getState
);