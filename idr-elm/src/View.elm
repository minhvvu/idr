module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model)
import Msgs exposing (Msg(..))
import Plot.Scatter exposing (scatterView, movedPointsView)


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button [ onClick LoadDataset ] [ text "Load dataset (MNIST)" ]
            , button [ onClick DoEmbedding ] [ text "Do Embedding" ]
            , button [ onClick PauseServer ] [ text "Pause Server" ]
            , button [ onClick ContinueServer ] [ text "Continue Server" ]
            , button [ onClick ResetData ] [ text "Reset Data" ]
            ]
        , div [] [ text model.debugMsg ]
        , scatterView model.scatter
        , movedPointsView model.scatter
        , div [] [ button [ onClick Msgs.SendMovedPoints ] [ text "Send Moved Points" ] ]
        ]
