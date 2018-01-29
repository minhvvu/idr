module Plot.LineChart exposing (Series, viewLineChart)

{-| This module shows how to build a simple line and area chart using some of
the primitives provided in this library.
-}

import Date exposing (Date)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.List as List
import Visualization.Scale as Scale exposing (ContinuousScale)
import Visualization.Shape as Shape


type alias Series =
    List Float


w : Float
w =
    650


h : Float
h =
    400


padding : Float
padding =
    30


xScale : ContinuousScale
xScale =
    Scale.linear ( 0, 500 ) ( 0, w - 2 * padding )


yScale : ContinuousScale
yScale =
    Scale.linear ( 0, 100 ) ( h - 2 * padding, 0 )


xAxis : Series -> Svg msg
xAxis model =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = List.length model } xScale


yAxis : Svg msg
yAxis =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 5 } yScale


transformToLineData : Int -> Float -> Maybe ( Float, Float )
transformToLineData it cost =
    Just ( Scale.convert xScale (toFloat it), Scale.convert yScale cost )


tranfromToAreaData : Int -> Float -> Maybe ( ( Float, Float ), ( Float, Float ) )
tranfromToAreaData it cost =
    Just
        ( ( Scale.convert xScale (toFloat it), Tuple.first (Scale.rangeExtent yScale) )
        , ( Scale.convert xScale (toFloat it), Scale.convert yScale cost )
        )


line : Series -> Attribute msg
line model =
    List.indexedMap transformToLineData model
        |> Shape.line Shape.monotoneInXCurve
        |> d


area : Series -> Attribute msg
area model =
    List.indexedMap tranfromToAreaData model
        |> Shape.area Shape.monotoneInXCurve
        |> d


viewLineChart : Series -> Svg msg
viewLineChart model =
    svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
        [ g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
            [ xAxis model ]
        , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
            [ yAxis ]
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ]
            [ --Svg.path [ area model, stroke "none", strokeWidth "3px", fill "rgba(255, 0, 0, 0.54)" ] []
              Svg.path [ line model, stroke "red", strokeWidth "3px", fill "none" ] []
            ]
        ]
