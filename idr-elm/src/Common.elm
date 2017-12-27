module Common exposing (..)

import List.Extra exposing (maximumBy, minimumBy)


type alias CircleId =
    String


toCircleId : number -> String
toCircleId a =
    toString a


type alias Point =
    { id : Int
    , x : Float
    , y : Float
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
