module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model, Point)
import Msgs exposing (Msg)
import Plot.Scatter exposing (scatterPlot)


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Msgs.RequestData ] [ Html.text "Request Data" ]
        , scatterPlot model.points
        , div [] (List.map printPoint model.points)
        ]


printPoint : Point -> Html Msg
printPoint { id, x, y } =
    div []
        [ Html.text ("id: " ++ toString id ++ ", x: " ++ toString x ++ ", y: " ++ toString y)
        ]
