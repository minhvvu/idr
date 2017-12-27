module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.CircleGroup exposing (CircleGroup, emptyGroup)


type alias Model =
    { points : CircleGroup
    , drag : Draggable.State CircleId
    }


initialModel : Model
initialModel =
    { points = emptyGroup
    , drag = Draggable.init
    }



{- TODO how to defind an error-model -}


errorModel : Model
errorModel =
    { points = emptyGroup
    , drag = Draggable.init
    }
