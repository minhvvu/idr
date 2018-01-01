module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model)
import Msgs exposing (Msg)
import Plot.Scatter exposing (scatterView, movedPointsView)


view : Model -> Html Msg
view model =
    div []
        [ div [] [ button [ onClick Msgs.RequestData ] [ Html.text "Request Data" ] ]
        , scatterView model.scatter
        , movedPointsView model.scatter
        ]
