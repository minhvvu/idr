module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Button as Button exposing (secondary, onClick, attrs)
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Models exposing (Model)
import Msgs exposing (Msg(..))
import Plot.Scatter exposing (scatterView, movedPointsView)
import Plot.LineChart exposing (viewLineChart)


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet
        , Grid.row []
            [ Grid.col []
                [ Button.button
                    [ secondary, Button.attrs [ class "ml-2" ], onClick LoadDataset ]
                    [ text "Load dataset (MNIST)" ]
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-1" ] ]
                    [ ButtonGroup.button
                        [ secondary, onClick DoEmbedding ]
                        [ text "Do Embedding" ]
                    , ButtonGroup.button
                        [ secondary, onClick PauseServer ]
                        [ text "Pause Server" ]
                    , ButtonGroup.button
                        [ secondary, onClick ContinueServer ]
                        [ text "Continue Server" ]
                    ]
                , Button.button
                    [ secondary, Button.attrs [ class "ml-2" ], onClick ResetData ]
                    [ text "Reset Data" ]
                , Button.button
                    [ secondary, Button.attrs [ class "ml-2" ], onClick Msgs.SendMovedPoints ]
                    [ text "Send Moved Points" ]
                ]
            ]
        , Grid.row [] [ Grid.col [] [ text model.debugMsg ] ]
        , Grid.row []
            [ Grid.col [] [ scatterView model.scatter ]
            , Grid.col []
                [ Grid.row [] [ Grid.col [] [ movedPointsView model.scatter ] ]
                , Grid.row [] [ Grid.col [] [ viewLineChart ] ]
                ]
            ]
        ]
