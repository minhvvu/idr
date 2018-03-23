module DataView.ImageView exposing (..)

import Array
import Html exposing (..)
import Html.Attributes as HtmlAttr exposing (..)
import Bootstrap.Badge as Badge
import Bootstrap.Utilities.Spacing as Spacing
import Models exposing (..)
import Common exposing (..)


view : Model -> Html msg
view { scatter, neighbors, distances, cf } =
    let
        selectedImg =
            div [] [ showImage 12.0 cf.datasetName scatter.selectedId 0.0 ]

        selectedId =
            scatter.selectedId
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.withDefault -1

        neighborIds =
            Array.get selectedId neighbors
                |> Maybe.withDefault []

        distanceToNeighbors =
            Array.get selectedId distances
                |> Maybe.withDefault []

        neighborImgs =
            div [] (List.map2 (showImage 6.0 cf.datasetName) neighborIds distanceToNeighbors)
    in
        Html.div [] [ selectedImg, neighborImgs ]


showImage : Float -> String -> String -> Float -> Html msg
showImage scaleFactor datasetName pointId distance =
    let
        imageSize =
            datasetName
                |> getImageSize
                |> (*) scaleFactor
                |> round
    in
        Html.figure [ HtmlAttr.style [ ( "float", "left" ), ( "boder", "1px" ) ] ]
            [ Html.img
                [ HtmlAttr.width imageSize
                , HtmlAttr.height imageSize
                , HtmlAttr.src ("/data/imgs/" ++ datasetName ++ ".svg#" ++ pointId)
                ]
                []
            , Html.figcaption [ HtmlAttr.style [ ( "font", "12px monospace" ), ( "color", "red" ) ] ]
                (if distance > 0 then
                    [ Badge.pillSuccess [ Spacing.ml2 ] [ text <| toString <| round <| distance ]
                    , Badge.pillLight [ Spacing.ml2 ] [ text <| toString <| round <| distance ]
                    ]
                 else
                    [ text "" ]
                )
            ]
