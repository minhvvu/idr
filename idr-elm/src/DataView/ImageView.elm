module DataView.ImageView exposing (..)

import Array
import Html exposing (..)
import Html.Attributes as HtmlAttr exposing (..)
import Bootstrap.Badge as Badge
import Bootstrap.Utilities.Spacing as Spacing
import Models exposing (..)
import Common exposing (..)


view : String -> String -> DataModel -> Html msg
view datasetName selectedId { xDistances, xNeighbors, yDistances, yNeighbors } =
    let
        selectedImg =
            div [] [ showImage 128 datasetName selectedId 0.0 ]

        targetId =
            selectedId
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.withDefault -1

        xNeighborIds =
            Array.get targetId xNeighbors
                |> Maybe.withDefault []

        xDistanceToNeighbors =
            Array.get targetId xDistances
                |> Maybe.withDefault []

        neighborImgs =
            div [] (List.map2 (showImage 64 datasetName) xNeighborIds xDistanceToNeighbors)
    in
        Html.div [] [ selectedImg, neighborImgs ]


showImage : Int -> String -> String -> Float -> Html msg
showImage imageSize datasetName pointId distance =
    Html.figure
        [ HtmlAttr.style [ ( "float", "left" ), ( "boder", "1px" ) ] ]
        [ Html.img
            [ HtmlAttr.width imageSize
            , HtmlAttr.height imageSize
            , HtmlAttr.src ("/data/imgs/" ++ datasetName ++ ".svg#" ++ pointId)
            ]
            []
        , Html.figcaption [ HtmlAttr.style [ ( "font", "12px monospace" ) ] ]
            (if distance > 0 then
                [ Badge.pillSuccess [ Spacing.ml1 ] [ text <| toString <| round <| distance ]
                , Badge.pillLight [ Spacing.ml1 ] [ text <| toString <| round <| distance ]
                ]
             else
                [ text "" ]
            )
        ]
