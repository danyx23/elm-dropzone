module DropZone
  ( Model
  , Action(Drop)
  , isHovering
  , init
  , update
  , dropZoneEventHandlers
  ) where

{-| This library makes it easier to use Html5 Drag/Drop events when you want
to support dropping of files into the webpage. 

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

import FileReader exposing (parseDroppedFiles, NativeFile)

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
            dropZoneDefault
          else
            dropZoneHover
        )
        ::
        dragDropEventHandlers (Signal.forwardTo address DnD)
-}
isHovering : Model -> Bool
isHovering model =
  model.hoverState == Hovering

{-| Initializes the HoverState to Normal
-}
init : Model
init = { hoverState = Normal }

-- UPDATE
{-| The Drop actions is tagged with a (List NativeFile) that represent the files
the user dropped onto the element. Handle this action in your code and do something
with the files.
-}
type Action
    = DragEnter -- user enters the drop zone while dragging something
    | DragLeave -- user leaves drop zone
    | Drop (List NativeFile)

{-| Simple update method that updates the HoverState from an Action.
-}
update : Action -> Model -> Model
update action model =
    case action of
        DragEnter ->
            {model | hoverState = Hovering }
        DragLeave ->
            {model | hoverState = Normal }
        Drop files ->
            {model | hoverState = Normal }

{-| Returns a list of Attributes to add to an element to turn it into a 
"Drpozone" by registering the required event handlers.

    -- Example view, renders a div that acts as a dropzone by 
    -- adding the dragDropEventHandlers. Note that DropZoneAction 
    -- would be one of your components Actions, tagged with 
    -- the Action of the Dropzone
    view : Signal.Address Action -> Model -> Html
    view address model =
        div
        (  dropZoneStyle model.dropZoneModel 
        :: dragDropEventHandlers (Signal.forwardTo address DropZoneAction))    
        [ renderImageOrPrompt model
        ]
-}
dropZoneEventHandlers : Signal.Address Action -> List Attribute
dropZoneEventHandlers address =
    [ onDragEnter address DragEnter
    , onDragLeave address DragLeave
    , onDragOver address DragEnter
    , onDrop address
    ]

-- Individual handler functions
onDragFunctionIgnoreFiles : String -> Signal.Address a -> a -> Attribute
onDragFunctionIgnoreFiles nativeEventName address action =
    onWithOptions
        nativeEventName
        {stopPropagation = False, preventDefault = True}
        Json.value
        (\_ -> Signal.message address action)

onDragFunctionDecodeFiles : String -> (List NativeFile -> Action) -> Signal.Address Action -> Attribute
onDragFunctionDecodeFiles nativeEventName actionCreator address =
    onWithOptions
        nativeEventName
        {stopPropagation = True, preventDefault = True}
        parseDroppedFiles
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

onDrop : Signal.Address Action -> Attribute
onDrop address =
  onDragFunctionDecodeFiles "drop" (\files -> Drop files) address
