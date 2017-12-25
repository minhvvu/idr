module Plot.Scatter exposing (scatterPlot)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Models exposing (Point)
import Msgs exposing (Msg)


scatterPlot : List Point -> Svg Msg
scatterPlot points =
    svg
        [ width <| px <| plotWidth
        , height <| px <| plotHeight
        ]
        [ drawAxis (plotHeight - padding) xAxis
        , drawAxis padding yAxis
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")") ] <|
            List.map circle points
        ]


drawAxis : Float -> Svg msg -> Svg msg
drawAxis offset axis =
    g [ transform ("translate(" ++ toString (padding) ++ ", " ++ toString (offset) ++ ")") ]
        [ axis ]


px : Float -> String
px i =
    (toString i) ++ "px"


plotWidth : Float
plotWidth =
    600


plotHeight : Float
plotHeight =
    600


padding : Float
padding =
    30


xScale : ContinuousScale
xScale =
    Scale.linear ( -5, 5 ) ( 0, plotWidth - 2 * padding )


yScale : ContinuousScale
yScale =
    Scale.linear ( -5, 5 ) ( plotHeight - 2 * padding, 0 )


xAxis : Svg msg
xAxis =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = 5 } xScale


yAxis : Svg msg
yAxis =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 5 } yScale


circle point =
    g []
        [ Svg.circle
            [ cx <| toString <| Scale.convert xScale point.x
            , cy <| toString <| Scale.convert yScale point.y
            , r "3px"
            ]
            []
        ]
