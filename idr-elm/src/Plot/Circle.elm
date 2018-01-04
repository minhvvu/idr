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
    , label : String
    , selected : Bool
    }


{-| Util function to create a circle
-}
createCircle : Point -> Circle
createCircle point =
    Circle
        point.id
        (Vector2.vec2 point.x point.y)
        point.label
        False


{-| Public API to get basic info of a circle and make a Point record
-}
circleToPoint : Circle -> Point
circleToPoint c =
    Point c.id (getX c.position) (getY c.position) c.label


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
setSelected : Circle -> Circle
setSelected circle =
    { circle | selected = True }


{-| Util function to draw a circle
-}
circleView : Circle -> Svg Msg
circleView { id, position, label, selected } =
    let
        {- http://htmlcolorcodes.com/ -}
        color =
            Common.labelToColorStr label

        strokeColor =
            if selected then
                plotConfig.selectedStrokeColor
            else
                plotConfig.defaultStrokeColor
    in
        Svg.circle
            ([ cx (position |> getX |> round |> toString)
             , cy (position |> getY |> round |> toString)
             , r (toString plotConfig.circleRadius)
             , fill color
             , stroke strokeColor
             , strokeWidth (toString plotConfig.strokeWidth)
             , Svg.Attributes.cursor "move"
             , Draggable.mouseTrigger id DragMsg
             , Svg.Events.onMouseUp StopDragging
             ]
                ++ (Draggable.touchTriggers id DragMsg)
            )
            [ Svg.title []
                -- for tooltip
                [ Svg.text
                    ("Label: " ++ label ++ ", id: " ++ id)
                ]
            ]


{-| Public API for drawing a indexed-svg circle (index by key)
-}
circleKeyedView : Circle -> ( CircleId, Svg Msg )
circleKeyedView circle =
    ( circle.id, lazy circleView circle )


{-| Public API for print the info of a circle
-}
circleTextView : Circle -> Html Msg
circleTextView { id, position, label } =
    div []
        [ Html.text
            ("[label:"
                ++ label
                ++ "]{id:"
                ++ (toString id)
                ++ ", (x = "
                ++ (toString <| round <| getX <| position)
                ++ "; y = "
                ++ (toString <| round <| getY <| position)
                ++ ")}"
            )
        ]


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
