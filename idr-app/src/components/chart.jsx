import React, { Component } from 'react';
import { scaleBand, scaleLinear } from 'd3-scale';

import Axes from './axes';
import Bars from './bars';
import Circles from './circles';

// https://medium.com/@caspg/responsive-chart-with-react-and-d3v4-afd717e57583

export default class Chart extends Component {

	constructor() {
		super();
		this.xScale = scaleBand();
		this.yScale = scaleLinear();
	}

	render() {

		const margins = {top:50, right:20, bottom:100, left:60};
		const svgSize = {width:800, height:500};
		const data = this.props.data;
		
		const maxValue = Math.max(... // extract all values
			// max function accepts list of value, but we have an array
			data.map(d => d.value)
		);

		const scales = {
			xScale: this.xScale
				.padding(0.5)
				.domain(data.map(d => d.title))
				.range([margins.left, svgSize.width - margins.right]),
			yScale: this.yScale
				.domain([0, maxValue])
				.range([svgSize.height - margins.bottom, margins.top])
			};

		const axesProperties = { scales, margins, svgSize };
		const chartProperties = { scales, margins, svgSize, data, maxValue };

		return (
			<svg width={svgSize.width} height={svgSize.height}>
				
				<Axes {...axesProperties} />

				<Bars {...chartProperties} />

				<Circles {...chartProperties} />

			</svg>
		);
	}
}