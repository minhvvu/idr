import React, { Component } from 'react';
import { scaleLinear } from 'd3-scale';
import { interpolateLab } from 'd3-interpolate';

import './circle.css';

export default class Circles extends Component {

	constructor(props) {
		super(props);

		this.colorScale = scaleLinear()
			.domain([0, this.props.maxValue])
			.range(['#FFF', '#000'])
			.interpolate(interpolateLab);
	}
	
	handleMouseDown(evt) {
		console.log("Mouse down", evt);
	};

	render() {
		const { scales, margins, svgSize, data, maxValue } = this.props;
		const { xScale, yScale } = scales;
		const { height } = svgSize;

		const circles = ( data.map(d => 
			<circle
				className="draggable"
				key={d.title}
				cx={xScale(d.title) + xScale.bandwidth()/2}
				cy={yScale(d.value/2)}
				r={d.value / 2}
				fill={this.colorScale(d.value)}
				onMouseDown={this.handleMouseDown}
			/>
		));

		return (
			<g>
				{circles}
			</g>
		);
	}

}