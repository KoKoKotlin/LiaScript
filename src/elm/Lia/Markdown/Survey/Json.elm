module Lia.Markdown.Survey.Json exposing
    ( fromVector
    , toVector
    )

import Accessibility.Aria exposing (errorMessage)
import Conditional.List as CList
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import Lia.Markdown.Survey.Types exposing (Element, State(..), Vector)


fromVector : Vector -> JE.Value
fromVector vector =
    JE.array (Tuple.first >> fromElement) vector


fromElement : Element -> JE.Value
fromElement ( b, state, errorMessage ) =
    [ ( "submitted", JE.bool b )
    , ( "state", fromState state )
    ]
        |> CList.addWhen (fromError errorMessage)
        |> JE.object


fromError : Maybe String -> Maybe ( String, JE.Value )
fromError =
    Maybe.map (JE.string >> Tuple.pair "errorMessage")


fromState : State -> JE.Value
fromState state =
    JE.object <|
        case state of
            Text_State str ->
                [ ( "Text"
                  , JE.string str
                  )
                ]

            Select_State _ i ->
                [ ( "Select"
                  , JE.int i
                  )
                ]

            Vector_State single vector ->
                [ ( if single then
                        "SingleChoice"

                    else
                        "MultipleChoice"
                  , dict2json vector
                  )
                ]

            Matrix_State single matrix ->
                [ ( if single then
                        "SingleChoiceMatrix"

                    else
                        "MultipleChoiceMatrix"
                  , JE.array dict2json matrix
                  )
                ]


dict2json : Dict String Bool -> JE.Value
dict2json dict =
    dict
        |> Dict.toList
        |> List.map (\( s, b ) -> ( s, JE.bool b ))
        |> JE.object


toVector : JD.Value -> Result JD.Error Vector
toVector json =
    JD.decodeValue (JD.array (toElement |> JD.map (\e -> ( e, Nothing )))) json


toElement : JD.Decoder Element
toElement =
    JD.map3 (\a b c -> ( a, b, c ))
        (JD.field "submitted" JD.bool)
        (JD.field "state" toState)
        (JD.maybe (JD.field "errorMessage" JD.string))


toState : JD.Decoder State
toState =
    JD.oneOf
        [ JD.field "Text" JD.string
            |> JD.map Text_State
        , JD.field "Select" JD.int
            |> JD.map (Select_State False)
        , JD.field "SingleChoice" (JD.dict JD.bool)
            |> JD.map (Vector_State True)
        , JD.field "MultipleChoice" (JD.dict JD.bool)
            |> JD.map (Vector_State False)
        , JD.field "SingleChoiceMatrix" (JD.array (JD.dict JD.bool))
            |> JD.map (Matrix_State False)
        , JD.field "MultipleChoiceMatrix" (JD.array (JD.dict JD.bool))
            |> JD.map (Matrix_State True)
        ]
