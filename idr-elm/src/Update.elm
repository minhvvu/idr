module Update exposing (..)

import Draggable
import Msgs exposing (Msg(..), myDragConfig)
import Commands exposing (getNewData, decodeListPoints, sendMovedPoints)
import Models exposing (..)
import Plot.Scatter exposing (createScatter)
import Plot.CircleGroup exposing (..)


{-| Big update function to handle all system messages
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ scatter } as model) =
    case msg of
        NewData dataStr ->
            updateNewData dataStr

        RequestData ->
            ( Models.initialModel, getNewData )

        OnDragBy delta ->
            let
                newScatter =
                    { scatter | points = dragActiveBy delta scatter.points }
            in
                { model | scatter = newScatter } ! []

        StartDragging circleId ->
            let
                newScatter =
                    { scatter | points = startDragging circleId scatter.points }
            in
                { model | scatter = newScatter } ! []

        StopDragging ->
            let
                newScatter =
                    { scatter | points = stopDragging scatter.points }
            in
                { model | scatter = newScatter } ! []

        DragMsg dragMsg ->
            Draggable.update myDragConfig dragMsg model

        SendMovedPoints ->
            let
                movedPoints =
                    getMovedPoints scatter.points
            in
                ( model, sendMovedPoints movedPoints )


{-| Util function to update new received data into model
-}
updateNewData : String -> ( Model, Cmd Msg )
updateNewData dataStr =
    case decodeListPoints dataStr of
        Err msg ->
            Debug.log "[Error Decode data]" ( Models.errorModel, Cmd.none )

        Ok rawPoints ->
            ( { initialModel
                | rawData = rawPoints
                , scatter = Plot.Scatter.createScatter rawPoints
              }
            , Cmd.none
            )
