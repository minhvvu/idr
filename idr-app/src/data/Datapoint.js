import Immutable from 'immutable';

const Datapoint = Immutable.Record({
  id: '',
  x_val: 0,
  y_val: 0,
  x: 0,
  y: 0,
  color: 'black',
  label: '',
  radius: 5,
});

export default Datapoint;