module Lia.Markdown.Quiz.View exposing
    ( class
    , showSolution
    , view
    )

{-| This module defines the basic frame for all subsequent and specialized
quizzes. It adds a common checkButton, hintButton, and resolveButton and shows
hints.

TODO:

  - Add translations for web accessability also:
    1.  check: check the solution of the current quiz
    2.  reveal: reveal the solution of the quiz
    3.  show hint: show an hint
    4.  state:
          - open: the quiz has not been touched yet
          - resolved: resolved quiz
          - solved: solved quiz

-}

import Accessibility.Aria as A11y_Aria
import Accessibility.Role as A11y_Role
import Accessibility.Widget as A11y_Widget
import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Lia.Markdown.Inline.Config exposing (Config)
import Lia.Markdown.Inline.Types exposing (Inlines)
import Lia.Markdown.Inline.View exposing (viewer)
import Lia.Markdown.Quiz.Block.View as Block
import Lia.Markdown.Quiz.Matrix.View as Matrix
import Lia.Markdown.Quiz.Solution as Solution exposing (Solution)
import Lia.Markdown.Quiz.Types
    exposing
        ( Element
        , Quiz
        , State(..)
        , Type(..)
        , Vector
        , getClass
        , getState
        , isSolved
        )
import Lia.Markdown.Quiz.Update exposing (Msg(..))
import Lia.Markdown.Quiz.Vector.View as Vector
import Lia.Utils exposing (btn, btnIcon)
import Translations
    exposing
        ( Lang
        , quizAnswerError
        , quizAnswerResolved
        , quizAnswerSuccess
        , quizCheck
        , quizLabelCheck
        , quizLabelSolution
        , quizSolution
        )


{-| Main Quiz view function.
-}
view : Config sub -> Maybe String -> Quiz -> Vector -> ( Maybe Int, List (Html (Msg sub)) )
view config labeledBy quiz vector =
    case getState vector quiz.id of
        Just elem ->
            ( elem.scriptID
            , viewState config elem quiz
                |> viewQuiz config labeledBy elem quiz
            )

        _ ->
            ( Nothing, [] )


{-| Determine the quiz class based on the current state
-}
class : Int -> Vector -> String
class id vector =
    getState vector id
        |> Maybe.map (\s -> "lia-quiz-" ++ getClass s.state ++ " " ++ Solution.toString s.solved)
        |> Maybe.withDefault ""
        |> (++) "lia-quiz "


{-| **private:** Simple router function that is used to match the current state
of a quiz with its type.
-}
viewState : Config sub -> Element -> Quiz -> ( List (Attribute (Msg sub)), List (Html (Msg sub)) )
viewState config elem quiz =
    case ( elem.state, quiz.quiz ) of
        ( Block_State s, Block_Type q ) ->
            ( []
            , s
                |> Block.view config ( elem.solved, elem.trial ) q
                |> List.map (Html.map (Block_Update quiz.id))
            )

        ( Vector_State s, Vector_Type q ) ->
            s
                |> Vector.view config
                    (elem.solved == Solution.Open)
                    (Solution.toClass ( elem.solved, elem.trial ))
                    q
                |> Tuple.mapSecond (List.map (Html.map (Vector_Update quiz.id)))

        ( Matrix_State s, Matrix_Type q ) ->
            ( []
            , [ s
                    |> Matrix.view config
                        (elem.solved == Solution.Open)
                        (Solution.toClass ( elem.solved, elem.trial ))
                        q
                    |> Html.map (Matrix_Update quiz.id)
              ]
            )

        _ ->
            ( [], [] )


{-| **private:** Return the current quiz as List of elements that contains:

1.  maybe an error message (that originates from the external application of
    JavaScript)
2.  the body of the quiz itself, which might be of type `Block`, `Vector`, or
    `Matrix`
3.  the main check-button
4.  a button that reveals the solution 5 a hint section, that contains a hint
    button and a list of already revealed hints

-}
viewQuiz : Config sub -> Maybe String -> Element -> Quiz -> ( List (Attribute (Msg sub)), List (Html (Msg sub)) ) -> List (Html (Msg sub))
viewQuiz config labeledBy state quiz ( attr, body ) =
    [ Html.div
        (Attr.class "lia-quiz__answers"
            :: (labeledBy
                    |> Maybe.map A11y_Aria.labelledBy
                    |> Maybe.withDefault (Attr.class "")
               )
            :: attr
        )
        body
    , Html.div [ Attr.class "lia-quiz__control" ]
        [ viewMainButton config state.trial state.solved (Check quiz.id quiz.quiz)
        , viewSolutionButton config state.solved (ShowSolution quiz.id quiz.quiz)
        , Translations.quizHint config.lang
            |> viewHintButton quiz.id (quiz.hints /= []) (Solution.Open == state.solved && state.hint < List.length quiz.hints)
        ]
    , viewFeedback config.lang state
    , viewHints config state.hint quiz.hints
    ]


