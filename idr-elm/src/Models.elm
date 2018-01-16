module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)


type alias Model =
    { rawData : List Point
    , scatter : Scatter
    , drag : Draggable.State CircleId
    , ready : Bool
    , current_it : Int
    , debugMsg : String
    }


initialModel : Model
initialModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    }



{- TODO how to defind an error-model -}


errorModel : Model
errorModel =
    { rawData = []
    , scatter = emptyScatter
    , drag = Draggable.init
    , ready = False
    , current_it = -1
    , debugMsg = "Error occurs"
    }
