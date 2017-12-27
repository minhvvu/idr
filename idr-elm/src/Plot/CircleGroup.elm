module Plot.CircleGroup exposing (..)

import Draggable exposing (Delta)
import Msgs exposing (Msg(..))
import Svg exposing (..)
import Svg.Keyed
import Plot.Circle exposing (..)
import Common exposing (..)


type alias CircleGroup =
    { movingCircles : List Circle
    , idleCircles : List Circle
    }


{-| Util function to build an empty circleGroup
-}
emptyGroup : CircleGroup
emptyGroup =
    CircleGroup [] []


{-| Util function to get all circle in a group
-}
getAll : CircleGroup -> List Circle
getAll group =
    group.idleCircles ++ group.movingCircles


{-| Add a circle into group
-}
addCircle : Point -> CircleGroup -> CircleGroup
addCircle point group =
    let
        newCircle =
            createCircle point
    in
        { group | idleCircles = newCircle :: group.idleCircles }


{-| Util function to create a group of circle
-}
createCircleGroup : List Point -> CircleGroup
createCircleGroup points =
    points |> List.foldl addCircle emptyGroup


{-| When start moving the circle(s), add them into moving list
-}
startDragging : CircleId -> CircleGroup -> CircleGroup
startDragging circleId group =
    let
        searchCond =
            \c -> c.id == circleId

        ( targetAsList, other ) =
            List.partition searchCond group.idleCircles

        target =
            case List.head targetAsList of
                Maybe.Nothing ->
                    []

                Maybe.Just a ->
                    List.singleton a
    in
        { group
            | idleCircles = other
            , movingCircles = target
        }


{-| When stop dragging the circles, the `movingCircles` is empty
-}
stopDragging : CircleGroup -> CircleGroup
stopDragging group =
    { group
        | idleCircles = getAll group
        , movingCircles = []
    }


{-| Drag the moving circles by applying `moveCircle` to each circle
-}
dragActiveBy : Delta -> CircleGroup -> CircleGroup
dragActiveBy delta group =
    { group
        | movingCircles = group.movingCircles |> List.map (moveCircle delta)
    }


circleGroupView : CircleGroup -> Svg Msg
circleGroupView group =
    group
        |> getAll
        |> List.reverse
        |> List.map circleKeyedView
        |> Svg.Keyed.node "g" []
