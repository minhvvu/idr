module Plot.Scatter exposing (scatterPlot, mapRawDataToScatterPlot)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Draggable
import Draggable.Events exposing (onClick, onDragBy, onDragStart)
import Msgs exposing (Msg)
import Models exposing (Model)
import Common exposing (..)
import Plot.Circle exposing (..)
import Plot.CircleGroup exposing (..)


type alias PlotConfig =
    { width : Float
    , height : Float
    , padding : Float
    }


config : PlotConfig
config =
    { width = 400.0
    , height = 400.0
    , padding = 30.0
    }



-- TODO think about AXES latter


type alias Scatter =
    { config : PlotConfig
    , rawData : List Point
    , xScale : ContinuousScale
    , yScale : ContinuousScale
    }


createScatter : List Point -> Scatter
createScatter points =
    { config = config
    , rawData = points
    , xScale =
        Scale.linear
            ( minX points, maxX points )
            ( 0, config.width - 2 * config.padding )
    , yScale =
        Scale.linear
            ( minY points, maxY points )
            ( config.height - 2 * config.padding, 0 )
    }


mapRawDataToScatterPlot : List Point -> CircleGroup
mapRawDataToScatterPlot rawPoints =
    let
        scatter =
            createScatter rawPoints

        mappedPoints =
            rawPoints
                |> List.map
                    (\p ->
                        (Point
                            p.id
                            (Scale.convert scatter.xScale p.x)
                            (Scale.convert scatter.yScale p.y)
                        )
                    )
    in
        createCircleGroup mappedPoints


scatterPlot : Model -> Svg Msg
scatterPlot { points } =
    svg
        [ width <| px <| plotWidth
        , height <| px <| plotHeight
        ]
        [ drawAxis (plotHeight - padding) xAxis
        , drawAxis padding yAxis
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")") ]
            [ circleGroupView points ]
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



--circle point =
--    g []
--        [ Svg.circle
--            [ cx <| toString <| Scale.convert xScale point.x
--            , cy <| toString <| Scale.convert yScale point.y
--            , r "3px"
--            ]
--            []
--        ]
