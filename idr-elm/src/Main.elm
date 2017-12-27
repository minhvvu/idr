-- tsnex_client


module Main exposing (..)

import Draggable
import Html exposing (program)
import Models exposing (Model, initialModel)
import Commands exposing (getInitData, listenToNewData)
import Update exposing (update)
import View exposing (view)
import Msgs exposing (Msg(..))


init : ( Model, Cmd Msg )
init =
    ( initialModel, getInitData )


subscriptions : Model -> Sub Msg
subscriptions ({ drag } as model) =
    Sub.batch
        [ listenToNewData
        , Draggable.subscriptions DragMsg drag
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }