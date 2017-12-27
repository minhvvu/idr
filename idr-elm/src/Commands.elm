module Commands exposing (..)

import WebSocket
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Common exposing (Point)
import Msgs exposing (Msg)


socketServer : String
socketServer =
    "ws://127.0.0.1:5000/tsnex"


getDataURI : String
getDataURI =
    socketServer ++ "/get_data"


listenToNewData : Sub Msg
listenToNewData =
    WebSocket.listen getDataURI Msgs.NewData


getInitData : Cmd Msg
getInitData =
    WebSocket.send getDataURI "Get Initial Data"


getNewData : Cmd Msg
getNewData =
    WebSocket.send getDataURI "Request data from client"


pointDecoder : Decode.Decoder Point
pointDecoder =
    decode Point
        |> required "id" Decode.int
        |> required "x" Decode.float
        |> required "y" Decode.float


listPointsDecoder : Decode.Decoder (List Point)
listPointsDecoder =
    Decode.list pointDecoder


decodeListPoints : String -> Result String (List Point)
decodeListPoints str =
    Decode.decodeString listPointsDecoder str
