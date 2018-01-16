module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model)
import Msgs exposing (Msg)
import Plot.Scatter exposing (scatterView, movedPointsView)


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button [ onClick Msgs.RequestData ] [ text "Request Data" ]
            , button [ onClick Msgs.PauseServer ] [ text "Pause Server" ]
            , button [ onClick Msgs.ContinueServer ] [ text "Continue Server" ]
            ]
        , scatterView model.scatter
        , movedPointsView model.scatter
        , div [] [ button [ onClick Msgs.SendMovedPoints ] [ text "Send Moved Points" ] ]
        ]
