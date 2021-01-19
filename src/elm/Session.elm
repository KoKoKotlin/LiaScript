module Session exposing
    ( Screen
    , Session
    , Type(..)
    , getType
    , load
    , navTo
    , navToHome
    , navToSlide
    , setQuery
    , setScreen
    , setUrl
    )

{-| This module covers all relevant session functions/data that deal with
URL-navigation. Therefor all relevant information is stored and updated with the
`Session` record, a unique repository, that is passed on between modules.
-}

import Browser.Navigation as Navigation
import Url exposing (Url)


{-| This record encapsulates all relevant session information, that is not
handled directly by LiaScript:

  - **share**: does the Browser posses a Navigation.share API
  - **key**: the "elm" navigation key
  - **screen**: the current screen size
  - **url**: the current url, commonly only the course-parameter `?` gets
    updated and the fragment `#`. No query-parameter indicate that the course
    index should be displayed.

-}
type alias Session =
    { share : Bool
    , key : Navigation.Key
    , screen : Screen
    , url : Url
    }


{-| Current display size...
-}
type alias Screen =
    { width : Int
    , height : Int
    }


{-| At the moment there are only two types of modes of presentations, either
a `Course ReadMeURL slideNumber` is rendered or and `Index` of all
visited/stored courses. In most cases this state of representation is also
defined by the url:

`http://lia.../?ReadMeURL#slideNumber`

If this information is present, then it is a course otherwise the index.

-}
type Type
    = Index
    | Course String Int


{-| Update the entire session-URL.

> In most case this is used only to update the query parameter (`?course-URL`)
> or the fragment (`#slideNumber`). All other parameters should not be touched.

-}
setUrl : Url -> Session -> Session
setUrl url session =
    { session | url = url }


{-| Update the query and thus, the current `?course-URL`.
-}
setQuery : String -> Session -> Session
setQuery query session =
    let
        url =
            session.url
    in
    { session | url = { url | query = Just query } }


navTo : Session -> Url -> Cmd msg
navTo session =
    Url.toString >> Navigation.pushUrl session.key


load : Url -> Cmd msg
load =
    Url.toString >> Navigation.load


{-| A shortcut for going to the Index-page, by simply deleting the URL query and
fragment.
-}
navToHome : Session -> Cmd msg
navToHome session =
    let
        url =
            session.url
    in
    { url | query = Nothing, fragment = Nothing }
        |> navTo session


{-| A shortcut for changeing the fragment number, which replicates the current
slideNumber.
-}
navToSlide : Session -> Int -> Cmd msg
navToSlide session id =
    let
        url =
            session.url
    in
    { url | fragment = Just <| String.fromInt (1 + id) }
        |> navTo session


{-| Parse the URL-query and fragment. If no query-string is present the Index
type is deduced, otherwise the Course type.
-}
getType : Url -> Type
getType url =
    case url.query of
        Just str ->
            url.fragment
                |> Maybe.andThen String.toInt
                |> Maybe.withDefault 1
                |> (+) -1
                |> Course str

        Nothing ->
            Index


{-| Update the screen size.
-}
setScreen : Screen -> Session -> Session
setScreen size session =
    { session | screen = size }
