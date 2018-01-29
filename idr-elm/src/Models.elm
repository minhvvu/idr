module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)
import Plot.LineChart exposing (LineSeries, emptySeries)


type alias Model =
    { rawData : List Point
    , scatter : Scatter
    , errorSeries : LineSeries
    , drag : Draggable.State CircleId
    , ready : Bool
    , current_it : Int
    , debugMsg : String
    , zoomFactor : Float
    }


initialModel : Model
initialModel =
    { rawData = []
    , scatter = emptyScatter
    , errorSeries = emptySeries
    , drag = Draggable.init
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    , zoomFactor = 1.0
    }



{- TODO how to defind an error-model -}


errorModel : Model
errorModel =
    { rawData = []
    , scatter = emptyScatter
    , errorSeries = emptySeries
    , drag = Draggable.init
    , ready = False
    , current_it = -1
    , debugMsg = "Error occurs"
    , zoomFactor = 0.0
    }
