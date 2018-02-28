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
        , Grid.row [{- A serie of buttons -}]
            [ Grid.col []
                [ Select.select
                    [ Select.id "dataset-name"
                    , Select.onChange SelectDataset
                    ]
                    [ Select.item [ value "" ] [ text "--Select dataset--" ]
                    , Select.item [ value "MNIST-SMALL" ] [ text "MNIST mini" ]
                    , Select.item [ value "MNIST" ] [ text "MNIST full sample 3000" ]
                    , Select.item [ value "COIL20" ] [ text "COIL-20" ]
                    , Select.item [ value "COUNTRY2014" ] [ text "Country Indicators 2014" ]
                    , Select.item [ value "COUNTRY2015" ] [ text "Country Indicators 2015" ]
                    , Select.item [ value "WIKI-FR" ] [ text "Top 3k Wiki French" ]
                    , Select.item [ value "WIKI-EN" ] [ text "Top 3K Wiki English" ]
                    ]
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-1" ] ]
                    [ ButtonGroup.button
                        [ secondary, onClick LoadDataset ]
                        [ text "Load Dataset" ]
                    , ButtonGroup.button
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
                    , HtmlAttrs.min "0.1"
                    , HtmlAttrs.max "200"
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
