module DataView.PointDetail exposing (..)

import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (..)
import Bootstrap.Utilities.Size as Size exposing (..)
import Bootstrap.Utilities.Border as Border exposing (..)
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Plot.Scatter exposing (..)
import Plot.Circle exposing (..)
import DataView.ImageView as ImageView exposing (..)
import DataView.TableView as TableView exposing (..)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Msgs exposing (Msg(..))
import Common exposing (..)
import Models exposing (..)


{-| Public API for calling drawing a list of moved circle in CircleGroup
-}
movedPointsView : List Circle -> Html Msg
movedPointsView movedCircles =
    let
        pointToListItem =
            (\p ->
                ListGroup.li
                    [ ListGroup.attrs [ HtmlAttrs.class "justify-content-between" ] ]
                    [ Badge.pillPrimary [] [ Html.text p.id ]
                    , Html.text
                        ("["
                            ++ p.text
                            ++ "], ("
                            ++ p.label
                            ++ "), {"
                            ++ (toString <| round <| getX <| p.position)
                            ++ ", "
                            ++ (toString <| round <| getY <| p.position)
                            ++ "}"
                        )
                    ]
            )
    in
        ListGroup.ul (List.map pointToListItem movedCircles)


selectedPointsView : Model -> Html Msg
selectedPointsView model =
    case getDatasetType model.cf.datasetName of
        Image ->
            ImageView.view model

        _ ->
            TableView.view "Table view here"



--let
--    neighbors =
--        Plot.CircleGroup.getKNN selectedId {-missing config here-} points
--in
--    Html.div []
--        [ Html.text ("Selected Id: " ++ selectedId)
--        , Html.br [] []
--        , Html.text
--            (if List.isEmpty neighbors then
--                "No neighbors"
--             else
--                (toString (List.length neighbors)
--                    ++ " neighbors: "
--                    ++ (toString neighbors)
--                )
--            )
--        ]
