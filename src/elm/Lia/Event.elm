module Lia.Event exposing
    ( Eval
    , Event
    , eval
    , evalDecode
    , evalDecoder
    , evalEncode
    , fromJson
    , store
    , toJson
    )

import Json.Decode as JD
import Json.Encode as JE
import Lia.Utils exposing (string_replace)


type alias Event =
    { topic : String
    , section : Int
    , message : JE.Value
    }


type alias Eval =
    { ok : Bool
    , result : String
    , details : List JE.Value
    }


toJson : Event -> JE.Value
toJson { topic, section, message } =
    JE.object
        [ ( "topic", JE.string topic )
        , ( "section", JE.int section )
        , ( "message", message )
        ]


fromJson : JD.Value -> Result JD.Error Event
fromJson json =
    JD.decodeValue
        (JD.map3 Event
            (JD.field "topic" JD.string)
            (JD.field "section" JD.int)
            (JD.field "message" JD.value)
        )
        json


store : JE.Value -> Event
store message =
    Event "store" -1 message


eval : Int -> String -> String -> Event
eval idx code replacement =
    code
        |> string_replace ( "@input", replacement )
        |> JE.string
        |> Event "eval" idx


evalDecoder : JD.Decoder Eval
evalDecoder =
    JD.map3 Eval
        (JD.field "ok" JD.bool)
        (JD.field "result" JD.string)
        (JD.field "details" (JD.list JD.value))


evalDecode : JD.Value -> Eval
evalDecode json =
    case JD.decodeValue evalDecoder json of
        Ok result ->
            result

        Err info ->
            Eval False (JD.errorToString info) []


evalEncode : Eval -> JE.Value
evalEncode { ok, result, details } =
    JE.object
        [ ( "ok", JE.bool ok )
        , ( "result", JE.string result )
        , ( "details", JE.list identity details )
        ]