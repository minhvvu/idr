module Plot.Scatter exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlAttrs exposing (class)
import Svg exposing (..)
import Svg.Attributes as SvgAttrs exposing (..)
import Svg.Events as SvgEvents exposing (onClick)
import Visualization.Scale as Scale exposing (ContinuousScale)
import Draggable
import Msgs exposing (..)
import Common exposing (..)
import Plot.Circle exposing (..)
import Plot.CircleGroup exposing (..)
import Plot.Axes exposing (..)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Array exposing (..)
import VirtualDom
import Json.Decode as Decode
import Strategy exposing (FixedPoint)


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
    , selectedId = ""
    }


{-| Util function to create scatter model from list of raw points
-}
createScatter : List Point -> Float -> PlotConfig -> Scatter
createScatter rawPoints zoomFactor cf =
    let
        ( minX, maxX ) =
            ( Common.minField .x rawPoints, Common.maxField .x rawPoints )

        ( minY, maxY ) =
            ( Common.minField .y rawPoints, Common.maxField .y rawPoints )

        ( minZ, maxZ ) =
            ( Common.minField .z rawPoints, Common.maxField .z rawPoints )

        autoZoomFactor =
            [ abs minX, abs maxX, abs minY, abs maxY ]
                |> List.maximum
                |> Maybe.withDefault cf.zoomFactor

        zoomFactorXY =
            if cf.autoZoom then
                autoZoomFactor
            else
                cf.zoomFactor

        xScale =
            Scale.linear
                ( -zoomFactorXY, zoomFactorXY )
                ( 0, cf.width - 2 * cf.padding )

        yScale =
            Scale.linear
                ( -zoomFactorXY, zoomFactorXY )
                ( cf.height - 2 * cf.padding, 0 )

        zScale =
            Scale.linear
                ( minZ, maxZ )
                ( cf.minCircleRadius, cf.maxCircleRadius )

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
                            p.text
                            p.fixed
                        )
                    )
    in
        { xScale = xScale
        , yScale = yScale
        , zScale = zScale
        , points = Plot.CircleGroup.createCircleGroup mappedPoints
        , selectedId = ""
        }


{-| Public API for plot the scatter
-- Zooming and Panning: <https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm>
-}
scatterView : Scatter -> PlotConfig -> Svg Msg
scatterView { points, xScale, yScale } cf =
    let
        ( cx, cy ) =
            ( getX cf.center, getY cf.center )

        panning =
            "translate(" ++ toString -cx ++ ", " ++ toString -cy ++ ")"
    in
        svg
            [ SvgAttrs.width <| toString <| plotConfig.width
            , SvgAttrs.height <| toString <| plotConfig.height
            , handleZoom Msgs.Zoom
            , Draggable.mouseTrigger "" DragMsg
            ]
            [ drawAxes ( xScale, yScale )
            , Svg.g
                [ SvgAttrs.transform (panning) ]
                [ drawScatter points cf ]
            ]


handleZoom : (Float -> msg) -> Svg.Attribute msg
handleZoom onZoom =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
        VirtualDom.onWithOptions
            "wheel"
            ignoreDefaults
            (Decode.map onZoom <| Decode.field "deltaY" Decode.float)


num : (String -> Svg.Attribute msg) -> number -> Svg.Attribute msg
num attr value =
    attr (toString value)


{-| Private function take plot the circles by calling the util function from `CircleGroup`
-}
drawScatter : CircleGroup -> PlotConfig -> Svg Msg
drawScatter points cf =
    let
        padding =
            toString cf.padding
    in
        g [ SvgAttrs.transform ("translate(" ++ padding ++ ", " ++ padding ++ ")") ]
            [ Plot.CircleGroup.circleGroupView points cf ]


{-| Public API for getting a list of moved circles and map them to the domain value
-}
getMovedPoints { points, xScale, yScale } =
    let
        movedPoint =
            Plot.CircleGroup.getMovedPoints points

        invertDomain =
            (\p ->
                { id = p.id
                , displayX = p.x
                , displayY = p.y
                , x = Scale.invert xScale p.x
                , y = Scale.invert yScale p.y
                }
            )
    in
        List.map invertDomain movedPoint


updateSelectedCircle : CircleId -> Array (List CircleId) -> Scatter -> Scatter
updateSelectedCircle circleId allNeighbors scatter =
    let
        neighbors =
            circleId
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.withDefault -1
                |> flip Array.get allNeighbors
                |> Maybe.withDefault []
    in
        { scatter
            | selectedId = circleId
            , points =
                scatter.points
                    |> Plot.CircleGroup.updateSelectedCircle circleId neighbors
        }


updateImportantPoints : List String -> Scatter -> Scatter
updateImportantPoints importantPoints scatter =
    { scatter | points = Plot.CircleGroup.updateImportantPoint importantPoints scatter.points }


{-| Public API for setting position of some fixed points
-}
updateFixedPoints : List FixedPoint -> Scatter -> Scatter
updateFixedPoints fixedPoints ({ points, xScale, yScale } as scatter) =
    let
        fixedPointsWithPos =
            fixedPoints
                |> List.map
                    (\p ->
                        { id = p.id
                        , x = p.x
                        , y = p.y
                        , displayX = Scale.convert xScale p.x
                        , displayY = Scale.convert yScale p.y
                        }
                    )
    in
        { scatter | points = Plot.CircleGroup.updateFixedPoints fixedPointsWithPos scatter.points }
