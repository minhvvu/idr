module Plot.LineChart exposing (viewLineChart)

{-| This module shows how to build a simple line and area chart using some of
the primitives provided in this library.
-}

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.List as List
import Visualization.Scale as Scale exposing (ContinuousScale)
import Visualization.Shape as Shape


w : Float
w =
    650


h : Float
h =
    400


padding : Float
padding =
    30


viewLineChart : String -> List (List Float) -> Svg msg
viewLineChart color series =
    let
        yScale =
            series
                -- find max of each child list
                |> List.map (List.maximum >> Maybe.withDefault 0.0)
                -- max all
                |> List.maximum
                -- convert to real value
                |> Maybe.withDefault 0.0
                -- extend domain value
                |> (*) 1.1
                -- create tuple (0, maxX)
                |> (,) 0.0
                -- make f(a1, a2) as f(a2,a1)
                |> flip Scale.linear ( h - 2 * padding, 0.0 )

        xScale =
            series
                |> List.head
                |> Maybe.withDefault [ 0.0 ]
                |> List.length
                |> toFloat
                |> (,) 0.0
                |> flip Scale.linear ( 0.0, w - 2 * padding )

        xAxis =
            Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = 15 } xScale

        yAxis1 =
            Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 11 } yScale

        yAxis2 =
            let
                newestValues =
                    series
                        |> List.map (List.reverse >> List.head >> Maybe.withDefault 0.0)
            in
                Axis.axis { defaultOptions | orientation = Axis.Right, ticks = Just (newestValues) } yScale

        transformToLineData idx value =
            Just
                ( Scale.convert xScale (toFloat idx)
                , Scale.convert yScale value
                )

        line points =
            points
                |> List.indexedMap transformToLineData
                |> Shape.line Shape.monotoneInXCurve

        drawLine points =
            Svg.path [ d (line points), stroke color, strokeWidth "2px", fill "none" ] []
    in
        svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
            [ g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
                [ xAxis ]
            , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
                [ yAxis1 ]
            , g [ transform ("translate(" ++ toString (w - padding - 1) ++ ", " ++ toString padding ++ ")") ]
                [ yAxis2 ]
            , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ]
                (List.map drawLine series)
            ]
