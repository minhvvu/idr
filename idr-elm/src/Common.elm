module Common exposing (..)

import List.Extra exposing (maximumBy, minimumBy)
import Array
import Color exposing (..)
import Visualization.Scale exposing (category20a, category10)


type alias CircleId =
    String


{-| <http://package.elm-lang.org/packages/gampleman/elm-visualization/latest/Visualization-Scale>
-}
intToColor10Str : Int -> String
intToColor10Str idx =
    category10
        |> Array.fromList
        |> Array.get (idx % 10)
        |> Maybe.withDefault Color.blue
        |> colorToString


labelToColorStr : String -> String
labelToColorStr label =
    let
        labelId =
            label
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.withDefault 0
    in
        category20a
            |> Array.fromList
            |> Array.get labelId
            |> Maybe.withDefault Color.black
            |> colorToString


colorToString : Color -> String
colorToString color =
    let
        { red, green, blue, alpha } =
            toRgb color
    in
        "rgba("
            ++ (red |> toString)
            ++ ","
            ++ (green |> toString)
            ++ ", "
            ++ (blue |> toString)
            ++ ","
            ++ (alpha |> toString)
            ++ ")"


type alias PlotConfig =
    { width : Float
    , height : Float
    , padding : Float
    , circleRadius : Float
    , strokeWidth : Float
    , defaultStrokeColor : String
    , selectedStrokeColor : String
    }


plotConfig : PlotConfig
plotConfig =
    { width = 900.0
    , height = 800.0
    , padding = 30.0
    , circleRadius = 6
    , strokeWidth = 2
    , defaultStrokeColor = "#D5D8DC"
    , selectedStrokeColor = "#E67E22"
    }


type alias Point =
    { id : String
    , x : Float
    , y : Float
    , label : String
    , fixed : Bool
    }


{-| Data structure for storing a series data for all iterations, including:

  - `name`: readable name of series data, e.g. "Errors" or "PIVE Measures"
  - `series`: a list of series data, each series data is an array of float

-}
type alias SeriesData =
    { name : String
    , series : List (List Float)
    }


emptySeriesData =
    { name = "", series = [] }


{-| Data structure that the server returns after each iteration, including:

  - `embedding`: a list of new position of embedded points
  - `seriesData`: a list of `SeriesData` for tracing errors, measurements, ...

-}
type alias EmbeddingResult =
    { embedding : List Point
    , seriesData : List SeriesData
    }


{-| Util function to get minimum/maximum value of x or y field
in a list of points
-}
minX : List Point -> Float
minX points =
    case (minimumBy .x points) of
        Nothing ->
            0

        Just point ->
            point.x


maxX : List Point -> Float
maxX points =
    case (maximumBy .x points) of
        Nothing ->
            0

        Just point ->
            point.x


minY : List Point -> Float
minY points =
    case (minimumBy .y points) of
        Nothing ->
            0

        Just point ->
            point.y


maxY : List Point -> Float
maxY points =
    case (maximumBy .y points) of
        Nothing ->
            0

        Just point ->
            point.y
