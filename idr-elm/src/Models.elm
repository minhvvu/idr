module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)


type alias Model =
    { rawData : List Point
    , scatter : Scatter
    , drag : Draggable.State CircleId
    , ready : Bool
    }


initialModel : Model
initialModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    , ready = True
    }



{- TODO how to defind an error-model -}


errorModel : Model
errorModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    , ready = False
    }
