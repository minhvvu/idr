module Commands exposing (..)

import WebSocket
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Common exposing (Point, SeriesData, EmbeddingResult, DatasetInfo)
import Msgs exposing (Msg)
import Strategy exposing (FixedPoint)


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
loadDataset : String -> Cmd Msg
loadDataset datasetName =
    if String.isEmpty datasetName then
        Cmd.none
    else
        WebSocket.send loadDatasetURI datasetName


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
sendFixedPoints : List FixedPoint -> Cmd Msg
sendFixedPoints points =
    WebSocket.send movedPointsURI (encodeListFixedPoints points)


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


{-| Socket endpoint for reseting data
-}
resetURI : String
resetURI =
    socketServer ++ "/reset"


{-| Client command to reset data
-}
sendReset : Cmd Msg
sendReset =
    WebSocket.send resetURI "ConfirmReset"


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
        |> required "z" Decode.float
        |> required "label" Decode.string
        |> required "text" Decode.string
        |> required "fixed" Decode.bool


{-| Util function to describle how to encode a Point object to json
-}
fixedPointEncoder : FixedPoint -> Encode.Value
fixedPointEncoder p =
    Encode.object
        [ ( "id", Encode.string p.id )
        , ( "x", Encode.float p.x )
        , ( "y", Encode.float p.y )
        , ( "displayX", Encode.float p.displayX )
        , ( "displayY", Encode.float p.displayY )
        ]


{-| Util function to describle how to decode json to a list of Point objects
-}
listPointsDecoder : Decode.Decoder (List Point)
listPointsDecoder =
    Decode.list pointDecoder


{-| Util function to describle how to encode a list of FixedPoint objects to json
-}
listFixedPointEncoder : List FixedPoint -> Encode.Value
listFixedPointEncoder points =
    Encode.list (List.map fixedPointEncoder points)


{-| Util function to decode a json to a list of Point object
-}
decodeListPoints : String -> Result String (List Point)
decodeListPoints str =
    Decode.decodeString listPointsDecoder str


{-| Util function to encode a list of Point objects into json
-}
encodeListFixedPoints : List FixedPoint -> String
encodeListFixedPoints points =
    points
        |> listFixedPointEncoder
        -- prety print
        |> Encode.encode 1


{-| Util function to decode series data
-}
seriesDataDecoder : Decode.Decoder SeriesData
seriesDataDecoder =
    decode SeriesData
        |> required "name" Decode.string
        |> required "series" (Decode.list (Decode.list Decode.float))


embeddingResultDecoder : Decode.Decoder EmbeddingResult
embeddingResultDecoder =
    decode EmbeddingResult
        |> required "embedding" listPointsDecoder
        |> required "seriesData" (Decode.list seriesDataDecoder)
        |> required "distances" (Decode.list (Decode.list Decode.float))
        |> required "neighbors" (Decode.list (Decode.list Decode.string))


decodeEmbeddingResult : String -> Result String EmbeddingResult
decodeEmbeddingResult str =
    Decode.decodeString embeddingResultDecoder str


{-| Util function to decode dataset info
-}
datasetInfoDecoder : Decode.Decoder DatasetInfo
datasetInfoDecoder =
    decode DatasetInfo
        |> required "distances" (Decode.list (Decode.list Decode.float))
        |> required "neighbors" (Decode.list (Decode.list Decode.string))
        |> required "importantPoints" (Decode.list Decode.string)
        |> required "infoMsg" Decode.string


decodeDatasetInfo : String -> Result String DatasetInfo
decodeDatasetInfo str =
    Decode.decodeString datasetInfoDecoder str
