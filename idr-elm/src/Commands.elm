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


{-| Socket endpoint for loading a new dataset
-}
loadDatasetURI : String
loadDatasetURI =
    socketServer ++ "/load_dataset"


{-| Client command to load a new dataset
-}
loadDataset : Cmd Msg
loadDataset =
    WebSocket.send loadDatasetURI "MNIST"


{-| Socket endpoint for calling function to do embedding
-}
doEmbeddingURI : String
doEmbeddingURI =
    socketServer ++ "/do_embedding"


{-| Client command request to do embedding with param is the iteration
-}
doEmbedding : Int -> Cmd Msg
doEmbedding iteration =
    WebSocket.send doEmbeddingURI (toString iteration)


{-| Socket endpoint for transforming list of moved points from client to server
-}
movedPointsURI : String
movedPointsURI =
    socketServer ++ "/moved_points"


{-| Client command to send a list of Points to server
-}
sendMovedPoints : List Point -> Cmd Msg
sendMovedPoints points =
    WebSocket.send movedPointsURI (encodeListPoints points)


{-| Socket endpoint for pausing server
-}
continueServerURI : String
continueServerURI =
    socketServer ++ "/continue_server"


{-| Client command to continue server after being paused
-}
sendContinue : Int -> Cmd Msg
sendContinue currentIteration =
    WebSocket.send continueServerURI (toString currentIteration)


{-| Client subscription to listen to the new data from server
-}
listenToNewData : Sub Msg
listenToNewData =
    Sub.batch
        [ WebSocket.listen loadDatasetURI Msgs.DatasetStatus
        , WebSocket.listen doEmbeddingURI Msgs.EmbeddingResult
        ]


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
