import React, { Component } from 'react';
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
		this.colors = ['red', 'green', 'blue'];
	}

	render() {
		const { scales, data } = this.props;
		const { xScale, yScale } = scales;

		const circles = ( data.map((d, idx) => 
			<DraggableCircle
				key={idx}
				r="5"
				cx={xScale(d.x)}
				cy={yScale(d.y)}
				color={this.colors[d.label]}
			/>
		));

		return (
			<g>
				{circles}
			</g>
		);
	}

}
