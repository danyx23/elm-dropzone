module DropZone
  ( Model
  , Action(Drop)
  , isHovering
  , init
  , update
  , dropZoneEventHandlers
  ) where

{-| This library makes it easier to use Html5 Drag/Drop events when you want
to support dropping of files into a webpage. 

# Main DnD support
@docs dropZoneEventHandlers

# Drop action
@docs Action

# Model
@docs Model

# Helper functions
@docs init, update, isHovering
-}

import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json exposing (andThen)
import Effects exposing (Effects)

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
type alias Model = {
  hoverState: HoverState -- set to Hovering if the user is hovering with content over the drop zone
}

{-| Function that tells you if the user is currently hovering over the dropzone
with a Drag operation. 

This information is stored inside the model and thus
isHovering can only give you a correct information if you attached the event
handlers to the dropzone you render and make sure that Dropzone Actions are "routed"
to the update function of the DropZone

    getDropZoneAttributes : Signal.Address Action -> DropZone.Model -> List Html.Attribute
    getDropZoneAttributes address dropZoneModel =
        ( if (DropZone.isHovering dropZoneModel) then
            style [( "border", "3px dashed red")]
          else
            style [( "border", "3px dashed steelblue")]
        )
        ::
        dragDropEventHandlers (Signal.forwardTo address DnD)
-}
isHovering : Model -> Bool
isHovering model =
  model.hoverState == Hovering

{-| Initializes the Model
-}
init : Model
init = { hoverState = Normal }

-- UPDATE
{-| The Drop actions is tagged with a (List NativeFile) that represent the files
the user dropped onto the element. Handle this action in your code and do something
with the files.
-}
type Action a
    = DragEnter -- user enters the drop zone while dragging something
    | DragLeave -- user leaves drop zone
    | Drop a

{-| Updates the Model from an Action.
-}
update : Action a -> Model -> Model
update action model =
    case action of
        DragEnter ->
            {model | hoverState = Hovering }
        DragLeave ->
            {model | hoverState = Normal }
        Drop a ->
            {model | hoverState = Normal }

{-| Returns a list of Attributes to add to an element to turn it into a 
"Dropzone" by registering the required event handlers. 

The Json.Decoder you pass in is used to extract the data from the drop operation.
If the drop operation is a user dropping files in a browser, you will want to 
extract the .dataTransfer.files content. The FileReader project
( https://github.com/simonh1000/file-reader ) provides a convinience function 
`parseDroppedFiles` to do this for you.

    -- Example view, renders a div that acts as a dropzone by 
    -- adding the dragDropEventHandlers. Note that DropZoneAction 
    -- would be one of your components Actions, tagged with 
    -- the Action of the Dropzone. Since we pass just a dummy Json.value
    -- decoder, the Drop action will be tagged with this. A real example
    -- may want to use parseDroppedFiles
    view : Signal.Address Action -> Model -> Html
    view address model =
        div
        (  dropZoneStyle model.dropZoneModel 
        :: dragDropEventHandlers (Json.value) (Signal.forwardTo address DropZoneAction))    
        [ renderImageOrPrompt model
        ]
-}
dropZoneEventHandlers : (Json.Decoder a) -> Signal.Address (Action a) -> List Attribute
dropZoneEventHandlers decoder address =
    [ onDragEnter address DragEnter
    , onDragLeave address DragLeave
    , onDragOver address DragEnter
    , onDrop address decoder
    ]

-- Individual handler functions
onDragFunctionIgnoreFiles : String -> Signal.Address a -> a -> Attribute
onDragFunctionIgnoreFiles nativeEventName address action =
    onWithOptions
        nativeEventName
        {stopPropagation = False, preventDefault = True}
        Json.value
        (\_ -> Signal.message address action)

onDragFunctionDecodeFiles : String -> (Json.Decoder a) -> (a -> (Action a)) -> Signal.Address (Action a) -> Attribute
onDragFunctionDecodeFiles nativeEventName decoder actionCreator address =
    onWithOptions
        nativeEventName
        {stopPropagation = True, preventDefault = True}
        decoder
        (\vals -> Signal.message address (actionCreator vals))

onDragEnter : Signal.Address a -> a -> Attribute
onDragEnter =
  onDragFunctionIgnoreFiles "dragenter"

onDragOver : Signal.Address a -> a -> Attribute
onDragOver =
  onDragFunctionIgnoreFiles "dragover"

onDragLeave : Signal.Address a -> a -> Attribute
onDragLeave =
  onDragFunctionIgnoreFiles "dragleave"

onDrop : Signal.Address (Action a) -> (Json.Decoder a) -> Attribute
onDrop address decoder =
  onDragFunctionDecodeFiles "drop" decoder (\dropContent -> Drop dropContent) address
