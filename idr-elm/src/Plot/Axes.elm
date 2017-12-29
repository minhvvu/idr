module Plot.Axes exposing (..)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Scale as Scale exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Common exposing (plotConfig)


{-| Public API for drawing 2 axes
-}
drawAxes : ( ContinuousScale, ContinuousScale ) -> Svg msg
drawAxes ( xScale, yScale ) =
    let
        ( xAxis, yAxis ) =
            createAxes ( xScale, yScale )

        padding =
            plotConfig.padding

        xOffset =
            plotConfig.height - padding

        yOffset =
            padding
    in
        g []
            [ drawAxis padding xOffset xAxis
            , drawAxis padding yOffset yAxis
            ]


{-| Private function to create axes from axis-scales
-}
createAxes : ( ContinuousScale, ContinuousScale ) -> ( Svg msg, Svg msg )
createAxes ( xScale, yScale ) =
    let
        xAxis =
            Axis.axis
                { defaultOptions | orientation = Axis.Bottom, tickCount = 10 }
                xScale

        yAxis =
            Axis.axis
                { defaultOptions | orientation = Axis.Left, tickCount = 10 }
                yScale
    in
        ( xAxis, yAxis )


{-| Util for drawing an axis
-}
drawAxis : Float -> Float -> Svg msg -> Svg msg
drawAxis padding offset axis =
    g [ transform ("translate(" ++ toString (padding) ++ ", " ++ toString (offset) ++ ")") ]
        [ axis ]
