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
-}
startDragging : CircleId -> CircleGroup -> CircleGroup
startDragging circleId oldGroup =
    let
        group =
            oldGroup
                |> correctCircleGroup
                |> updateSelectedCircle circleId

        neighbors =
            getKNN 5.0 10 circleId oldGroup

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
dragActiveBy : Delta -> CircleGroup -> CircleGroup
dragActiveBy delta group =
    { group
        | movingCircles = group.movingCircles |> List.map (moveCircle delta)
    }


{-| Update selected circle
-}
updateSelectedCircle : CircleId -> CircleGroup -> CircleGroup
updateSelectedCircle circleId group =
    let
        updatedIdleCircles =
            group.idleCircles |> List.map (Plot.Circle.toggleSelected circleId)
    in
        { group | idleCircles = updatedIdleCircles }


{-| Util function to update a list of moved circles
TODO FIX: we have a list of moving circles now!
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


{-| Util function to get a list of circles by circleIds
-}
getCircleById : List CircleId -> CircleGroup -> List Circle
getCircleById listCircleIds group =
    List.filter (\c -> List.member c.id listCircleIds) group.idleCircles



--{-| Util function to get a list of position of idle circle
---}
--getPosOfIdlePoints : CircleGroup -> List (Float Float)
--getPosOfIdlePoints group =
--    List.map Plot.Circle.getPosition group.idleCircles


getKNN : Float -> Int -> CircleId -> CircleGroup -> List CircleId
getKNN threshold k circleId group =
    let
        knn =
            calculateDistances circleId group.idleCircles
    in
        knn
            |> List.filter (\p -> Tuple.first p < threshold)
            |> List.take k
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

        distances =
            case foundCircle of
                Maybe.Nothing ->
                    [ ( 0, circleId ) ]

                Maybe.Just aCircle ->
                    listCircles
                        |> List.map
                            (\c ->
                                ( Plot.Circle.distance aCircle c, c.id )
                            )
    in
        List.sort distances
