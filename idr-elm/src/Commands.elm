module Commands exposing (..)

import WebSocket
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Common exposing (Point)
import Msgs exposing (Msg)


{-| Socket server URI
-}
socketServer : String
socketServer =
    "ws://127.0.0.1:5000/tsnex"


{-| Socket endpoint for transforming data from server to client
-}
getDataURI : String
getDataURI =
    socketServer ++ "/get_data"


{-| Socket endpoint for transforming list of moved points from client to server
-}
movedPointsURI : String
movedPointsURI =
    socketServer ++ "/moved_points"


{-| Socket endpoint for pausing server
-}
continueServerURI : String
continueServerURI =
    socketServer ++ "/continue_server"


{-| Client subscription to listen to the new data from server
-}
listenToNewData : Sub Msg
listenToNewData =
    WebSocket.listen getDataURI Msgs.NewData


{-| Client command to request the initial data
-}
getInitData : Cmd Msg
getInitData =
    WebSocket.send getDataURI "Get Initial Data"


{-| Client command to request new data
-}
getNewData : Cmd Msg
getNewData =
    WebSocket.send getDataURI "Request data from client"


{-| Client command to inform server about its `readiness`
to receive new data from the next iteration
-}
getNewDataAck : Bool -> Cmd Msg
getNewDataAck ready =
    WebSocket.send getDataURI ("ACK=" ++ (toString ready))



{- ! Client command to continue server after being paused -}


sendContinue : Cmd Msg
sendContinue =
    WebSocket.send continueServerURI "ACK=True"


{-| Client command to send a list of Points to server
-}
sendMovedPoints : List Point -> Cmd Msg
sendMovedPoints points =
    WebSocket.send movedPointsURI (encodeListPoints points)


{-| Util function to describe how to deocde json to a Point object
-}
pointDecoder : Decode.Decoder Point
pointDecoder =
    decode Point
        |> required "id" Decode.string
        |> required "x" Decode.float
        |> required "y" Decode.float
        |> required "label" Decode.string


{-| Util function to describle how to encode a Point object to json
-}
pointEncoder : Point -> Encode.Value
pointEncoder point =
    Encode.object
        [ ( "id", Encode.string point.id )
        , ( "x", Encode.float point.x )
        , ( "y", Encode.float point.y )
        ]


{-| Util function to describle how to decode json to a list of Point objects
-}
listPointsDecoder : Decode.Decoder (List Point)
listPointsDecoder =
    Decode.list pointDecoder


{-| Util function to describle how to encode a list of Point objects to json
-}
listPointEncoder : List Point -> Encode.Value
listPointEncoder points =
    Encode.list (List.map pointEncoder points)


{-| Util function to decode a json to a list of Point object
-}
decodeListPoints : String -> Result String (List Point)
decodeListPoints str =
    Decode.decodeString listPointsDecoder str


{-| Util function to encode a list of Point objects into json
-}
encodeListPoints : List Point -> String
encodeListPoints points =
    let
        pretyPrint =
            -- set to zero for disable prety json string
            1
    in
        points
            |> listPointEncoder
            |> Encode.encode pretyPrint
