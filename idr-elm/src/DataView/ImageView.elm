module DataView.ImageView exposing (..)

import Html exposing (..)
import Models exposing (..)


view : Model -> Html msg
view { scatter, neighbors, distances } =
    Html.text <| toString <| scatter.selectedId
