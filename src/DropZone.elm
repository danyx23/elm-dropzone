module DropZone
    exposing
        ( Model
        , DropZoneMessage(Drop)
        , isHovering
        , init
        , update
        , dropZoneEventHandlers
        )

{-| This library makes it easier to use Html5 Drag/Drop events when you want
to support dropping of files into a webpage.


# Main DnD support

@docs dropZoneEventHandlers


# Drop action

@docs DropZoneMessage


# Model

@docs Model


# Helper functions

@docs init, update, isHovering

-}

import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json exposing (andThen, map)


-- MODEL


{-| Indicates if the user is hovering over the element. Can be used to change the
styling of the Dropzone when the user is dragging something on top of it. Possible
states are Normal and Hovering.

    case hoverState of
        Normal ->
          text "Drag files here"
        Hovering ->
          text "Yes, drop them now!"

-}
type HoverState
    = Normal
    | Hovering


{-| Opaque model of the DropZone.
-}
type alias Model =
    { hoverState :
        HoverState

    -- set to Hovering if the user is hovering with content over the drop zone
    }


{-| Function that tells you if the user is currently hovering over the dropzone
with a Drag operation.

This information is stored inside the model and thus
isHovering can only give you a correct information if you attached the event
handlers to the dropzone you render and make sure that Dropzone DropZoneMessages are "routed"
to the update function of the DropZone

    getDropZoneAttributes : DropZone.Model -> List Html.Attribute msg
    getDropZoneAttributes dropZoneModel =
        ( if (DropZone.isHovering dropZoneModel) then
            style [( "border", "3px dashed red")]
          else
            style [( "border", "3px dashed steelblue")]
        )
        ::
        dragDropEventHandlers payloadDecoder)

-}
isHovering : Model -> Bool
isHovering model =
    model.hoverState == Hovering


{-| Initializes the Model
-}
init : Model
init =
    { hoverState = Normal }



-- UPDATE


{-| The Drop actions is usually tagged with a (List NativeFile) that represent the files
the user dropped onto the element. Handle this action in your code and do something
with the files.
-}
type DropZoneMessage a
    = DragEnter
      -- user enters the drop zone while dragging something
    | DragLeave
      -- user leaves drop zone
    | Drop a


{-| Updates the Model from a DropZoneMessage.
-}
update : DropZoneMessage msg -> Model -> Model
update action model =
    case action of
        DragEnter ->
            { model | hoverState = Hovering }

        DragLeave ->
            { model | hoverState = Normal }

        Drop msg ->
            { model | hoverState = Normal }


{-| Returns a list of Attributes to add to an element to turn it into a
"Dropzone" by registering the required event handlers.

The Json.Decoder you pass in is used to extract the data from the drop operation.
If the drop operation is a user dropping files in a browser, you will want to
extract the .dataTransfer.files content. The FileReader project
( <https://github.com/simonh1000/file-reader> ) provides a convinience function
`parseDroppedFiles` to do this for you.

    view : Message -> Model -> Html
    view address model =
        div
            (dropZoneStyle model.dropZoneModel
                :: dragDropEventHandlers (Json.value)
            )
            [ renderImageOrPrompt model
            ]

-}
dropZoneEventHandlers : Json.Decoder msg -> List (Attribute (DropZoneMessage msg))
dropZoneEventHandlers decoder =
    [ onDragEnter DragEnter
    , onDragLeave DragLeave
    , onDragOver DragEnter
    , onDrop decoder
    ]



-- Individual handler functions


onDragFunctionIgnoreFiles : String -> msg -> Attribute msg
onDragFunctionIgnoreFiles nativeEventName action =
    onWithOptions nativeEventName
        { stopPropagation = False, preventDefault = True }
        (Json.succeed action)


onDragFunctionDecodeFiles : String -> Json.Decoder (DropZoneMessage msg) -> Attribute (DropZoneMessage msg)
onDragFunctionDecodeFiles nativeEventName decoder =
    onWithOptions nativeEventName
        { stopPropagation = True, preventDefault = True }
        decoder


onDragEnter : msg -> Attribute msg
onDragEnter =
    onDragFunctionIgnoreFiles "dragenter"


onDragOver : msg -> Attribute msg
onDragOver =
    onDragFunctionIgnoreFiles "dragover"


onDragLeave : msg -> Attribute msg
onDragLeave =
    onDragFunctionIgnoreFiles "dragleave"


onDrop : Json.Decoder msg -> Attribute (DropZoneMessage msg)
onDrop decoder =
    onDragFunctionDecodeFiles "drop" (map (\userVal -> Drop userVal) decoder)
