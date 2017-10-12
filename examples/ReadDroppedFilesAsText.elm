module Main exposing (..)

import DropZone exposing (DropZoneMessage(Drop), dropZoneEventHandlers, isHovering)
import FileReader exposing (Error(..), FileRef, NativeFile, readAsTextFile)
import Html exposing (Html, button, div, h1, input, p, text)
import Html.Attributes exposing (id, style, type_)
import Task


{- Attention! For this example to work you need to have a copy of simonh1000/filereader
   in this directory. Since filereader has not passed native review as of writing this,
   you need to directly clone the filereader repository into this directory. The elm-package.json
   is already configured to look for the source of filereader inside this directory.

   To clone, please run this command from inside the examples directory:
   git clone https://github.com/simonh1000/file-reader

   This example was adapted from Simon Hamptons example in the file-reader library.
-}
-- MODEL


type alias Model =
    { message : String
    , dropZone :
        DropZone.Model

    -- store the DropZone model in your apps Model
    , files : List NativeFile
    , contents : List String
    }


init : Model
init =
    { message = "Waiting..."
    , dropZone =
        DropZone.init

    -- call DropZone.init to initialize
    , files = []
    , contents = []
    }



-- UPDATE


type Message
    = DnD (DropZone.DropZoneMessage (List NativeFile))
      -- add an Message that takes care of hovering, dropping etc
    | FileReadSucceeded String
    | FileReadFailed FileReader.Error


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        DnD (Drop files) ->
            -- this happens when the user dropped something into the dropzone
            ( { model
                | dropZone =
                    DropZone.update (Drop files) model.dropZone

                -- update the DropZone model
                , files =
                    files

                -- and store the dropped files
              }
            , Cmd.batch <|
                -- also create a bunch of effects to read the files as text, one effect for each file
                List.map (readTextFile << .blob) files
            )

        DnD a ->
            -- these are opaque DropZone messages, just hand them to DropZone to deal with them
            ( { model | dropZone = DropZone.update a model.dropZone }
            , Cmd.none
            )

        FileReadSucceeded str ->
            -- this happens when an effect has finished and the file has successfully been loaded
            ( { model
                | contents = str :: model.contents
                , message = "Successfully loaded at least one file"
              }
            , Cmd.none
            )

        FileReadFailed err ->
            -- this happens when an effect has finished and there was an error loading hte file
            ( { model | message = FileReader.prettyPrint err }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Message
view model =
    div [ containerStyles ]
        [ h1 [] [ text "Drag 'n Drop" ]
        , renderDropZone model.dropZone

        -- render the dropzone
        , div []
            -- list the files that were dropped
            [ text <| "Files: " ++ commaSeparate (List.map .name model.files)
            ]
        , div [] <|
            -- and the contents
            [ text <| "Content: " ++ commaSeparate model.contents ]
        , p [] [ text model.message ]
        ]


commaSeparate : List String -> String
commaSeparate lst =
    List.foldl (++) "" (List.intersperse ", " lst)


renderDropZone : DropZone.Model -> Html Message
renderDropZone dropZoneModel =
    Html.map DnD
        (div (renderZoneAttributes dropZoneModel) [])


renderZoneAttributes :
    DropZone.Model
    -> List (Html.Attribute (DropZoneMessage (List NativeFile)))
renderZoneAttributes dropZoneModel =
    (if DropZone.isHovering dropZoneModel then
        dropZoneHover
        -- style the dropzone differently depending on whether the user is hovering
     else
        dropZoneDefault
    )
        :: -- add the necessary DropZone event wiring
           dropZoneEventHandlers FileReader.parseDroppedFiles


containerStyles : Html.Attribute a
containerStyles =
    style [ ( "padding", "20px" ) ]


dropZoneDefault : Html.Attribute a
dropZoneDefault =
    style
        [ ( "height", "120px" )
        , ( "border-radius", "10px" )
        , ( "border", "3px dashed steelblue" )
        ]


dropZoneHover : Html.Attribute a
dropZoneHover =
    style
        [ ( "height", "120px" )
        , ( "border-radius", "10px" )
        , ( "border", "3px dashed red" )
        ]



-- TASKS


readTextFile : FileRef -> Cmd Message
readTextFile fileValue =
    readAsTextFile fileValue
        |> Task.attempt
            (\res ->
                case res of
                    Ok val ->
                        FileReadSucceeded val

                    Err error ->
                        FileReadFailed error
            )



-- ----------------------------------


app : Program Never Model Message
app =
    Html.program
        { init = ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


main : Program Never Model Message
main =
    app
