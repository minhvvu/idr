module Plot.LineChart exposing (LineSeries, emptySeries, createSeries, viewLineChart)

{-| This module shows how to build a simple line and area chart using some of
the primitives provided in this library.
-}

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.List as List
import Visualization.Scale as Scale exposing (ContinuousScale)
import Visualization.Shape as Shape


type alias LineSeries =
    { series : List Float
    , xScale : ContinuousScale
    , yScale : ContinuousScale
    }


emptySeries : LineSeries
emptySeries =
    { series = [ 0.0 ]
    , xScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    , yScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    }


w : Float
w =
    650


h : Float
h =
    400


padding : Float
padding =
    30


xScaler : Float -> ContinuousScale
xScaler maxX =
    Scale.linear ( 0, maxX ) ( 0, w - 2 * padding )


yScaler : Float -> ContinuousScale
yScaler maxY =
    Scale.linear ( 0, maxY ) ( h - 2 * padding, 0 )


xAxis : LineSeries -> Svg msg
xAxis { xScale } =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = 15 } xScale


yAxis : LineSeries -> Svg msg
yAxis { yScale } =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 12 } yScale


createSeries : List Float -> LineSeries
createSeries data =
    let
        maxX =
            (toFloat (List.length data)) * 1.2

        xScale =
            xScaler maxX

        maxY =
            Maybe.withDefault 10.0 <| List.maximum data

        yScale =
            yScaler maxY
    in
        { series = data
        , xScale = xScale
        , yScale = yScale
        }


line : LineSeries -> Attribute msg
line { series, xScale, yScale } =
    let
        transformToLineData it cost =
            Just
                ( Scale.convert xScale (toFloat it)
                , Scale.convert yScale cost
                )
    in
        List.indexedMap transformToLineData series
            |> Shape.line Shape.monotoneInXCurve
            |> d


viewLineChart : LineSeries -> Svg msg
viewLineChart model =
    svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
        [ g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
            [ xAxis model ]
        , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
            [ yAxis model ]
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ]
            [ Svg.path [ line model, stroke "red", strokeWidth "2px", fill "none" ] [ text "ABC" ] ]
        ]
