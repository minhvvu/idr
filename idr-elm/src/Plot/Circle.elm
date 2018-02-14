module Plot.Circle exposing (..)

import Math.Vector2 as Vector2 exposing (Vec2, getX, getY, distanceSquared)
import Draggable
import Html exposing (Html, div, text)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseUp)
import Svg.Lazy exposing (lazy)
import Msgs exposing (Msg(..))
import Common exposing (..)


type CircleStatus
    = Idle
    | Selected
    | Moved


{-| Circle in scatter plot
-}
type alias Circle =
    { id : CircleId
    , position : Vec2
    , radius : Float
    , label : String
    , status : CircleStatus
    , fixed : Bool
    }


{-| Util function to create a circle
-}
createCircle : Point -> Circle
createCircle point =
    Circle
        point.id
        (Vector2.vec2 point.x point.y)
        point.z
        point.label
        Idle
        point.fixed


{-| Public API to get basic info of a circle and make a Point record
-}
circleToPoint : Circle -> Point
circleToPoint c =
    Point c.id (getX c.position) (getY c.position) c.radius c.label c.fixed


{-| Move a circle to a new position
-}
moveCircle : Draggable.Delta -> Circle -> Circle
moveCircle delta circle =
    let
        newPos =
            circle.position |> Vector2.add (Vector2.fromTuple delta)
    in
        { circle
            | position = newPos
        }


{-| Click to select a circle
-}
toggleSelected : CircleId -> Circle -> Circle
toggleSelected circleId circle =
    { circle
        | status =
            if circleId == circle.id then
                Selected
            else
                Idle
    }


{-| Util function to draw a circle
-}
circleView : Circle -> Svg Msg
circleView { id, position, radius, label, status, fixed } =
    let
        alphaFactor =
            if status == Selected then
                1.0
            else
                0.6

        color =
            Common.labelToColorStr label alphaFactor

        strokeColor =
            if status == Selected then
                plotConfig.selectedStrokeColor
            else if fixed then
                "red"
            else
                plotConfig.defaultStrokeColor

        circleRadius =
            if plotConfig.fixedRadius then
                plotConfig.circleRadius
            else
                radius

        centerX =
            position |> getX |> round |> toString

        centerY =
            position |> getY |> round |> toString

        fgCircle =
            Svg.circle
                ([ cx centerX
                 , cy centerY
                 , r (toString circleRadius)
                 , fill color
                 , stroke strokeColor
                 , strokeWidth (toString plotConfig.strokeWidth)
                 , Svg.Attributes.cursor "move"
                 , Draggable.mouseTrigger id DragMsg
                 , Svg.Events.onMouseUp StopDragging
                 ]
                    ++ (Draggable.touchTriggers id DragMsg)
                )
                []
    in
        Svg.g []
            (if status == Selected then
                [ Svg.circle
                    [ cx centerX
                    , cy centerY
                    , r (toString (circleRadius * 5))
                    , fill (Common.labelToColorStr label 0.15)
                    , stroke strokeColor
                    , strokeWidth (toString (2 * plotConfig.strokeWidth))
                    ]
                    []
                , fgCircle
                ]
             else
                [] ++ [ fgCircle ]
            )


{-| Public API for drawing a indexed-svg circle (index by key)
-}
circleKeyedView : Circle -> ( CircleId, Svg Msg )
circleKeyedView circle =
    ( circle.id, lazy circleView circle )


{-| Calculate the squared distance between the centers of 2 circles
-}
distance : Circle -> Circle -> Float
distance c1 c2 =
    Vector2.distanceSquared c1.position c2.position



--{-| Public API to get float value of the position of circle center
---}
--getPosition : Circle -> Float Float
--getPosition { position } =
--    ( getX position, getY position )
