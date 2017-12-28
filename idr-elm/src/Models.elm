module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)


type alias Model =
    { rawData : List Point
    , scatter : Scatter
    , drag : Draggable.State CircleId
    }


initialModel : Model
initialModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    }



{- TODO how to defind an error-model -}


errorModel : Model
errorModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    }