viewFeedback : Lang -> Element -> Html msg
viewFeedback lang state =
    if state.error_msg /= "" then
        Html.div [ Attr.class "lia-quiz__feedback text-error" ]
            [ Html.text state.error_msg
            ]

    else
        case state.solved of
            Solution.Solved ->
                Html.div [ Attr.class "lia-quiz__feedback text-success" ]
                    -- TODO: maybe lable success, failure, ... locale independend
                    [ lang
                        |> quizAnswerSuccess
                        |> Html.text
                    ]

            Solution.ReSolved ->
                Html.div [ Attr.class "lia-quiz__feedback text-disabled" ]
                    [ lang
                        |> quizAnswerResolved
                        |> Html.text
                    ]

            Solution.Open ->
                if state.trial == 0 then
                    Html.text ""

                else
                    Html.div [ Attr.class "lia-quiz__feedback text-error" ]
                        [ lang
                            |> quizAnswerError
                            |> Html.text
                        ]


{-| **private:** Show the solution button only if the quiz has not been solved
yet.
-}
viewSolutionButton : Config sub -> Solution -> Msg sub -> Html (Msg sub)
viewSolutionButton config solution msg =
    btnIcon
        { title = quizSolution config.lang
        , msg =
            if solution == Solution.Open then
                Just msg

            else
                Nothing
        , tabbable = True
        , icon = "icon-resolve"
        }
        [ Attr.class "lia-btn--transparent lia-quiz__resolve", A11y_Widget.label (quizLabelSolution config.lang) ]


{-| **private:** Show the main check-button to compare the current state of the
quiz with the solution state. The number of trials is automatically added.
-}
viewMainButton : Config sub -> Int -> Solution -> Msg sub -> Html (Msg sub)
viewMainButton config trials solution msg =
    btn
        { title = ""
        , msg =
            if solution == Solution.Open then
                Just msg

            else
                Nothing
        , tabbable = solution == Solution.Open
        }
        [ Attr.class "lia-btn--outline lia-quiz__check", A11y_Widget.label (quizLabelCheck config.lang) ]
        [ Html.text (quizCheck config.lang)
        , Html.text <|
            if trials > 0 then
                " " ++ String.fromInt trials

            else
                ""
        ]


{-| **private:** If hints have been added to the quiz by `[[?]]` these will
shown within a list and an additional button will be displayed to reveal more
hints, if there are still hints not shown to the user and if the quiz has not
been solved yet.
-}
viewHints : Config sub -> Int -> List Inlines -> Html (Msg sub)
viewHints config counter hints =
    if List.isEmpty hints then
        Html.text ""

    else
        hints
            |> List.take counter
            |> List.map (viewer config >> Html.li [])
            |> Html.ul [ Attr.class "lia-list--unordered lia-quiz__hints" ]
            |> Html.map Script


{-| **private:** Show a generic hint button, every time it is clicked it will
reveal another hint from the list.
-}
viewHintButton : Int -> Bool -> Bool -> String -> Html (Msg sub)
viewHintButton id show active title =
    if show then
        btnIcon
            { title = title
            , msg =
                if active then
                    Just (ShowHint id)

                else
                    Nothing
            , icon = "icon-hint"
            , tabbable = True
            }
            [ Attr.class "lia-btn--transparent lia-quiz__hint", A11y_Role.button ]

    else
        Html.text ""


{-| Check the state of quiz:

    Open -> False

    Solved -> True

    Resolved -> True

-}
showSolution : Vector -> Quiz -> Bool
showSolution vector quiz =
    quiz.id
        |> getState vector
        |> Maybe.map isSolved
        |> Maybe.withDefault False
