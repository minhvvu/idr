module Commands exposing (..)

import WebSocket
import Json.Encode as Encode
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


movedPointsURI : String
movedPointsURI =
    socketServer ++ "/moved_points"


listenToNewData : Sub Msg
listenToNewData =
    WebSocket.listen getDataURI Msgs.NewData


getInitData : Cmd Msg
getInitData =
    WebSocket.send getDataURI "Get Initial Data"


getNewData : Cmd Msg
getNewData =
    WebSocket.send getDataURI "Request data from client"


sendMovedPoints : List Point -> Cmd Msg
sendMovedPoints points =
    WebSocket.send movedPointsURI (Encode.encode 4 (encodeListPoints points))


pointDecoder : Decode.Decoder Point
pointDecoder =
    decode Point
        |> required "id" Decode.string
        |> required "x" Decode.float
        |> required "y" Decode.float


listPointsDecoder : Decode.Decoder (List Point)
listPointsDecoder =
    Decode.list pointDecoder


decodeListPoints : String -> Result String (List Point)
decodeListPoints str =
    Decode.decodeString listPointsDecoder str


encodePoint : Point -> Encode.Value
encodePoint point =
    Encode.object
        [ ( "id", Encode.string point.id )
        , ( "x", Encode.float point.x )
        , ( "y", Encode.float point.y )
        ]


encodeListPoints : List Point -> Encode.Value
encodeListPoints points =
    Encode.list (List.map encodePoint points)
