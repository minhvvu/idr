module Plot.Circle exposing (..)

import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Draggable
import Html exposing (Html, div, text)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseUp)
import Svg.Lazy exposing (lazy)
import Msgs exposing (Msg(..))
import Common exposing (..)


{-| Circle in scatter plot
-}
type alias Circle =
    { id : CircleId
    , position : Vec2
    , class : String
    , color : String
    , clicked : Bool
    }


{-| Move a circle to a new position
-}
moveCircle : Draggable.Delta -> Circle -> Circle
moveCircle delta circle =
    let
        tempPos =
            circle.position |> Vector2.add (Vector2.fromTuple delta)

        newPos =
            correctPosition tempPos
    in
        { circle
            | position = newPos
        }


{-| Click to select a circle
-}
toggleClicked : Circle -> Circle
toggleClicked circle =
    { circle | clicked = not circle.clicked }


{-| Util function to create a circle
-}
createCircle : Point -> Circle
createCircle point =
    Circle
        point.id
        (Vector2.vec2 point.x point.y)
        ""
        ""
        False


{-| Util function to draw a circle
-}
circleView : Circle -> Svg Msg
circleView { id, position, clicked } =
    let
        color =
            if clicked then
                "red"
            else
                "lightblue"
    in
        Svg.circle
            [ cx (toString (getX position))
            , cy (toString (getY position))
            , r "5"
            , fill color
            , Draggable.mouseTrigger id DragMsg
            , onMouseUp StopDragging
            ]
            []


{-| Public API for drawing a indexed-svg circle (index by key)
-}
circleKeyedView : Circle -> ( CircleId, Svg Msg )
circleKeyedView circle =
    ( circle.id, lazy circleView circle )


{-| Public API for print the info of a circle
-}
circleTextView : Circle -> Html Msg
circleTextView { id, position } =
    div []
        [ Html.text
            ((toString id)
                ++ ": (x = "
                ++ (toString <| getX <| position)
                ++ "; y = "
                ++ (toString <| getY <| position)
                ++ ")"
            )
        ]


{-| Public API to get basic info of a circle and make a Point record
-}
circleToPoint : Circle -> Point
circleToPoint c =
    Point c.id (getX c.position) (getY c.position)


{-| Public API for correcting the position of a circle
-}
correctPosition : Vec2 -> Vec2
correctPosition pos =
    pos



--let
--    correctedX =
--        Basics.min plotConfig.width <| Basics.max 0 <| getX pos
--    correctedY =
--        Basics.min plotConfig.height <| Basics.max 0 <| getY pos
--in
--    Vector2.vec2 correctedX correctedY
