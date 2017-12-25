module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Models exposing (Model, Point)
import Msgs exposing (Msg)


view : Model -> Html Msg
view model =
    div []
        [ div [] (List.map viewPoint model.points)
        , button [ onClick Msgs.RequestData ] [ Html.text "Request Data" ]
        , scatterPlot model
        ]


viewPoint : Point -> Html Msg
viewPoint { id, x, y } =
    div []
        [ Html.text ("id: " ++ toString id ++ ", x: " ++ toString x ++ ", y: " ++ toString y)
        ]


scatterPlot : Model -> Svg Msg
scatterPlot model =
    svg
        [ width <| px <| plotWidth
        , height <| px <| plotHeight
        ]
        (List.map circle model.points)


px : Float -> String
px i =
    (toString i) ++ "px"


plotWidth : Float
plotWidth =
    900


plotHeight : Float
plotHeight =
    450


padding : Float
padding =
    30


xScale : ContinuousScale
xScale =
    Scale.linear ( -5, 5 ) ( 0, plotWidth - 2 * padding )


yScale : ContinuousScale
yScale =
    Scale.linear ( -5, 5 ) ( plotHeight - 2 * padding, 0 )


xAxis : Svg msg
xAxis =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = 5 } xScale


yAxis : Svg msg
yAxis =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 5 } yScale


circle point =
    g []
        [ Svg.circle
            [ cx <| toString <| Scale.convert xScale point.x
            , cy <| toString <| Scale.convert yScale point.y
            , r "3px"
            ]
            []
        ]
