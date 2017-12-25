module Update exposing (..)

import Msgs exposing (Msg)
import Commands exposing (getNewData, decodeListPoints)
import Models exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msgs.NewData dataStr ->
            updateNewData dataStr

        Msgs.RequestData ->
            ( Models.initialModel, getNewData )


updateNewData : String -> ( Model, Cmd Msg )
updateNewData dataStr =
    case decodeListPoints dataStr of
        Err msg ->
            ( Models.errorModel, Cmd.none )

        Ok listPoints ->
            ( Model listPoints, Cmd.none )
