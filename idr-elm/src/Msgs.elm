module Msgs exposing (..)

import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Common exposing (CircleId)


type Msg
    = NewData String
    | NewDataAck Bool
    | RequestData
    | DragMsg (Draggable.Msg CircleId)
    | StartDragging CircleId
    | OnDragBy Draggable.Delta
    | StopDragging
    | SendMovedPoints
    | PauseServer


myDragConfig : Draggable.Config CircleId Msg
myDragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]
