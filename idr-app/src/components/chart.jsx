import React, { Component } from 'react';
import { scaleBand, scaleLinear } from 'd3-scale';

export default class Chart extends Component {
	render() {
		console.log("Data render: ", this.props.data);
		
		return (
			<div>Chart Component!</div>
		);
	}
}