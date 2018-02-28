module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)
import Array exposing (Array, fromList)


type alias Model =
    { scatter : Scatter
    , seriesData : List SeriesData
    , drag : Draggable.State CircleId
    , ready : Bool
    , current_it : Int
    , debugMsg : String
    , zoomFactor : Float
    , datasetName : String
    , neighbors : Array (List String)
    , distances : List (List Float)
    , importantPoints : List String
    , cf : PlotConfig
    }


initialModel : Model
initialModel =
    { scatter = emptyScatter
    , seriesData = []
    , drag = Draggable.init
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    , zoomFactor = 1.0
    , datasetName = ""
    , neighbors = Array.fromList []
    , distances = []
    , importantPoints = []
    , cf = plotConfig
    }
