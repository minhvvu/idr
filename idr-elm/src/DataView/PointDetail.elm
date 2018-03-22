module DataView.PointDetail exposing (..)

import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (..)
import Bootstrap.Utilities.Size as Size exposing (..)
import Bootstrap.Utilities.Border as Border exposing (..)
import Bootstrap.ListGroup as ListGroup exposing (..)
import Bootstrap.Badge as Badge
import Msgs exposing (Msg(..))
import Common exposing (..)
import Plot.Scatter exposing (..)
import Plot.Circle exposing (..)


dataview : String -> Html msg
dataview data =
    let
        longTexts =
            List.range 1 100
                |> List.map (\i -> div [] [ text ((toString i) ++ ": --------------------------------------------------------------------------------") ])
    in
        div [ Size.h25, Border.all, HtmlAttrs.style [ ( "overflow", "scroll" ) ] ] (longTexts)


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


selectedPointsView : Scatter -> Html Msg
selectedPointsView { points, selectedId } =
    Html.div [] []



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
