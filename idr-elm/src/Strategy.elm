module Strategy exposing (..)

import Dict exposing (Dict, get)


type alias FixedPoint =
    { id : String
    , x : Float
    , y : Float
    , displayX : Float
    , displayY : Float
    }


strategies =
    Dict.fromList
        [ ( "COUNTRY1999_1"
          , [ { id = "185", x = 18.129376220703122, y = 10.727090454101564, displayX = 762.5875244140625, displayY = 614.5418090820313 }
            , { id = "28", x = -19.087408447265624, y = 11.15969543457031, displayX = 18.2518310546875, displayY = 623.1939086914063 }
            , { id = "99", x = 11.493627929687502, y = -19.380674743652342, displayX = 629.87255859375, displayY = 12.386505126953125 }
            , { id = "68", x = -18.68573455810547, y = -19.116424560546875, displayX = 26.285308837890625, displayY = 17.6715087890625 }
            ]
          )
        ]


getStrategy : String -> String -> List FixedPoint
getStrategy datasetName strategyId =
    strategies
        |> Dict.get (datasetName ++ "_" ++ strategyId)
        |> Maybe.withDefault []
