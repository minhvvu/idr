module Plot.Circle exposing (..)

import Math.Vector2 as Vector2 exposing (Vec2, getX, getY, distanceSquared)
import Draggable
import Html exposing (Html, div, text)
import Html.Attributes as HtmlAttr exposing (..)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseUp)
import Svg.Lazy exposing (lazy2)
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
    , text : String
    , status : Int
    }


{-| Util function to create a circle
-}
createCircle : Point -> Circle
createCircle point =
    let
        status =
            if point.fixed then
                Bitwise.or sIDLE sFIXED
            else
                sIDLE
    in
        Circle
            point.id
            (Vector2.vec2 point.x point.y)
            point.z
            point.label
            point.text
            status


{-| Public API to get basic info of a circle and make a Point record
-}
circleToPoint : Circle -> Point
circleToPoint c =
    Point c.id (getX c.position) (getY c.position) c.radius c.label c.text (isFixed c.status)


{-| Move a circle to a new position
-}
moveCircle : Vec2 -> Circle -> Circle
moveCircle delta circle =
    { circle
        | position = Vector2.add delta circle.position
    }


{-| Click to select a circle
-}
toggleSelected : CircleId -> Circle -> Circle
toggleSelected circleId ({ id, status } as circle) =
    { circle
        | status =
            if circleId == id then
                setSelected status
            else
                unsetSelected status
    }


{-| Toggle `sNEIGHBOR_HIGH` status of a point if its id in `neighbors`
-}
toggleNeighborHigh : List String -> Circle -> Circle
toggleNeighborHigh neighbors ({ id, status } as circle) =
    { circle
        | status =
            if List.member id neighbors then
                setNeighborHigh status
            else
                unsetNeighborHigh status
    }


{-| Toggle `sHIGHLIGHT` status of a point when user searches by label
-}
toggleHighlight : String -> Circle -> Circle
toggleHighlight lowerQuery ({ status, text } as circle) =
    { circle
        | status =
            if
                not (String.isEmpty lowerQuery)
                    && (String.contains lowerQuery (String.toLower text))
            then
                setHighligh status
            else
                unsetHighlight status
    }


{-| Set status of a point in a list of important points
-}
makeImportant : List String -> Circle -> Circle
makeImportant importantPoints ({ id, status } as circle) =
    { circle
        | status =
            if List.member id importantPoints then
                setImportant status
            else
                status
    }


{-| Util function to draw a circle
-}
circleView : Circle -> PlotConfig -> Svg Msg
circleView { id, position, radius, label, text, status } cf =
    let
        deco =
            { alpha = 0.6
            , sColor = "white"
            , sWidth = 0
            , labelSize = "10px"
            }
                |> decoIdle (isIdle status)
                |> decoSelected (isSelected status)
                |> decoImportant (isImportant status)
                |> decoFixed (isFixed status)
                |> decoNeighborHigh (isNeighborHigh status)
                |> decoHighlight (isHighlight status)

        color =
            if not cf.showColor && not (isImportant status) then
                "rgba(0, 0, 0, 0.2)"
            else
                Common.labelToColorStr label deco.alpha

        textColor =
            if (isSelected status) then
                "red"
            else
                Common.labelToColorStr label 0.8

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
                , fill textColor
                , fontSize deco.labelSize
                ]
                [ Html.text text ]

        fgCircle =
            Svg.circle
                ([ cx (centerX 0)
                 , cy (centerY 0)
                 , r (toString circleRadius)
                 , fill color
                 , stroke strokeColor
                 , strokeWidth myStrokeWidth

                 --, Svg.Attributes.cursor "move"
                 --, Draggable.mouseTrigger id DragMsg
                 --, Svg.Events.onMouseUp StopDragging
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

                --, Svg.Attributes.cursor "move"
                --, Draggable.mouseTrigger id DragMsg
                --, Svg.Events.onMouseUp StopDragging
                ]
                []

        displayCircle =
            if cf.showImage then
                imageElem
            else
                fgCircle
    in
        Svg.g
            [ Svg.Attributes.cursor "move"
            , Draggable.mouseTrigger id DragMsg
            , Svg.Events.onMouseUp StopDragging
            ]
            (if isJustIdle status && not cf.showLabel then
                [ displayCircle ]
             else
                [ lblText, displayCircle ]
            )


{-| Public API for drawing a indexed-svg circle (index by key)
-}
circleKeyedView : PlotConfig -> Circle -> ( CircleId, Svg Msg )
circleKeyedView cf circle =
    ( circle.id, lazy2 circleView circle cf )


{-| Calculate the squared distance between the centers of 2 circles
-}
distance : Circle -> Circle -> Float
distance c1 c2 =
    Vector2.distanceSquared c1.position c2.position


{-| Decoration for circle
-}
type alias Deco =
    { alpha : Float, sColor : String, sWidth : Float, labelSize : String }


decoIdle : Bool -> Deco -> Deco
decoIdle flag deco =
    deco


decoSelected : Bool -> Deco -> Deco
decoSelected flag deco =
    if flag then
        { deco
            | alpha = 1
            , sColor = "rgba(255, 0, 0, 1)"
            , sWidth = 1.0
            , labelSize = "16px"
        }
    else
        deco


decoImportant : Bool -> Deco -> Deco
decoImportant flag deco =
    if flag then
        { deco | alpha = 1 }
    else
        deco


decoFixed : Bool -> Deco -> Deco
decoFixed flag deco =
    if flag then
        { deco
            | alpha = 0.6
            , sColor = "rgba(255, 0, 0, 1)"
            , sWidth = 2.0
        }
    else
        deco


decoNeighborHigh : Bool -> Deco -> Deco
decoNeighborHigh flag deco =
    if flag then
        { deco
            | alpha = 1.0
            , sColor = "rgba(255, 69, 0, 0.8)"
            , sWidth = 1.0
            , labelSize = "9px"
        }
    else
        deco


decoHighlight : Bool -> Deco -> Deco
decoHighlight flag deco =
    if flag then
        { deco
            | sColor = "rgba(88, 24, 69, 1.0)"
            , sWidth = 2.5
            , labelSize = "12px"
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


sHIGHLIGHT =
    32


isIdle status =
    (Bitwise.and status sIDLE) > 0


isJustIdle status =
    (Bitwise.or status sIDLE) == sIDLE


isSelected status =
    (Bitwise.and status sSELECTED) > 0


isImportant status =
    (Bitwise.and status sIMPORTANT) > 0


isFixed status =
    (Bitwise.and status sFIXED) > 0


isNeighborHigh status =
    (Bitwise.and status sNEIGHBOR_HIGH) > 0


isHighlight status =
    (Bitwise.and status sHIGHLIGHT) > 0


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


setHighligh status =
    Bitwise.or status sHIGHLIGHT


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


unsetHighlight status =
    if (isHighlight status) then
        Bitwise.xor status sHIGHLIGHT
    else
        status
