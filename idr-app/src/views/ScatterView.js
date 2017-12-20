import React, { Component } from 'react';

export default class ScatterView extends Component {

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