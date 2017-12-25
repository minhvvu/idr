module Models exposing (..)


type alias Point =
    { id : Int
    , x : Float
    , y : Float
    }


type alias Model =
    { points : List Point
    }


initialModel : Model
initialModel =
    Model []


errorModel : Model
errorModel =
    Model [ Point -1 -99.0 -99.0 ]
