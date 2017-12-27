module Common exposing (..)


type alias CircleId =
    String


toCircleId : number -> String
toCircleId a =
    toString a


type alias Point =
    { id : Int
    , x : Float
    , y : Float
    }
