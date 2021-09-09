module Lia.Markdown.Quiz.Update exposing (Msg(..), handle, update)

import Array
import Json.Encode as JE
import Lia.Markdown.Effect.Script.Types as Script exposing (Scripts, outputs)
import Lia.Markdown.Quiz.Block.Update as Block
import Lia.Markdown.Quiz.Json as Json
import Lia.Markdown.Quiz.Matrix.Update as Matrix
import Lia.Markdown.Quiz.Solution as Solution
import Lia.Markdown.Quiz.Types exposing (Element, State(..), Type, Vector, comp, toState)
import Lia.Markdown.Quiz.Vector.Update as Vector
import Port.Eval as Eval
import Port.Event as Event exposing (Event)
import Return exposing (Return)


type Msg sub
    = Block_Update Int (Block.Msg sub)
    | Vector_Update Int (Vector.Msg sub)
    | Matrix_Update Int (Matrix.Msg sub)
    | Check Int Type (Maybe String)
    | ShowHint Int
    | ShowSolution Int Type
    | Handle Event
    | Script (Script.Msg sub)


update : Scripts a -> Msg sub -> Vector -> Return Vector msg sub
update scripts msg vector =
    case msg of
        Block_Update id _ ->
            update_ id vector (state_ msg)

        Vector_Update id _ ->
            update_ id vector (state_ msg)

        Matrix_Update id _ ->
            update_ id vector (state_ msg)

        Check id solution Nothing ->
            check solution
                |> update_ id vector
                |> store

        Check idx _ (Just code) ->
            let
                state =
                    case
                        vector
                            |> Array.get idx
                            |> Maybe.map .state
                    of
                        Just (Block_State b) ->
                            Block.toString b

                        Just (Vector_State s) ->
                            Vector.toString s

                        Just (Matrix_State m) ->
                            Matrix.toString m

                        _ ->
                            ""
            in
            vector
                |> Return.value
                |> Return.event
                    (Eval.event idx
                        code
                        (outputs scripts)
                        [ state ]
                    )

        ShowHint idx ->
            (\e -> Return.value { e | hint = e.hint + 1 })
                |> update_ idx vector
                |> store

        ShowSolution idx solution ->
            (\e -> Return.value { e | state = toState solution, solved = Solution.ReSolved, error_msg = "" })
                |> update_ idx vector
                |> store

        Handle event ->
            case event.topic of
                "eval" ->
                    event.message
                        |> evalEventDecoder
                        |> update_ event.section vector
                        |> store

                "restore" ->
                    event.message
                        |> Json.toVector
                        |> Result.withDefault vector
                        |> Return.value

                _ ->
                    Return.value vector

        Script sub ->
            vector
                |> Return.value
                |> Return.script sub


get : Int -> Vector -> Maybe Element
get idx vector =
    case Array.get idx vector of
        Just elem ->
            if (elem.solved == Solution.Solved) || (elem.solved == Solution.ReSolved) then
                Nothing

            else
                Just elem

        _ ->
            Nothing


update_ :
    Int
    -> Vector
    -> (Element -> Return Element msg sub)
    -> Return Vector msg sub
update_ idx vector fn =
    Return.value <|
        case get idx vector |> Maybe.map fn of
            Just elem ->
                Array.set idx elem.value vector

            _ ->
                vector


state_ : Msg sub -> Element -> Return Element msg sub
state_ msg e =
    case ( msg, e.state ) of
        ( Block_Update _ m, Block_State s ) ->
            s
                |> Block.update m
                |> Return.map (setState e Block_State)

        ( Vector_Update _ m, Vector_State s ) ->
            s
                |> Vector.update m
                |> Return.map (setState e Vector_State)

        ( Matrix_Update _ m, Matrix_State s ) ->
            s
                |> Matrix.update m
                |> Return.map (setState e Matrix_State)

        _ ->
            Return.value e


setState : Element -> (s -> State) -> s -> Element
setState e fn state =
    { e | state = fn state }


handle : Event -> Msg sub
handle =
    Handle


evalEventDecoder : JE.Value -> Element -> Return Element msg sub
evalEventDecoder json =
    let
        eval =
            Eval.decode json
    in
    if eval.ok then
        if eval.result == "true" then
            \e ->
                Return.value
                    { e
                        | trial = e.trial + 1
                        , solved = Solution.Solved
                        , error_msg = ""
                    }

        else
            \e ->
                Return.value
                    { e
                        | trial =
                            if eval.result == "false" then
                                e.trial + 1

                            else
                                e.trial
                        , solved = Solution.Open
                        , error_msg = ""
                    }

    else
        \e -> Return.value { e | error_msg = eval.result }


store : Return Vector msg sub -> Return Vector msg sub
store return =
    return
        |> Return.event
            (return.value
                |> Json.fromVector
                |> Event.store
            )


check : Type -> Element -> Return Element msg sub
check solution e =
    { e
        | trial = e.trial + 1
        , solved = comp solution e.state
    }
        |> Return.value
