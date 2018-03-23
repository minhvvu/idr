module Models exposing (..)

import Draggable
import Common exposing (..)
import Plot.Scatter exposing (Scatter, emptyScatter)
import Array exposing (Array, fromList)
import Bootstrap.Tab as Tab exposing (..)


type alias Model =
    { rawPoints : List Point -- a list of raw point from server, store it for zoom when pausing
    , scatter : Scatter -- main data for scatter plot
    , seriesData : List SeriesData -- series data from server for line charts

    --
    , ready : Bool -- status flag denoting that client is ready for receiving new data
    , current_it : Int -- current iteration in client
    , debugMsg : String -- message showing dataset info, ...
    , cf : PlotConfig -- all config for ploting

    --
    , dataModel : DataModel -- contains data of distances and neighbors of each points in high and low dim

    --
    , pointMoving : Bool -- panning or moving a point
    , drag : Draggable.State CircleId -- this var must be named `drag`, used by Draggable lib
    , tabState : Tab.State -- needed for Boostrap.Tab
    }


initialModel : Model
initialModel =
    { rawPoints = []
    , scatter = emptyScatter
    , seriesData = []
    , ready = True
    , current_it = 0
    , debugMsg = "Client ready"
    , cf = plotConfig
    , dataModel = initialDataModel
    , pointMoving = False
    , drag = Draggable.init
    , tabState = Tab.initialState
    }


type alias DataModel =
    { importantPoints : List String -- a list of important points calculated by server
    , xDistances : Array (List Float) -- pairwise distance b.w. points in HIGH dim
    , xNeighbors : Array (List String) -- a list of knn of each point in HIGH dim
    , yDistances : Array (List Float) -- in LOW dim
    , yNeighbors : Array (List String) -- in LOW dim
    }


initialDataModel : DataModel
initialDataModel =
    { importantPoints = []
    , xDistances = Array.fromList []
    , xNeighbors = Array.fromList []
    , yDistances = Array.fromList []
    , yNeighbors = Array.fromList []
    }
