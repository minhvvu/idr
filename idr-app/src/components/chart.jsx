import React, { Component } from 'react';
import { scaleLinear} from 'd3-scale';

import Axes from './axes';
import Circles from './circles';

// https://medium.com/@caspg/responsive-chart-with-react-and-d3v4-afd717e57583

export default class Chart extends Component {

	constructor(props) {
		super(props);
		this.xScale = scaleLinear();
		this.yScale = scaleLinear();
	}

	movePoint(id, x, y) {
		this.props.movePoint(id, x, y);
	}

	render() {
		const margins = {top:50, right:20, bottom:100, left:60};
		const svgSize = {width:800, height:500};
		const data = this.props.data;
		
		const scales = {
			xScale: this.xScale
				.domain([-4.0, 4.0])
				.range([margins.left, svgSize.width - margins.right]),
			yScale: this.yScale
				.domain([-1.5, 1.5])
				.range([svgSize.height - margins.bottom, margins.top])
			};

		const axesProperties = { scales, margins, svgSize };
		const chartProperties = { scales, data };

		return (
			<svg width={svgSize.width} height={svgSize.height}>
				
				<Axes {...axesProperties} />

				<Circles {...chartProperties} />

			</svg>
		);
	}
}