module View exposing (view)

import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (class, min, max, value)
import Html.Events as HtmlEvents exposing (onInput)
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Button as Button exposing (secondary, onClick, attrs)
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Bootstrap.Form as BForm
import Models exposing (Model)
import Msgs exposing (Msg(..))
import Plot.Scatter exposing (scatterView, movedPointsView)
import Plot.LineChart exposing (viewLineChart)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row [ Row.betweenSm ]
            [ Grid.col []
                [ Button.button
                    [ secondary, Button.attrs [ class "ml-2" ], onClick LoadDataset ]
                    [ text "Load dataset" ]
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
        , Grid.row [ Row.betweenSm ]
            [ Grid.col [] [ text model.debugMsg ]
            , Grid.col []
                [ Html.label [] [ text "Zoom factor:" ]
                , input
                    [ HtmlAttrs.type_ "range"
                    , HtmlAttrs.value (toString model.zoomFactor)
                    , HtmlAttrs.min "1"
                    , HtmlAttrs.max "100"
                    , HtmlEvents.onInput UpdateZoomFactor
                    ]
                    []
                , text (toString model.zoomFactor)
                ]
            ]
        , Grid.row [ Row.betweenSm ]
            [ Grid.col []
                [ scatterView model.scatter ]
            , Grid.col []
                (model.seriesData
                    |> List.map
                        (\aseries -> viewLineChart aseries.name aseries.series)
                )
            ]
        , Grid.row [ Row.betweenSm ]
            [ Grid.col []
                [ movedPointsView model.scatter
                ]
            ]
        ]
