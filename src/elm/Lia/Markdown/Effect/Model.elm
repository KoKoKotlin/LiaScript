module Lia.Markdown.Effect.Model exposing
    ( Element
    , Model
    , current_comment
    , current_paragraphs
    , get_paragraph
    , init
    , set_annotation
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Lia.Markdown.Effect.Script.Types exposing (Scripts)
import Lia.Markdown.HTML.Attributes exposing (Parameters)
import Lia.Markdown.Inline.Types exposing (Inlines)


type alias Model a =
    { visible : Int
    , effects : Int
    , comments : Dict Int Element
    , javascript : Scripts a
    , speaking : Maybe Int
    }


type alias Element =
    { narrator : String
    , comment : String
    , paragraphs : Array ( Parameters, Inlines )
    }


set_annotation : Int -> Int -> Dict Int Element -> Parameters -> Dict Int Element
set_annotation id1 id2 m attr =
    case Dict.get id1 m of
        Just e ->
            case Array.get id2 e.paragraphs of
                Just ( _, par ) ->
                    Dict.insert id1
                        { e
                            | paragraphs =
                                e.paragraphs
                                    |> Array.set id2 ( attr, par )
                        }
                        m

                Nothing ->
                    m

        Nothing ->
            m


get_paragraph : Int -> Int -> Model a -> Maybe ( String, ( Parameters, Inlines ) )
get_paragraph id1 id2 model =
    case Dict.get id1 model.comments of
        Just element ->
            element.paragraphs
                |> Array.get id2
                |> Maybe.map (Tuple.pair element.narrator)

        _ ->
            Nothing


current_paragraphs : Model a -> List ( Bool, List ( Parameters, Inlines ) )
current_paragraphs model =
    model.comments
        |> Dict.toList
        |> List.map
            (\( key, value ) ->
                ( key == model.visible
                , Array.toList value.paragraphs
                )
            )


current_comment : Model a -> Maybe ( Int, String, String )
current_comment model =
    model.comments
        |> Dict.get model.visible
        |> Maybe.map (\e -> ( model.visible, e.comment, e.narrator ))


init : Model a
init =
    Model
        0
        0
        Dict.empty
        Array.empty
        Nothing
