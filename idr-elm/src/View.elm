module View exposing (view)

import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (class, min, max, value, src)
import Html.Events as HtmlEvents exposing (onInput)
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col
import Bootstrap.Button as Button exposing (secondary, onClick, attrs)
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Bootstrap.Form as BForm
import Models exposing (Model)
import Msgs exposing (Msg(..))
import Plot.Scatter exposing (scatterView, movedPointsView, selectedPointsView)
import Plot.LineChart exposing (viewLineChart)
import Svg exposing (image)
import Svg.Attributes exposing (x, y, xlinkHref)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row [{- A serie of buttons -}]
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
        , Grid.row [{- debug message and slider for param controlling -}]
            [ Grid.col [] [ text model.debugMsg ]
            , Grid.col []
                [ Html.label [] [ text "Zoom factor:" ]
                , input
                    [ HtmlAttrs.type_ "range"
                    , HtmlAttrs.value (toString model.zoomFactor)
                    , HtmlAttrs.min "1"
                    , HtmlAttrs.max "150"
                    , HtmlEvents.onInput UpdateZoomFactor
                    ]
                    []
                , text (toString model.zoomFactor)
                ]
            ]
        , Grid.row [{- main content: scatter plot and detail view for selected and moved point -}]
            [ Grid.col [] [ scatterView model.scatter ]
            , Grid.col []
                [ Grid.row [] [ Grid.col [] [ selectedPointsView model.scatter ] ]
                , Grid.row [] [ Grid.col [] [ movedPointsView model.scatter ] ]
                ]
            ]
        , Grid.row [{- line charts for measurement -}]
            [ Grid.col []
                (model.seriesData
                    |> List.map
                        (\aseries -> viewLineChart aseries.name aseries.series)
                )
            ]
        ]
