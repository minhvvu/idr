module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)
import Array exposing (Array, fromList)


type alias Model =
    { scatter : Scatter -- main data for scatter plot
    , seriesData : List SeriesData -- series data from server for line charts
    , drag : Draggable.State CircleId -- this var must be named `drag`, used by Draggable lib
    , ready : Bool -- status flag denoting that client is ready for receiving new data
    , current_it : Int -- current iteration in client
    , debugMsg : String -- message showing dataset info, ...
    , zoomFactor : Float -- make the viz auto fit, confused with panning and zoomming feature
    , datasetName : String -- store the name of selected dataset
    , neighbors : Array (List String) -- a list of knn of each point in high dim
    , distances : List (List Float) -- pairwise distance b.w. points in high dim
    , importantPoints : List String -- a list of important points calculated by server
    , cf : PlotConfig -- all config for ploting
    , pointMoving : Bool -- panning or moving a point
    , rawPoints : List Point -- a list of raw point from server, store it for zoom when pausing
    }


initialModel : Model
initialModel =
    { scatter = emptyScatter
    , seriesData = []
    , drag = Draggable.init
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    , zoomFactor = 20.0
    , datasetName = ""
    , neighbors = Array.fromList []
    , distances = []
    , importantPoints = []
    , cf = plotConfig
    , pointMoving = False
    , rawPoints = []
    }
