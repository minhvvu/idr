import React, {Component} from 'react';
import * as d3Axis from 'd3-axis';
import { select as d3Select } from 'd3-selection';

import './axis.css';

export default class Axis extends Component {

	// we just use props, not state, so call re-render axis manually
	componentDidMount() {
		this.renderAxis();
	}

	componentDidUpdate() {
		this.renderAxis();
	}

	renderAxis() {
		const {orient, scale, translate, tickSize} = this.props;
		const axisType = `axis${orient}`;
		const axis = d3Axis[axisType]()
			.scale(scale)
			.tickSize(-tickSize)
			.tickPadding([10])
			.ticks([10]);

		d3Select(this.axisElement).call(axis);
	}

	render() {
		return (
			<g
				className={`axis axis-${this.props.orient}`}
				ref={(el)=>{this.axisElement=el;}}
				transform={this.props.translate}
			/>
		);
	}
}