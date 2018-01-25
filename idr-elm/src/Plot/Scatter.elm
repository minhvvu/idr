module Plot.Scatter
    exposing
        ( Scatter
        , scatterView
        , emptyScatter
        , createScatter
        , movedPointsView
        , getMovedPoints
        )

import Html exposing (Html)
import Html.Attributes as HtmlAttrs exposing (class)
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Draggable
import Msgs exposing (Msg)
import Common exposing (PlotConfig, plotConfig, Point, minX, minY, maxX, maxY)
import Plot.Circle exposing (..)
import Plot.CircleGroup exposing (..)
import Plot.Axes exposing (..)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)


{-| Scatter Model contains data used for rendering a scatter plot
-}
type alias Scatter =
    { points : CircleGroup
    , xScale : ContinuousScale
    , yScale : ContinuousScale
    }


emptyScatter : Scatter
emptyScatter =
    { points = emptyGroup
    , xScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    , yScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    }


{-| Util function to create scatter model from list of raw points
-}
createScatter : List Point -> Scatter
createScatter rawPoints =
    let
        xScale =
            Scale.linear
                ( -plotConfig.clientScale, plotConfig.clientScale )
                -- ( Common.minX rawPoints, Common.maxX rawPoints )
                ( 0, plotConfig.width - 2 * plotConfig.padding )

        yScale =
            Scale.linear
                ( -plotConfig.clientScale, plotConfig.clientScale )
                -- ( Common.minY rawPoints, Common.maxY rawPoints )
                ( plotConfig.height - 2 * plotConfig.padding, 0 )
    in
        { xScale = xScale
        , yScale = yScale
        , points = mapRawDataToScatterPlot rawPoints ( xScale, yScale )
        }


{-| Private function to create a list of plotted points from the raw data
-}
mapRawDataToScatterPlot : List Point -> ( ContinuousScale, ContinuousScale ) -> CircleGroup
mapRawDataToScatterPlot rawPoints ( xScale, yScale ) =
    let
        mappedPoints =
            rawPoints
                |> List.map
                    (\p ->
                        (Point
                            p.id
                            (Scale.convert xScale p.x)
                            (Scale.convert yScale p.y)
                            p.label
                            p.fixed
                        )
                    )
    in
        createCircleGroup mappedPoints


{-| Public API for plot the scatter
-}
scatterView : Scatter -> Svg Msg
scatterView { points, xScale, yScale } =
    svg
        [ width <| px <| plotConfig.width
        , height <| px <| plotConfig.height
        ]
        [ drawAxes ( xScale, yScale )
        , drawScatter points
        ]


{-| Private function take plot the circles by calling the util function from `CircleGroup`
-}
drawScatter : CircleGroup -> Svg Msg
drawScatter points =
    let
        padding =
            toString plotConfig.padding
    in
        g [ transform ("translate(" ++ padding ++ ", " ++ padding ++ ")") ]
            [ circleGroupView points ]


px : Float -> String
px i =
    (toString i) ++ "px"


{-| Public API for calling drawing a list of moved circle in CircleGroup
-}
movedPointsView : Scatter -> Html Msg
movedPointsView { points } =
    ListGroup.ul
        (points.movedCircles
            |> List.map
                (\p ->
                    ListGroup.li
                        [ ListGroup.attrs [ HtmlAttrs.class "justify-content-between" ] ]
                        [ Badge.pill [] [ Html.text p.id ]
                        , Html.text
                            ("[label:"
                                ++ p.label
                                ++ "], (x = "
                                ++ (toString <| round <| getX <| p.position)
                                ++ "; y = "
                                ++ (toString <| round <| getY <| p.position)
                                ++ ")"
                            )
                        ]
                )
        )


{-| Public API for getting a list of moved circles and map them to the domain value
-}
getMovedPoints : Scatter -> List Point
getMovedPoints { points, xScale, yScale } =
    let
        movedPoint =
            Plot.CircleGroup.getMovedPoints points

        invertDomain =
            (\p ->
                (Point
                    p.id
                    (Scale.invert xScale p.x)
                    (Scale.invert yScale p.y)
                    p.label
                    p.fixed
                )
            )
    in
        List.map invertDomain movedPoint
