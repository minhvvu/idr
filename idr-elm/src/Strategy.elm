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
          , [ { id = "240", x = -18.814137268066407, y = -17.999588012695313, displayX = 23.717254638671875, displayY = 607.993408203125 }
            , { id = "76", x = -18.532794189453124, y = 18.73746109008789, displayX = 29.3441162109375, displayY = 20.20062255859375 }
            , { id = "35", x = 18.26318969726563, y = 18.996651649475098, displayX = 765.2637939453125, displayY = 16.053573608398438 }
            , { id = "27", x = 18.881735229492186, y = -17.601245880126953, displayX = 777.6347045898438, displayY = 601.6199340820313 }
            ]
          )
        , ( "COUNTRY1999_2"
          , [ { id = "240", x = -19.997283935546875, y = 19.939456939697266, displayX = 0.0543212890625, displayY = 0.96868896484375 } ]
          )
        , ( "COUNTRY1999_3"
          , [ { id = "47", x = 16.579440307617183, y = 0.3551788330078125, displayX = 731.5888061523438, displayY = 314.317138671875 }
            , { id = "19", x = -3.103251647949218, y = 0.2758445739746094, displayX = 337.9349670410156, displayY = 315.58648681640625 }
            , { id = "234", x = -18.824485778808594, y = -0.047260284423828125, displayX = 23.510284423828125, displayY = 320.75616455078125 }
            ]
          )
        ]


getStrategy : String -> String -> List FixedPoint
getStrategy datasetName strategyId =
    strategies
        |> Dict.get (datasetName ++ "_" ++ strategyId)
        |> Maybe.withDefault []
