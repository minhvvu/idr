module Plot.Scatter exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlAttrs exposing (class)
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Svg exposing (..)
import Svg.Attributes as SvgAttrs exposing (width, height)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Draggable
import Msgs exposing (Msg)
import Common exposing (..)
import Plot.Circle exposing (..)
import Plot.CircleGroup exposing (..)
import Plot.Axes exposing (..)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Array exposing (..)


{-| Scatter Model contains data used for rendering a scatter plot
-}
type alias Scatter =
    { points : CircleGroup
    , xScale : ContinuousScale
    , yScale : ContinuousScale
    , zScale : ContinuousScale
    , selectedId : String
    }


emptyScatter : Scatter
emptyScatter =
    { points = emptyGroup
    , xScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    , yScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    , zScale = Scale.linear ( 0, 0 ) ( 0, 0 )
    , selectedId = "0"
    }


{-| Util function to create scatter model from list of raw points
-}
createScatter : List Point -> Float -> Scatter
createScatter rawPoints zoomFactor =
    let
        ( minX, maxX ) =
            ( Common.minField .x rawPoints, Common.maxField .x rawPoints )

        ( minY, maxY ) =
            ( Common.minField .y rawPoints, Common.maxField .y rawPoints )

        ( minZ, maxZ ) =
            ( Common.minField .z rawPoints, Common.maxField .z rawPoints )

        autoZoomFactor =
            [ zoomFactor, abs minX, abs maxX, abs minY, abs maxY ]
                |> List.maximum
                |> Maybe.withDefault zoomFactor

        zoomFactorXY =
            if plotConfig.autoZoom then
                autoZoomFactor
            else
                zoomFactor

        xScale =
            Scale.linear
                ( -zoomFactorXY, zoomFactorXY )
                ( 0, plotConfig.width - 2 * plotConfig.padding )

        yScale =
            Scale.linear
                ( -zoomFactorXY, zoomFactorXY )
                ( plotConfig.height - 2 * plotConfig.padding, 0 )

        zScale =
            Scale.linear
                ( minZ, maxZ )
                ( plotConfig.minCircleRadius, plotConfig.maxCircleRadius )

        mappedPoints =
            rawPoints
                |> List.map
                    (\p ->
                        (Point
                            p.id
                            (Scale.convert xScale p.x)
                            (Scale.convert yScale p.y)
                            (Scale.convert zScale p.z)
                            p.label
                            p.fixed
                        )
                    )
    in
        { xScale = xScale
        , yScale = yScale
        , zScale = zScale
        , points = createCircleGroup mappedPoints
        , selectedId = "0"
        }


{-| Public API for plot the scatter
-}
scatterView : Scatter -> Svg Msg
scatterView { points, xScale, yScale } =
    svg
        [ SvgAttrs.width <| toString <| plotConfig.width
        , SvgAttrs.height <| toString <| plotConfig.height
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
        g [ SvgAttrs.transform ("translate(" ++ padding ++ ", " ++ padding ++ ")") ]
            [ Plot.CircleGroup.circleGroupView points ]


{-| Public API for calling drawing a list of moved circle in CircleGroup
-}
movedPointsView : Scatter -> Html Msg
movedPointsView { points } =
    let
        pointToListItem =
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
    in
        ListGroup.ul
            (points.movedCircles
                |> List.map pointToListItem
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
                    p.z
                    p.label
                    p.fixed
                )
            )
    in
        List.map invertDomain movedPoint


updateSelectedCircle : CircleId -> Scatter -> Scatter
updateSelectedCircle circleId scatter =
    { scatter
        | selectedId = circleId
        , points = Plot.CircleGroup.updateSelectedCircle circleId scatter.points
    }


selectedPointsView : Scatter -> Html Msg
selectedPointsView { points, selectedId } =
    let
        neighbors =
            Plot.CircleGroup.getKNN selectedId points
    in
        Html.div []
            [ Html.text ("Selected Id: " ++ selectedId)
            , Html.br [] []
            , Html.text
                (if List.isEmpty neighbors then
                    "No neighbors"
                 else
                    (toString (List.length neighbors)
                        ++ " neighbors: "
                        ++ (toString neighbors)
                    )
                )
            ]
