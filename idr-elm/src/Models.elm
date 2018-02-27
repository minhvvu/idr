module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)


type alias Model =
    { rawData : List Point
    , scatter : Scatter
    , seriesData : List SeriesData
    , drag : Draggable.State CircleId
    , ready : Bool
    , current_it : Int
    , debugMsg : String
    , zoomFactor : Float
    , datasetName : String
    , neighbors : List (List String)
    , distances : List (List Float)
    , importantPoints : List String
    }


initialModel : Model
initialModel =
    { rawData = []
    , scatter = emptyScatter
    , seriesData = []
    , drag = Draggable.init
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    , zoomFactor = 1.0
    , datasetName = ""
    , neighbors = []
    , distances = []
    , importantPoints = []
    }
