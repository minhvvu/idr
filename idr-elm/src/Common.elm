module Common exposing (..)

import List.Extra exposing (maximumBy, minimumBy)
import Array
import Color exposing (..)
import Visualization.Scale exposing (category20a, category10)


type alias CircleId =
    String


type alias PlotConfig =
    { width : Float
    , height : Float
    , padding : Float
    , circleRadius : Float
    , minCircleRadius : Float
    , maxCircleRadius : Float
    , fixedRadius : Bool
    , autoZoom : Bool
    , strokeWidth : Float
    , defaultStrokeColor : String
    , selectedStrokeColor : String
    }


plotConfig : PlotConfig
plotConfig =
    { width = 860.0
    , height = 700.0
    , padding = 30.0
    , circleRadius = 6
    , minCircleRadius = 4
    , maxCircleRadius = 12
    , fixedRadius = False
    , autoZoom = True
    , strokeWidth = 0.5
    , defaultStrokeColor = "#D5D8DC"
    , selectedStrokeColor = "#E67E22"
    }


type alias Point =
    { id : String
    , x : Float
    , y : Float
    , z : Float
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
  - `knn`: index of k-nearest neighbors of each point
  - `seriesData`: a list of `SeriesData` for tracing errors, measurements, ...

-}
type alias EmbeddingResult =
    { embedding : List Point
    , knn : List (List Int)
    , seriesData : List SeriesData
    }


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


{-| Util function to get min/max value of field (x, y, z) in a list of points
-}
minField field points =
    case minimumBy field points of
        Nothing ->
            0

        Just p ->
            field p


maxField field points =
    case maximumBy field points of
        Nothing ->
            0

        Just p ->
            field p
