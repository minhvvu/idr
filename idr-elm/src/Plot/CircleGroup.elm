module Plot.CircleGroup exposing (..)

import Draggable exposing (Delta)
import Msgs exposing (Msg(..))
import Html exposing (Html, div)
import Svg exposing (..)
import Svg.Keyed
import Plot.Circle exposing (..)
import Common exposing (..)
import Array exposing (..)
import Math.Vector2 exposing (Vec2)
import Strategy exposing (FixedPoint)


type alias CircleGroup =
    { movingCircles : List Circle
    , idleCircles : List Circle
    , movedCircles : List Circle
    }


{-| Util function to build an empty circleGroup
-}
emptyGroup : CircleGroup
emptyGroup =
    CircleGroup [] [] []


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
createCircleGroup : List Point -> CircleGroup
createCircleGroup points =
    points |> List.foldl addCircle emptyGroup


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
Drag also the neighbors point in 2D
-}
startDragging : CircleId -> PlotConfig -> CircleGroup -> CircleGroup
startDragging circleId cf oldGroup =
    let
        group =
            correctCircleGroup oldGroup

        neighbors =
            getKNN circleId cf oldGroup

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
    { group
        | idleCircles = group.idleCircles ++ group.movingCircles
        , movedCircles = addMovedCircleFrom group.movingCircles group.movedCircles
        , movingCircles = []
    }


{-| Drag the moving circles by applying `moveCircle` to each circle
-}
dragActiveBy : Vec2 -> CircleGroup -> CircleGroup
dragActiveBy delta group =
    { group
        | movingCircles = List.map (moveCircle delta) group.movingCircles
    }


{-| Update status flag for the selected point by user
-}
updateSelectedCircle : CircleId -> List CircleId -> CircleGroup -> CircleGroup
updateSelectedCircle circleId neighbors group =
    { group
        | idleCircles =
            group.idleCircles
                |> List.map (Plot.Circle.toggleSelected circleId)
                |> List.map (Plot.Circle.toggleNeighborHigh (List.take plotConfig.nNeighbors neighbors))
    }


{-| Update status flag for highlighted points via user query
-}
updateHighlightPoint : String -> CircleGroup -> CircleGroup
updateHighlightPoint lowerQuery group =
    { group
        | idleCircles =
            group.idleCircles
                |> List.map (Plot.Circle.toggleHighlight lowerQuery)
    }


{-| Update status flag for the important points returned from server
-}
updateImportantPoint : List String -> CircleGroup -> CircleGroup
updateImportantPoint importantPoints group =
    { group | idleCircles = List.map (Plot.Circle.makeImportant importantPoints) group.idleCircles }


{-| Update fixed points from predefined strategy
-}
updateFixedPoints : List FixedPoint -> CircleGroup -> CircleGroup
updateFixedPoints fixedPoints group =
    let
        fixedIds =
            List.map (\p -> p.id) fixedPoints

        updatedIdleCircles =
            List.map (Plot.Circle.updateFixedPos fixedPoints) group.idleCircles

        updatedMovedCircles =
            List.filter (\c -> List.member c.id fixedIds) updatedIdleCircles
    in
        { group
            | idleCircles = updatedIdleCircles
            , movedCircles = updatedMovedCircles
        }


{-| Util function to update a list of moved circles
TODO FIX: we have a list of moving circles now!
-}
addMovedCircleFrom : List Circle -> List Circle -> List Circle
addMovedCircleFrom movingCircles movedCircles =
    let
        movingIds =
            List.map .id movingCircles

        ( dejaMovedPoints, otherMovedPoints ) =
            List.partition
                (\c ->
                    List.member c.id movingIds
                )
                movedCircles
    in
        movingCircles
            ++ otherMovedPoints


{-| Public API for rendering the circles in group
-}
circleGroupView : CircleGroup -> PlotConfig -> Svg Msg
circleGroupView group cf =
    let
        allCircle =
            getAll group
    in
        List.map (circleKeyedView cf) allCircle |> Svg.Keyed.node "g" []



--group
--    |> getAll
--    |> List.map circleKeyedView cf
--    |> Svg.Keyed.node "g" []


{-| Public API to get a list of moved circles and convert them to List Point
-}
getMovedPoints : CircleGroup -> List Point
getMovedPoints group =
    group
        |> correctCircleGroup
        |> .movedCircles
        |> List.map Plot.Circle.circleToPoint


{-| Util function to get a list of circles by circleIds
-}
getCircleById : List CircleId -> CircleGroup -> List Circle
getCircleById listCircleIds group =
    List.filter (\c -> List.member c.id listCircleIds) group.idleCircles


{-| Public API to get a list of k nearest neighbors of a circle
-}
getKNN : CircleId -> PlotConfig -> CircleGroup -> List CircleId
getKNN circleId cf group =
    group.idleCircles
        |> calculateDistances circleId
        |> List.filter (\p -> Tuple.first p < cf.selectionRadius * cf.selectionRadius)
        |> List.take (cf.nNeighbors + 1)
        |> List.tail
        |> Maybe.withDefault [ ( 0, circleId ) ]
        |> List.map Tuple.second


{-| Util function to calculate distances between
the selected circle and all other idle circles
-}
calculateDistances : CircleId -> List Circle -> List ( Float, CircleId )
calculateDistances circleId listCircles =
    let
        foundCircle =
            listCircles
                |> List.filter (\c -> c.id == circleId)
                |> List.head
    in
        case foundCircle of
            Maybe.Nothing ->
                [ ( 0, circleId ) ]

            Maybe.Just aCircle ->
                listCircles
                    |> List.map (\c -> ( Plot.Circle.distance aCircle c, c.id ))
                    |> List.sort
