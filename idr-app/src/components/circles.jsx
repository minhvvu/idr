import React, { Component } from 'react';
import { scaleLinear } from 'd3-scale';
import { interpolateLab } from 'd3-interpolate';

import clickdrag from 'react-clickdrag';

import './circle.css';

class Circle extends Component {

	constructor(props) {
		super(props);

		this.state = {
			lastCX: 0,
			lastCY: 0,
			currentCX: this.props.cx,
			currentCY: this.props.cy
		}
	}

	componentWillReceiveProps(nextProps) {
		if (nextProps.dataDrag.isMoving) {
			this.setState({
				currentCX: this.state.lastCX + nextProps.dataDrag.moveDeltaX,
				currentCY: this.state.lastCY + nextProps.dataDrag.moveDeltaY
			});
		} else {
			this.setState({
				lastCX: this.state.currentCX,
				lastCY: this.state.currentCY
			});
		}
	}


	render() {
		return (
			<circle
				key={this.props.title}
				cx={this.state.currentCX}
				cy={this.state.currentCY}
				r={this.props.r}
				fill={this.props.color}
			/>
		);
	}
}

var DraggableCircle = clickdrag(Circle, {touch:true});

export default class Circles extends Component {

	constructor(props) {
		super(props);

		this.colorScale = scaleLinear()
			.domain([0, this.props.maxValue])
			.range(['#FFF', '#000'])
			.interpolate(interpolateLab);
	}

	render() {
		const { scales, margins, svgSize, data, maxValue } = this.props;
		const { xScale, yScale } = scales;
		const { height } = svgSize;

		const circles = ( data.map(d => 
			<DraggableCircle
				key={d.title}
				r={d.value / 2}
				cx={xScale(d.title) + xScale.bandwidth()/2}
				cy={yScale(d.value/2)}
				fill={this.colorScale(d.value)}
			/>
		));

		return (
			<g>
				{circles}
			</g>
		);
	}

}
