module Update exposing (..)

import Draggable
import Msgs exposing (Msg(..), myDragConfig)
import Commands exposing (..)
import Models exposing (..)
import Plot.CircleGroup exposing (..)
import Plot.Scatter exposing (createScatter, getMovedPoints)
import Array exposing (..)
import Task exposing (succeed, perform)


{-| Big update function to handle all system messages
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ scatter, ready, neighbors } as model) =
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
            let
                newScatter =
                    { scatter | points = dragActiveBy delta scatter.points }
            in
                { model | scatter = newScatter } ! []

        StartDragging circleId ->
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
                { model | scatter = newScatter } ! []

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

                updatedScatter =
                    model.rawData
                        |> flip Plot.Scatter.createScatter newZoomFactor
                        |> Plot.Scatter.updateSelectedCircle scatter.selectedId neighbors
            in
                { model | zoomFactor = newZoomFactor, scatter = updatedScatter } ! []

        ClickSvg str ->
            ( model, Cmd.none )


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

                rawPoints =
                    embeddingResult.embedding

                seriesData =
                    embeddingResult.seriesData

                oldSelectedId =
                    model.scatter.selectedId

                newScatter =
                    Plot.Scatter.createScatter rawPoints model.zoomFactor
                        |> Plot.Scatter.updateSelectedCircle oldSelectedId model.neighbors
                        |> Plot.Scatter.updateImportantPoints model.importantPoints
            in
                ( { model
                    | current_it = current_it + 1
                    , rawData = rawPoints
                    , scatter = newScatter
                    , seriesData = seriesData
                  }
                , nextCommand
                )


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
