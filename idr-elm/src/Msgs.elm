module Msgs exposing (..)

import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Common exposing (CircleId)


type Msg
    = NewData String
    | LoadDataset -- [send] load dataset (TODO add dataset name)
    | DatasetStatus String -- [receive] server response dataset info
    | DoEmbedding -- [send] do embedding
    | DragMsg (Draggable.Msg CircleId) -- draggable message
    | StartDragging CircleId
    | OnDragBy Draggable.Delta
    | StopDragging
    | SendMovedPoints
    | PauseServer
    | ContinueServer


myDragConfig : Draggable.Config CircleId Msg
myDragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]
