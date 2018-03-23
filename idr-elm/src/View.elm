module View exposing (view)

import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (class, min, max, value, src)
import Html.Events as HtmlEvents exposing (onInput)
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col
import Bootstrap.Button as Button exposing (..)
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
import Bootstrap.Tab as Tab exposing (..)
import Bootstrap.Utilities.Size as Size exposing (..)
import Bootstrap.Utilities.Border as Border exposing (..)
import Common exposing (datasets, DatasetType)
import Dict exposing (..)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row []
            [ Grid.col [ Col.xs3 ] [ text model.debugMsg ]
            , Grid.col [ Col.xs6 ]
                [ input [ class "ml-2", HtmlAttrs.placeholder "Search by label", onInput SearchByLabel ] []

                --, slider "Group moving:" model.cf.selectionRadius ( 0, 30 ) UpdateGroupMoving
                , slider "Zoom:" model.cf.zoomFactor ( 0.1, 150 ) UpdateZoomFactor
                ]
            , Grid.col [ Col.xs3 ]
                [ checkbox "Label" model.cf.showLabel
                , checkbox "Color" model.cf.showColor
                , checkbox "Fit" model.cf.autoZoom
                , checkbox "Axes" model.cf.showAxes
                ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs3 ]
                [ Select.select
                    [ Select.small, Select.id "dataset-name", Select.onChange SelectDataset ]
                    (List.map sitem <| Dict.toList datasets)
                ]
            , Grid.col [ Col.xs6 ]
                [ button "Load Dataset" LoadDataset
                , ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-2" ] ]
                    [ groupButton "Do Embedding" DoEmbedding
                    , groupButton "Pause" PauseServer
                    , groupButton "Continue" ContinueServer
                    ]
                , button "Move Points" SendMovedPoints
                , button "Reset" ResetData
                ]
            , Grid.col [ Col.xs3 ]
                [ ButtonGroup.buttonGroup
                    [ ButtonGroup.attrs [ class "ml-2" ] ]
                    [ groupButton "Strategy1" (DoStrategy "1")
                    , groupButton "Strategy2" (DoStrategy "2")
                    , groupButton "Strategy3" (DoStrategy "3")
                    ]
                ]
            ]
        , Grid.row [{- main content: scatter plot and detail view for selected and moved point -}]
            [ Grid.col [ Col.xs7 ] [ scatterView model.scatter model.cf ]
            , Grid.col [ Col.xs5 ]
                [ div [ HtmlAttrs.style [ ( "padding-top", "10px" ) ] ]
                    [ Tab.config TabMsg
                        |> Tab.right
                        |> Tab.items
                            [ tabItem "tab1" "Charts" (List.map (\aseries -> viewLineChart aseries.name aseries.series) model.seriesData)
                            , tabItem "tab2" "Moved Points" [ movedPointsView model.scatter.points.movedCircles ]
                            , tabItem "tab3" "Selected points" [ selectedPointsView model ]
                            ]
                        |> Tab.view model.tabState
                    ]
                ]
            ]
        ]


tabItem id name items =
    Tab.item
        { id = id
        , link = Tab.link [] [ text name ]
        , pane = Tab.pane [] items
        }


checkbox : String -> Bool -> Html Msg
checkbox name value =
    Html.label [ class "ml-2" ]
        [ input
            [ HtmlAttrs.type_ "checkbox"
            , HtmlAttrs.checked value
            , HtmlEvents.onClick (ToggleConfig name)
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


sitem : ( String, ( DatasetType, String ) ) -> Select.Item msg
sitem ( keyName, ( aType, displayName ) ) =
    Select.item [ HtmlAttrs.value keyName ] [ text displayName ]


compactLayout model =
    Grid.containerFluid []
        [ CDN.stylesheet
        , Grid.row []
            [ Grid.col [ Col.xs3 ] [ text model.debugMsg ]
            , Grid.col [ Col.xs7 ]
                [ slider "Zoom:" model.cf.zoomFactor ( 0.1, 150 ) UpdateZoomFactor
                , checkbox "Labels" model.cf.showLabel
                , checkbox "Colors" model.cf.showColor
                , checkbox "Fit" model.cf.autoZoom
                , checkbox "Axes" model.cf.showAxes
                ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs3 ]
                [ Select.select
                    [ Select.small, Select.id "dataset-name", Select.onChange SelectDataset ]
                    (List.map sitem <| Dict.toList datasets)
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
