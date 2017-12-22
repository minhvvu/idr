-- tsnex_client


module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Json.Decode as JD exposing (Decoder, string, float, list)
import Json.Decode.Pipeline as JDP exposing (decode, required)


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


socketServer : String
socketServer =
    "ws://127.0.0.1:5000/tsnex"


getDataURI : String
getDataURI =
    socketServer ++ "/get_data"



-- MODEL


type alias Point =
    { x : Float
    , y : Float
    }


type alias Model =
    { points : List Point
    }


init : ( Model, Cmd Msg )
init =
    ( Model [], WebSocket.send getDataURI "Client Get Init Data" )



-- UPDATE


type Msg
    = NewData String
    | RequestData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { points } =
    case msg of
        NewData str ->
            case JD.decodeString listPointsDecoder str of
                Err msg ->
                    ( Model [ Point -99.0 -99.0 ], Cmd.none )

                Ok listPoints ->
                    ( Model listPoints, Cmd.none )

        RequestData ->
            ( Model [], WebSocket.send getDataURI "Request data from client" )


pointDecoder : Decoder Point
pointDecoder =
    JDP.decode Point
        |> JDP.required "x" float
        |> JDP.required "y" float


listPointsDecoder : Decoder (List Point)
listPointsDecoder =
    JD.list pointDecoder



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen getDataURI NewData



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] (List.map viewPoint model.points)
        , button [ onClick RequestData ] [ text "Request Data" ]
        ]


viewPoint : Point -> Html Msg
viewPoint { x, y } =
    div [] [ text ("client point: {" ++ (toString x) ++ "," ++ (toString y) ++ "}") ]
