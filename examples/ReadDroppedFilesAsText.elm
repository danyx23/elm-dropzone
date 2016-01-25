import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type', id, style)
import Html.Events exposing (onClick, on)
import StartApp
import Effects exposing (Effects)
import Task
import Json.Decode as Json exposing (Value, andThen)
import FileReader exposing (FileRef, NativeFile, readAsTextFile, Error(..))
import DropZone exposing (Action(Drop), dropZoneEventHandlers, isHovering)
import MimeType exposing (MimeType(Text))

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
    , dropZone : DropZone.Model -- store the DropZone model in your apps Model
    , files : List NativeFile
    , contents : List String
    }

init : Model
init =
    { message = "Waiting..."
    , dropZone = DropZone.init -- call DropZone.init to initialize
    , files = []
    , contents = []
    }

-- UPDATE

type Action
    = DnD (DropZone.Action (List NativeFile)) -- add an Action that takes care of hovering, dropping etc
    | FileData (Result FileReader.Error String)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        DnD (Drop files) -> -- this happens when the user dropped something into the dropzone
            ( { model
              | dropZone = DropZone.update (Drop files) model.dropZone -- update the DropZone model 
              , files = files -- and store the dropped files
              }
            , Effects.batch <| -- also create a bunch of effects to read the files as text, one effect for each file
                List.map (readTextFile << .blob) files
            )
        DnD a -> -- these are opaque DropZone actions, just hand them to DropZone to deal with them
            ( { model | dropZone = DropZone.update a model.dropZone }
            , Effects.none
            )

        FileData (Result.Ok str) -> -- this happens when an effect has finished and the file has successfully been loaded
            ( { model 
                  | contents = str :: model.contents
                  , message = "Successfully loaded at least one file" 
              }
            , Effects.none
            )

        FileData (Result.Err err) -> -- this happens when an effect has finished and there was an error loading hte file
            ( { model | message = FileReader.toString err }
            , Effects.none
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ containerStyles ]
        [ h1 [] [ text "Drag 'n Drop" ]
        , renderDropZone address (model.dropZone) -- render the dropzone
        , div
            [] -- list the files that were dropped
            [ text <| "Files: " ++ commaSeparate (List.map .name model.files)
            ]
        , div
            [] <| -- and the contents
            [ text <| "Content: " ++ commaSeparate model.contents ]
        , p [] [ text model.message ]
        ]

commaSeparate : List String -> String
commaSeparate lst =
    List.foldl (++) "" (List.intersperse ", " lst)

renderDropZone :  Signal.Address Action -> DropZone.Model -> Html
renderDropZone address dropZoneModel =
  div
    (renderZoneAttributes address dropZoneModel)
    []

renderZoneAttributes :  Signal.Address Action -> DropZone.Model -> List Html.Attribute
renderZoneAttributes address dropZoneModel =
    ( if DropZone.isHovering dropZoneModel then
        dropZoneHover -- style the dropzone differently depending on whether the user is hovering
      else
        dropZoneDefault          
    )
    ::
    -- add the necessary DropZone event wiring 
    dropZoneEventHandlers FileReader.parseDroppedFiles (Signal.forwardTo address DnD)

containerStyles =
    style [ ( "padding", "20px") ]
    
dropZoneDefault =
    style
        [ ( "height", "120px")
        , ( "border-radius", "10px")
        , ( "border", "3px dashed steelblue")
        ]
        
dropZoneHover =
    style
        [ ( "height", "120px")
        , ( "border-radius", "10px")
        , ( "border", "3px dashed red")
        ]

-- TASKS

readTextFile : FileRef -> Effects Action
readTextFile fileValue =
    readAsTextFile fileValue
        |> Task.toResult
        |> Task.map FileData
        |> Effects.task

-- ----------------------------------
app =
    StartApp.start
        { init = (init, Effects.none)
        , update = update
        , view = view
        , inputs = []
        }

main =
    app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks =
    app.tasks
