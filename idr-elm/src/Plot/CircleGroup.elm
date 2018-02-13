module Plot.CircleGroup exposing (..)

import Draggable exposing (Delta)
import Msgs exposing (Msg(..))
import Html exposing (Html, div)
import Svg exposing (..)
import Svg.Keyed
import Plot.Circle exposing (..)
import Common exposing (..)
import Array exposing (..)


type alias CircleGroup =
    { knn : Array (List Int)
    , movingCircles : List Circle
    , idleCircles : List Circle
    , movedCircles : List Circle
    }


{-| Util function to build an empty circleGroup
-}
emptyGroup : CircleGroup
emptyGroup =
    CircleGroup Array.empty [] [] []


{-| Util function to get all circle in a group
-- Maybe BUG here: we have 3 groups, but how to get a list of all "unique" circles?
-- Observed BUG: when drag a (t+1) point, the (t) point disappears.
-- NOTE: the order of points in the final list: the recently interacted is on top
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
createCircleGroup : List Point -> Array (List Int) -> CircleGroup
createCircleGroup points knnData =
    let
        initGroup =
            { emptyGroup | knn = knnData }
    in
        points |> List.foldl addCircle initGroup


{-| Workaround to fix the strange bug (BUG 1):

  - A normal flow message: [StartDragging -> (OnDragBy) -> StopDragging]

  - A bug: [StartDragging -> (OnDragBy)] -> [StartDragging ...]

  - Nomarlly, system fires `DragMsg Msg DragAt` and our program triggers `OnDragBy`,
    the same for (`DragMsg Msg StopDragging`, `StopDragging`).
    But a strange flow can happens:
    sys: DragMsg Msg DragAt
    sys: DragMsg Msg StopDragging
    app: OnDragBy
    app: NO StopDragging <- BUG here
      - A `theorical` solution is adding e.preventDefault() for the event listening func,
        but in ELM, I found no way to do so.

      - Fix by manually check the `movingCircles`
        whenever the StartDragging is fired

-}
correctCircleGroup : CircleGroup -> CircleGroup
correctCircleGroup oldGroup =
    if List.isEmpty oldGroup.movingCircles then
        oldGroup
    else
        {- There is still a moving circle but the StopDragging is not fired
           Do exactly when having a StopDragging
        -}
        stopDragging oldGroup


{-| When start moving the circle(s), add them into moving list
-}
startDragging : CircleId -> CircleGroup -> CircleGroup
startDragging circleId oldGroup =
    let
        group =
            correctCircleGroup oldGroup

        neighbors =
            getNeighbors circleId oldGroup

        searchCond =
            \c -> List.member c.id (circleId :: neighbors)

        ( targetAsList, other ) =
            List.partition searchCond group.idleCircles
    in
        { group
            | idleCircles = other
            , movingCircles = targetAsList
        }


{-| When stop dragging the circles, the `movingCircles` is empty
-}
stopDragging : CircleGroup -> CircleGroup
stopDragging group =
    let
        allCircles =
            getAll group

        movedCircles =
            addMovedCircleFrom group.movingCircles group.movedCircles

        movingCircles =
            []
    in
        { group
            | idleCircles = allCircles
            , movedCircles = movedCircles
            , movingCircles = movingCircles
        }


{-| Drag the moving circles by applying `moveCircle` to each circle
-}
dragActiveBy : Delta -> CircleGroup -> CircleGroup
dragActiveBy delta group =
    { group
        | movingCircles = group.movingCircles |> List.map (moveCircle delta)
    }


{-| Util function to update a list of moved circles
-}
addMovedCircleFrom : List Circle -> List Circle -> List Circle
addMovedCircleFrom movingCircles movedCircles =
    case List.head movingCircles of
        Maybe.Nothing ->
            movedCircles

        Maybe.Just circle ->
            let
                searchCond =
                    \c -> c.id == circle.id

                ( duplicatedMovedPoints, otherMovedPoints ) =
                    List.partition searchCond movedCircles
            in
                circle :: otherMovedPoints


{-| Public API for rendering the circles in group
-}
circleGroupView : CircleGroup -> Svg Msg
circleGroupView group =
    group
        |> getAll
        |> List.map circleKeyedView
        |> Svg.Keyed.node "g" []


{-| Public API to get a list of moved circles and convert them to List Point
-}
getMovedPoints : CircleGroup -> List Point
getMovedPoints group =
    group
        |> correctCircleGroup
        |> .movedCircles
        |> List.map Plot.Circle.circleToPoint


getNeighbors : CircleId -> CircleGroup -> List String
getNeighbors circleId group =
    String.toInt circleId
        |> Result.withDefault 0
        |> flip Array.get group.knn
        |> Maybe.withDefault []
        |> List.map toString
