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
import Plot.Scatter exposing (scatterView)
import Plot.LineChart exposing (viewLineChart)
import Svg exposing (image)
import Svg.Attributes exposing (x, y, xlinkHref)
import DataView.PointDetail exposing (..)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row []
            [ Grid.col [ Col.xs2 ] [ text model.debugMsg ]
            , Grid.col [ Col.xs5 ]
                [ input [ class "ml-2", HtmlAttrs.placeholder "Search by label", onInput SearchByLabel ] []

                --, slider "Group moving:" model.cf.selectionRadius ( 0, 30 ) UpdateGroupMoving
                , slider "Zoom:" model.cf.zoomFactor ( 0.1, 150 ) UpdateZoomFactor
                ]
            , Grid.col [ Col.xs3 ]
                [ checkbox "Labels" model.cf.showLabel ToggleLabel
                , checkbox "Colors" model.cf.showColor ToggleColor
                , checkbox "Fit" model.cf.autoZoom ToggleAutoZoom
                ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs2 ]
                [ Select.select
                    [ Select.small, Select.id "dataset-name", Select.onChange SelectDataset ]
                    [ sitem "--Select dataset--" ""
                    , sitem "Country Indicators 1999" "COUNTRY1999"
                    , sitem "Country Indicators 2013" "COUNTRY2013"
                    , sitem "Country Indicators 2014" "COUNTRY2014"
                    , sitem "Country Indicators 2015" "COUNTRY2015"
                    , sitem "Cars and Trucks 2004" "CARS04"
                    , sitem "Breast Cancer Wisconsin (Diagnostic)" "BREAST-CANCER95"
                    , sitem "Pima Indians Diabetes" "DIABETES"
                    , sitem "Multidimensional Poverty Measures" "MPI"
                    , sitem "US Insurance Cost" "INSURANCE"
                    , sitem "Fifa 18 Players (top 2000)" "FIFA18"
                    , sitem "French salaries per town (top 2000)" "FR_SALARY"
                    , sitem "MNIST mini" "MNIST-SMALL"
                    , sitem "MNIST full (sample 2000)" "MNIST"
                    , sitem "COIL-20" "COIL20"
                    , sitem "Top 1000 words in Wiki-French" "WIKI-FR-1K"
                    , sitem "Top 3000 words in Wiki-French" "WIKI-FR-3K"
                    , sitem "Top 1000 words in Wiki-English" "WIKI-EN-1K"
                    , sitem "Top 3000 words in Wiki-English" "WIKI-EN-3K"
                    ]
                ]
            , Grid.col [ Col.xs5 ]
                [ button "Load Dataset" LoadDataset
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-2" ] ]
                    [ groupButton "Do Embedding" DoEmbedding
                    , groupButton "Pause" PauseServer
                    , groupButton "Continue" ContinueServer
                    ]
                , button "Move Points" SendMovedPoints
                ]
            , Grid.col [ Col.xs3 ]
                [ ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-2" ] ]
                    [ groupButton "Strategy1" (DoStrategy "1")
                    , groupButton "Strategy2" (DoStrategy "2")
                    , groupButton "Strategy3" (DoStrategy "3")
                    ]
                , button "Reset" ResetData
                ]
            ]
        , Grid.row [{- main content: scatter plot and detail view for selected and moved point -}]
            [ Grid.col [ Col.xs8 ] [ scatterView model.scatter model.cf ]
            , Grid.col [ Col.xs4 ]
                [ dataview "cool qua la cool"
                , Grid.row [{- line charts for measurement -}]
                    [ Grid.col []
                        (model.seriesData
                            |> List.map
                                (\aseries -> viewLineChart aseries.name aseries.series)
                        )
                    ]
                , Grid.row [] [ Grid.col [] [ movedPointsView model.scatter.points.movedCircles ] ]

                --Grid.row [] [ Grid.col [] [ selectedPointsView model.scatter ] ]
                ]
            ]
        ]


checkbox : String -> Bool -> Msg -> Html Msg
checkbox name value toggleMsg =
    Html.label [ class "ml-2" ]
        [ input
            [ HtmlAttrs.type_ "checkbox"
            , HtmlAttrs.checked value
            , HtmlEvents.onClick toggleMsg
            ]
            []
        , text name
        ]


slider : String -> Float -> ( Float, Float ) -> (String -> Msg) -> Html Msg
slider name value ( minVal, maxVal ) msgWithString =
    Html.label [ class "ml-2" ]
        [ text name
        , input
            [ HtmlAttrs.type_ "range"
            , HtmlAttrs.value (toString value)
            , HtmlAttrs.min (toString minVal)
            , HtmlAttrs.max (toString maxVal)
            , HtmlEvents.onInput msgWithString
            ]
            []
        , text (toString value)
        ]


button : String -> Msg -> Html Msg
button name clickMsg =
    Button.button [ Button.outlinePrimary, Button.small, Button.attrs [ class "ml-2" ], onClick clickMsg ]
        [ text name ]


groupButton : String -> Msg -> ButtonGroup.ButtonItem Msg
groupButton name clickMsg =
    ButtonGroup.button
        [ Button.outlineSecondary, Button.small, onClick clickMsg ]
        [ text name ]


sitem : String -> String -> Select.Item msg
sitem sname svalue =
    Select.item [ HtmlAttrs.value svalue ] [ text sname ]


compactLayout model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row []
            [ Grid.col [ Col.xs3 ] [ text model.debugMsg ]
            , Grid.col [ Col.xs7 ]
                [ slider "Zoom:" model.cf.zoomFactor ( 0.1, 150 ) UpdateZoomFactor
                , checkbox "Labels" model.cf.showLabel ToggleLabel
                , checkbox "Colors" model.cf.showColor ToggleColor
                , checkbox "Fit" model.cf.autoZoom ToggleAutoZoom
                ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs3 ]
                [ Select.select
                    [ Select.small, Select.id "dataset-name", Select.onChange SelectDataset ]
                    [ sitem "--Select dataset--" "" ]
                ]
            , Grid.col [ Col.xs7 ]
                [ button "Load Dataset" LoadDataset
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-2" ] ]
                    [ groupButton "Do Embedding" DoEmbedding
                    , groupButton "Pause" PauseServer
                    , groupButton "Continue" ContinueServer
                    ]
                , button "Move Points" SendMovedPoints
                ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs8 ] [ scatterView model.scatter model.cf ] ]
        ]
