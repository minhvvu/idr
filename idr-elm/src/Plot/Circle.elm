module Plot.Circle exposing (..)

import Math.Vector2 as Vector2 exposing (Vec2, getX, getY, distanceSquared)
import Draggable
import Html exposing (Html, div, text)
import Html.Attributes as HtmlAttr exposing (..)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseUp)
import Svg.Lazy exposing (lazy)
import Msgs exposing (Msg(..))
import Common exposing (..)
import Bitwise exposing (and, or, xor)


{-| Circle in scatter plot
-}
type alias Circle =
    { id : CircleId
    , position : Vec2
    , radius : Float
    , label : String
    , status : Int
    }


{-| Util function to create a circle
-}
createCircle : Point -> Circle
createCircle point =
    let
        status =
            if point.fixed then
                Bitwise.and sIDLE sFIXED
            else
                sIDLE
    in
        Circle
            point.id
            (Vector2.vec2 point.x point.y)
            point.z
            point.label
            status


{-| Public API to get basic info of a circle and make a Point record
-}
circleToPoint : Circle -> Point
circleToPoint c =
    Point c.id (getX c.position) (getY c.position) c.radius c.label (isFixed c.status)


{-| Move a circle to a new position
-}
moveCircle : Draggable.Delta -> Circle -> Circle
moveCircle delta circle =
    { circle
        | position = Vector2.add (Vector2.fromTuple delta) circle.position
    }


{-| Click to select a circle
-}
toggleSelected : CircleId -> Circle -> Circle
toggleSelected circleId circle =
    { circle
        | status =
            if circleId == circle.id then
                setSelected circle.status
            else
                unsetSelected circle.status
    }


makeImportant : List String -> Circle -> Circle
makeImportant importantPoints circle =
    { circle
        | status =
            if List.member circle.id importantPoints then
                setImportant circle.status
            else
                circle.status
    }


makeNeighborHigh : List String -> Circle -> Circle
makeNeighborHigh neighbors circle =
    { circle
        | status =
            if List.member circle.id neighbors then
                setNeighborHigh circle.status
            else
                unsetNeighborHigh circle.status
    }


{-| Util function to draw a circle
-}
circleView : Circle -> Svg Msg
circleView { id, position, radius, label, status } =
    let
        deco =
            { alpha = 0.2
            , sColor = "black"
            , sWidth = 0
            }
                |> decoIdle (isIdle status)
                |> decoSelected (isSelected status)
                |> decoImportant (isImportant status)
                |> decoFixed (isFixed status)
                |> decoNeighborHigh (isNeighborHigh status)

        color =
            Common.labelToColorStr label deco.alpha

        --(if (isIdle status) then
        --    "-1"
        -- else
        --    label
        --)
        --    |> flip Common.labelToColorStr deco.alpha
        strokeColor =
            deco.sColor

        myStrokeWidth =
            toString deco.sWidth

        circleRadius =
            if plotConfig.fixedRadius then
                plotConfig.circleRadius
            else
                radius

        centerX offset =
            position |> getX |> (+) offset |> round |> toString

        centerY offset =
            position |> getY |> (+) offset |> round |> toString

        lblText =
            Svg.text_
                [ x (centerX 4)
                , y (centerY -4)
                , fill "black"
                , fontSize "14px"
                ]
                [ Html.text label ]

        fgCircle =
            Svg.circle
                ([ cx (centerX 0)
                 , cy (centerY 0)
                 , r (toString circleRadius)
                 , fill color
                 , stroke strokeColor
                 , strokeWidth myStrokeWidth
                 , Svg.Attributes.cursor "move"
                 , Draggable.mouseTrigger id DragMsg
                 , Svg.Events.onMouseUp StopDragging
                 ]
                    ++ (Draggable.touchTriggers id DragMsg)
                )
                [ Svg.path [ x (centerX 0), y (centerY 0), d "M2 1 h1 v1 h1 v1 h-1 v1 h-1 v-1 h-1 v-1 h1 z" ] [{- doesnot work -}] ]

        bgCircle =
            {- not used -}
            Svg.circle
                [ cx (centerX 0)
                , cy (centerY 0)
                , r (toString plotConfig.selectionRadius)
                , fill (Common.labelToColorStr label 0.15)
                , stroke strokeColor
                , strokeWidth myStrokeWidth
                ]
                []

        imageElem =
            Svg.image
                [ x (centerX 0)
                , y (centerY 0)
                , Svg.Attributes.width "8"
                , Svg.Attributes.height "8"
                , xlinkHref ("http://localhost:8000/data/imgs/mnist-small.svg#" ++ id)
                , Svg.Attributes.cursor "move"
                , Draggable.mouseTrigger id DragMsg
                , Svg.Events.onMouseUp StopDragging
                ]
                []

        displayCircle =
            if plotConfig.showImage then
                imageElem
            else
                fgCircle
    in
        Svg.g []
            (if (isSelected status) || (isNeighborHigh status) then
                [ displayCircle
                , lblText
                ]
             else
                [ displayCircle ]
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


{-| Decoration for circle
-}
type alias Deco =
    { alpha : Float, sColor : String, sWidth : Float }


decoIdle : Bool -> Deco -> Deco
decoIdle flag deco =
    if flag then
        { deco
            | alpha = 0.2
            , sColor = "white"
            , sWidth = 0
        }
    else
        deco


decoSelected : Bool -> Deco -> Deco
decoSelected flag deco =
    if flag then
        { deco
            | alpha = 1
            , sColor = "red"
            , sWidth = 1.0
        }
    else
        deco


decoImportant : Bool -> Deco -> Deco
decoImportant flag deco =
    if flag then
        { deco
            | alpha = 0.6
            , sColor = "blue"
            , sWidth = 1.0
        }
    else
        deco


decoFixed : Bool -> Deco -> Deco
decoFixed flag deco =
    if flag then
        { deco
            | alpha = 0.8
            , sColor = "green"
            , sWidth = 1.5
        }
    else
        deco


decoNeighborHigh : Bool -> Deco -> Deco
decoNeighborHigh flag deco =
    if flag then
        { deco
            | alpha = 0.4
            , sColor = "orange"
            , sWidth = 1.0
        }
    else
        deco



{- Status of a point in scatter plot -}


sIDLE =
    1


sSELECTED =
    2


sIMPORTANT =
    4


sFIXED =
    8


sNEIGHBOR_HIGH =
    16


isIdle status =
    (Bitwise.and status sIDLE) > 0


isSelected status =
    (Bitwise.and status sSELECTED) > 0


isImportant status =
    (Bitwise.and status sIMPORTANT) > 0


isFixed status =
    (Bitwise.and status sFIXED) > 0


isNeighborHigh status =
    (Bitwise.and status sNEIGHBOR_HIGH) > 0


setIdle status =
    Bitwise.or status sIDLE


setSelected status =
    Bitwise.or status sSELECTED


setImportant status =
    Bitwise.or status sIMPORTANT


setFixed status =
    Bitwise.or status sFIXED


setNeighborHigh status =
    Bitwise.or status sNEIGHBOR_HIGH


unsetSelected status =
    if (isSelected status) then
        Bitwise.xor status sSELECTED
    else
        status


unsetNeighborHigh status =
    if (isNeighborHigh status) then
        Bitwise.xor status sNEIGHBOR_HIGH
    else
        status
