module Update exposing (..)

import Draggable
import Msgs exposing (Msg(..), myDragConfig)
import Commands exposing (..)
import Common exposing (Point)
import Models exposing (..)
import Plot.CircleGroup exposing (..)
import Plot.Scatter exposing (Scatter, createScatter, getMovedPoints)
import Array exposing (..)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)


{-| Big update function to handle all system messages
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ scatter, ready, neighbors, cf } as model) =
    case msg of
        {- Do embedding commands -}
        SelectDataset datasetName ->
            { model | datasetName = datasetName } ! []

        LoadDataset ->
            let
                newModel =
                    Models.initialModel
            in
                ( { newModel | datasetName = model.datasetName }
                , loadDataset model.datasetName
                )

        DatasetStatus datasetInfo ->
            updateDatasetInfo model datasetInfo

        DoEmbedding ->
            ( model, doEmbedding model.current_it )

        EmbeddingResult dataStr ->
            updateNewData model dataStr

        {- Control server command -}
        PauseServer ->
            { model | ready = False } ! []

        ContinueServer ->
            -- if we wish to run the server `manually`
            -- do not set the `ready` flag to `True`
            ( { model | ready = True }, sendContinue model.current_it )

        ResetData ->
            let
                newModel =
                    Models.initialModel
            in
                ( { newModel | datasetName = model.datasetName }, sendReset )

        {- Client interact commands -}
        SendMovedPoints ->
            let
                movedPoints =
                    Plot.Scatter.getMovedPoints scatter
            in
                ( { model | ready = True }, sendMovedPoints movedPoints )

        {- Drag circle in scatter plot commands -}
        OnDragBy delta ->
            if model.pointMoving then
                let
                    newScatter =
                        { scatter | points = dragActiveBy delta scatter.points }
                in
                    { model | scatter = newScatter } ! []
            else
                let
                    newDelta =
                        Vector2.scale -1.0 delta

                    newConfig =
                        { cf | center = cf.center |> Vector2.add newDelta }
                in
                    { model | cf = newConfig } ! []

        StartDragging circleId ->
            if String.isEmpty circleId then
                { model | pointMoving = False } ! []
            else
                let
                    newScatter =
                        { scatter
                            | selectedId = circleId
                            , points = startDragging circleId scatter.points
                        }
                            -- the dragged circle is also a selected one,
                            -- so we have to show its neighbors in high-dim
                            |> Plot.Scatter.updateSelectedCircle circleId neighbors
                in
                    { model | scatter = newScatter, pointMoving = True } ! []

        StopDragging ->
            let
                newScatter =
                    { scatter | points = stopDragging scatter.points }
            in
                { model | scatter = newScatter } ! []

        Select selectedId ->
            { model
                | scatter =
                    scatter
                        |> Plot.Scatter.updateSelectedCircle selectedId neighbors
            }
                ! []

        DragMsg dragMsg ->
            Draggable.update myDragConfig dragMsg model

        UpdateZoomFactor amount ->
            let
                newZoomFactor =
                    Result.withDefault 10.0 (String.toFloat amount)

                newScatter =
                    buildScatter model model.rawPoints model.scatter.selectedId newZoomFactor
            in
                { model | zoomFactor = newZoomFactor, scatter = newScatter } ! []

        UpdateGroupMoving amount ->
            let
                groupSize =
                    Result.withDefault 0.0 (String.toFloat amount)
            in
                { model | cf = { cf | selectionRadius = groupSize } } ! []

        ToggleLabel ->
            { model | cf = { cf | showLabel = not model.cf.showLabel } } ! []

        ToggleColor ->
            { model | cf = { cf | showColor = not model.cf.showColor } } ! []

        ToggleAutoZoom ->
            { model
                | cf =
                    { cf
                        | autoZoom = not model.cf.autoZoom
                        , center = Vector2.vec2 0 0
                    }
            }
                ! []

        SearchByLabel query ->
            let
                lowerQuery =
                    String.toLower query

                newScatter =
                    { scatter
                        | points = Plot.CircleGroup.updateHighlightPoint lowerQuery scatter.points
                    }
            in
                { model | scatter = newScatter } ! []

        Zoom factor ->
            let
                newZoomFactor =
                    model.zoomFactor
                        |> (+)
                            (if factor > 0 then
                                1.0
                             else
                                -1.0
                            )
                        |> round
                        |> toFloat
                        |> clamp 0.1 50

                newScatter =
                    buildScatter model model.rawPoints model.scatter.selectedId newZoomFactor
            in
                { model | zoomFactor = newZoomFactor, scatter = newScatter } ! []


{-| Util function to update new received data into model
-}
updateNewData : Model -> String -> ( Model, Cmd Msg )
updateNewData ({ ready, current_it } as model) dataStr =
    case decodeEmbeddingResult dataStr of
        Err msg ->
            Debug.log ("[ERROR]decodeEmbeddingResult:\n" ++ msg)
                ( Models.initialModel, Cmd.none )

        Ok embeddingResult ->
            let
                nextCommand =
                    if ready then
                        sendContinue (current_it + 1)
                    else
                        Cmd.none

                newRawPoints =
                    embeddingResult.embedding

                newScatter =
                    buildScatter model newRawPoints model.scatter.selectedId model.zoomFactor
            in
                ( { model
                    | current_it = current_it + 1
                    , scatter = newScatter
                    , seriesData = embeddingResult.seriesData
                    , rawPoints = newRawPoints
                  }
                , nextCommand
                )


buildScatter : Model -> List Point -> String -> Float -> Scatter
buildScatter model rawPoints selectedId zoomFactor =
    Plot.Scatter.createScatter rawPoints zoomFactor model.cf
        |> Plot.Scatter.updateSelectedCircle selectedId model.neighbors
        |> Plot.Scatter.updateImportantPoints model.importantPoints


updateDatasetInfo : Model -> String -> ( Model, Cmd Msg )
updateDatasetInfo model dataStr =
    case decodeDatasetInfo dataStr of
        Err msg ->
            Debug.log ("[ERROR]decodeEmbeddingResult:\n" ++ msg)
                ( Models.initialModel, Cmd.none )

        Ok datasetInfo ->
            { model
                | neighbors = Array.fromList datasetInfo.neighbors
                , distances = datasetInfo.distances
                , importantPoints = datasetInfo.importantPoints
                , debugMsg = datasetInfo.infoMsg
            }
                ! []
