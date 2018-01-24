module Common exposing (..)

import List.Extra exposing (maximumBy, minimumBy)
import Array
import Color exposing (..)
import Visualization.Scale exposing (category20a)


-- http://package.elm-lang.org/packages/gampleman/elm-visualization/latest/Visualization-Scale


type alias CircleId =
    String


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
    , clientScale : Float
    , circleRadius : Float
    , strokeWidth : Float
    , defaultStrokeColor : String
    , selectedStrokeColor : String
    }


plotConfig : PlotConfig
plotConfig =
    { width = 1000.0
    , height = 850.0
    , padding = 50.0
    , clientScale = 50.0 -- client data value is scaled in range [-50.0, +50.0]
    , circleRadius = 7
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
