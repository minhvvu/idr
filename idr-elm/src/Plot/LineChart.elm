module Plot.LineChart exposing (viewLineChart)

{-| This module shows how to build a simple line and area chart using some of
the primitives provided in this library.
-}

import Date exposing (Date)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.List as List
import Visualization.Scale as Scale exposing (ContinuousScale, ContinuousTimeScale)
import Visualization.Shape as Shape


type alias Point =
    { it : Float
    , cost : Float
    }


type alias Model =
    List Point


timeSeries : Model
timeSeries =
    [ Point 1 2.5
    , Point 2 2
    , Point 3 3.5
    , Point 4 2
    , Point 5 3
    , Point 6 1
    , Point 7 1.2
    ]


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
    Scale.linear ( 0, 10 ) ( 0, w - 2 * padding )


yScale : ContinuousScale
yScale =
    Scale.linear ( 0, 5 ) ( h - 2 * padding, 0 )


xAxis : Model -> Svg msg
xAxis model =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = List.length model } xScale


yAxis : Svg msg
yAxis =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 5 } yScale


transformToLineData : Point -> Maybe ( Float, Float )
transformToLineData { it, cost } =
    Just ( Scale.convert xScale it, Scale.convert yScale cost )


tranfromToAreaData : Point -> Maybe ( ( Float, Float ), ( Float, Float ) )
tranfromToAreaData { it, cost } =
    Just
        ( ( Scale.convert xScale it, Tuple.first (Scale.rangeExtent yScale) )
        , ( Scale.convert xScale it, Scale.convert yScale cost )
        )


line : Model -> Attribute msg
line model =
    List.map transformToLineData model
        |> Shape.line Shape.monotoneInXCurve
        |> d


area : Model -> Attribute msg
area model =
    List.map tranfromToAreaData model
        |> Shape.area Shape.monotoneInXCurve
        |> d


view : Model -> Svg msg
view model =
    svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
        [ g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
            [ xAxis model ]
        , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
            [ yAxis ]
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ]
            [ Svg.path [ area model, stroke "none", strokeWidth "3px", fill "rgba(255, 0, 0, 0.54)" ] []
            , Svg.path [ line model, stroke "red", strokeWidth "3px", fill "none" ] []
            ]
        ]


viewLineChart : Svg msg
viewLineChart =
    view timeSeries
