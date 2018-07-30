module UpDown exposing (main)

import Html exposing (Html, div, text)
import Html.Attributes as Attributes
import Html.Events as Events
import Reference exposing (Reference)
import Reference.List


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( { todos =
            [ "foo"
            , "bar"
            , "baz"
            , "foobar"
            , "foobaz"
            , "barbaz"
            , "foobarbaz"
            ]
      }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { todos : List String
    }



-- UPDATE


type Msg
    = UpdateTodo (Reference ( UpDown, String ) (List String))


type UpDown
    = Up
    | Down
    | Retain


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateTodo ref ->
            ( { model
                | todos =
                    Reference.root ref
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] <|
            Reference.List.unwrap renderRow <|
                Reference.fromRecord
                    { this = List.map ((,) Retain) model.todos
                    , rootWith = flattenUpDown
                    }
        , div []
            [ text "Results:"
            , div [ Attributes.style [ ( "padding-left", "1em" ) ] ] <|
                List.map (\str -> div [] [ text str ]) model.todos
            ]
        ]


renderRow : Reference ( UpDown, String ) (List String) -> Html Msg
renderRow ref =
    div
        []
        [ Html.input
            [ Attributes.type_ "text"
            , Events.onInput (\str -> UpdateTodo <| Reference.modify (\_ -> ( Retain, str )) ref)
            , Attributes.value <| Tuple.second <| Reference.this ref
            ]
            []
        , Html.button
            [ Attributes.type_ "button"
            , Events.onClick (UpdateTodo <| Reference.modify (Tuple.mapFirst (\_ -> Up)) ref)
            ]
            [ text "△"
            ]
        , Html.button
            [ Attributes.type_ "button"
            , Events.onClick (UpdateTodo <| Reference.modify (Tuple.mapFirst (\_ -> Down)) ref)
            ]
            [ text "▽"
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Helper functions


{-| Reordering by `UpDown` notation and flatten to the bare list.
-}
flattenUpDown : List ( UpDown, a ) -> List a
flattenUpDown =
    -- It is guaranteed only one Up/Down in the list at most.
    List.map Tuple.second << reorderUp << reorderDown


reorderUp : List ( UpDown, a ) -> List ( UpDown, a )
reorderUp =
    List.foldr
        (\a ( mb, ls ) ->
            case ( mb, a ) of
                ( Just b, _ ) ->
                    ( Nothing, b :: a :: ls )

                ( Nothing, ( Up, _ ) ) ->
                    ( Just a, ls )

                ( Nothing, _ ) ->
                    ( Nothing, a :: ls )
        )
        ( Nothing, [] )
        >> \( ma, ls ) ->
            case ma of
                Just a ->
                    a :: ls

                Nothing ->
                    ls


reorderDown : List ( UpDown, a ) -> List ( UpDown, a )
reorderDown =
    List.foldl
        (\a ( mb, dls ) ->
            case ( mb, a ) of
                ( Just b, _ ) ->
                    ( Nothing, dls << ((::) a) << ((::) b) )

                ( Nothing, ( Down, _ ) ) ->
                    ( Just a, dls )

                ( Nothing, _ ) ->
                    ( Nothing, dls << ((::) a) )
        )
        ( Nothing, identity )
        >> \( ma, dls ) ->
            case ma of
                Just a ->
                    (dls << ((::) a)) []

                Nothing ->
                    dls []