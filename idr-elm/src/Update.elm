module Update exposing (..)

import Draggable
import Msgs exposing (Msg(..), myDragConfig)
import Commands exposing (getNewData, decodeListPoints)
import Models exposing (..)
import Plot.CircleGroup exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ points } as model) =
    case msg of
        NewData dataStr ->
            updateNewData dataStr

        RequestData ->
            ( Models.initialModel, getNewData )

        OnDragBy delta ->
            { model | points = dragActiveBy delta points } ! []

        StartDragging circleId ->
            { model | points = startDragging circleId points } ! []

        StopDragging ->
            { model | points = stopDragging points } ! []

        DragMsg dragMsg ->
            Draggable.update myDragConfig dragMsg model


updateNewData : String -> ( Model, Cmd Msg )
updateNewData dataStr =
    case decodeListPoints dataStr of
        Err msg ->
            ( Models.errorModel, Cmd.none )

        Ok listPoints ->
            ( { initialModel | points = (createCircleGroup listPoints) }, Cmd.none )
