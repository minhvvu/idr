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
import Bootstrap.Form.Select as Select exposing (..)
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
        , Grid.row [{- select box for dataset and debug message -}]
            [ Grid.col []
                [ Select.select
                    [ Select.id "dataset-name"
                    , Select.onChange SelectDataset
                    ]
                    [ Select.item [ value "" ] [ text "--Select dataset--" ]
                    , Select.item [ value "MNIST-SMALL" ] [ text "MNIST mini" ]
                    , Select.item [ value "MNIST" ] [ text "MNIST full sample 3000" ]
                    , Select.item [ value "COIL20" ] [ text "COIL-20" ]
                    , Select.item [ value "COUNTRY1999" ] [ text "Country Indicators 1999" ]
                    , Select.item [ value "COUNTRY2013" ] [ text "Country Indicators 2013" ]
                    , Select.item [ value "COUNTRY2014" ] [ text "Country Indicators 2014" ]
                    , Select.item [ value "COUNTRY2015" ] [ text "Country Indicators 2015" ]
                    , Select.item [ value "WIKI-FR-1K" ] [ text "Top 1000 words in Wiki-French" ]
                    , Select.item [ value "WIKI-FR-3K" ] [ text "Top 3000 words in Wiki-French" ]
                    , Select.item [ value "WIKI-EN-1K" ] [ text "Top 1000 words in Wiki-English" ]
                    , Select.item [ value "WIKI-EN-3K" ] [ text "Top 3000 words in Wiki-English" ]
                    ]
                ]
            , Grid.col [] [ text model.debugMsg ]
            ]
        , Grid.row [{- A serie of buttons -}]
            [ Grid.col []
                [ Button.button
                    [ secondary, Button.attrs [ class "ml-4" ], onClick LoadDataset ]
                    [ text "Load Dataset" ]
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-4" ] ]
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
                    [ secondary, Button.attrs [ class "ml-4" ], onClick ResetData ]
                    [ text "Reset Data" ]
                , Button.button
                    [ secondary, Button.attrs [ class "ml-4" ], onClick Msgs.SendMovedPoints ]
                    [ text "Send Moved Points" ]
                ]
            ]
        , Grid.row [{- debug message and slider for param controlling -}]
            [ Grid.col []
                [ Html.label [ class "ml-4" ]
                    [ text "Zoom factor:"
                    , input
                        [ HtmlAttrs.type_ "range"
                        , HtmlAttrs.value (toString model.zoomFactor)
                        , HtmlAttrs.min "0.1"
                        , HtmlAttrs.max "200"
                        , HtmlEvents.onInput UpdateZoomFactor
                        ]
                        []
                    , text (toString model.zoomFactor)
                    ]
                , Html.label [ class "ml-4" ]
                    [ text "Group moving:"
                    , input
                        [ HtmlAttrs.type_ "range"
                        , HtmlAttrs.value (toString model.cf.selectionRadius)
                        , HtmlAttrs.min "0"
                        , HtmlAttrs.max "30"
                        , HtmlEvents.onInput UpdateGroupMoving
                        ]
                        []
                    , text (toString model.cf.selectionRadius)
                    ]
                ]
            , Grid.col []
                [ Html.label [ class "ml-4" ]
                    [ input
                        [ HtmlAttrs.type_ "checkbox"
                        , HtmlAttrs.checked model.cf.showLabel
                        , HtmlEvents.onClick ToggleLabel
                        ]
                        []
                    , text "Toggle labels"
                    ]
                , Html.label [ class "ml-4" ]
                    [ input
                        [ HtmlAttrs.type_ "checkbox"
                        , HtmlAttrs.checked model.cf.showColor
                        , HtmlEvents.onClick ToggleColor
                        ]
                        []
                    , text "Toggle colors"
                    ]
                , Html.label [ class "ml-4" ]
                    [ input
                        [ HtmlAttrs.type_ "checkbox"
                        , HtmlAttrs.checked model.cf.autoZoom
                        , HtmlEvents.onClick ToggleAutoZoom
                        ]
                        []
                    , text "Toggle AutoZoom"
                    ]
                ]
            ]
        , Grid.row [{- main content: scatter plot and detail view for selected and moved point -}]
            [ Grid.col [] [ scatterView model.scatter model.cf ]
            , Grid.col []
                [ --Grid.row [] [ Grid.col [] [ selectedPointsView model.scatter ] ]
                  Grid.row [] [ Grid.col [] [ movedPointsView model.scatter ] ]
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
