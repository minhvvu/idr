module Msgs exposing (..)

import Draggable
import Draggable.Events exposing (onDragBy, onDragStart, onClick)
import Common exposing (CircleId)
import Math.Vector2 as Vector2 exposing (Vec2)
import Bootstrap.Tab as Tab exposing (..)


type Msg
    = SelectDataset String
    | LoadDataset -- [send] load dataset (TODO add dataset name)
    | DatasetStatus String -- [receive] server response dataset info
    | DoEmbedding -- [send] do embedding
    | EmbeddingResult String -- [receive] the intermediate result
    | PauseServer -- [send] pause server
    | ContinueServer -- [send] unpause server
    | SendMovedPoints -- [send] send moved points to server
    | ResetData -- [send] send reset data command
    | DragMsg (Draggable.Msg CircleId) -- draggable message
    | StartDragging CircleId
    | OnDragBy Vec2
    | StopDragging
    | Select String
    | UpdateZoomFactor String -- zoom in/ zoom out the svg
    | UpdateGroupMoving String -- size of the radius using for group moving
    | ToggleLabel
    | ToggleColor
    | ToggleAutoZoom
    | SearchByLabel String
    | Zoom Float
    | DoStrategy String
    | TabMsg Tab.State


myDragConfig : Draggable.Config CircleId Msg
myDragConfig =
    Draggable.customConfig
        [ onDragBy (OnDragBy << Vector2.fromTuple)
        , onDragStart StartDragging
        , onClick Select
        ]
