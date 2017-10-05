import React, { Component } from 'react';
import { scaleLinear } from 'd3-scale';
import { interpolateLab } from 'd3-interpolate';

export default class Bars extends Component {

	constructor(props) {
		super(props);

		this.colorScale = scaleLinear()
			.domain([0, this.props.maxValue])
			.range(['#F3E5F5', '#7B1FA2'])
			.interpolate(interpolateLab);
	}

	render() {

		const { scales, margins, svgSize, data, maxValue } = this.props;
		const { xScale, yScale } = scales;
		const { height } = svgSize;

		const bars = ( data.map(d => 
			<rect
				key={d.title}
				x={xScale(d.title)}
				y={yScale(d.value)}
				width={xScale.bandwidth()}
				height={height - margins.bottom - yScale(d.value)}
				fill={this.colorScale(d.value)}
			/>
		));

		return (
			<g>
				{bars}
			</g>
		);
	}

}