module Lia.Markdown.Task.Json exposing
    ( fromVector
    , toVector
    )

import Json.Decode as JD
import Json.Encode as JE
import Lia.Markdown.Task.Types exposing (Vector)


{-| Convert a Task vector into a JSON representation.
-}
fromVector : Vector -> JE.Value
fromVector =
    JE.array (JE.array JE.bool)


{-| Read in a Task vector from a JSON representation.
-}
toVector : JD.Value -> Result JD.Error Vector
toVector =
    JD.decodeValue (JD.array (JD.array JD.bool))
