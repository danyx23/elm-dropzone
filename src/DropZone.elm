{-
Based on original code from Daniel Bachler (danyx23)
-}

module DragDrop
  ( HoverState(..)
  , Action(Drop)
  , init
  , update
  , dragDropEventHandlers
  ) where

{-| This library makes it easier to use Html5 Drag/Drop events when you want
to support dropping of files into the webpage. 

# Main DnD support
@docs dragDropEventHandlers

# Drop action
@docs Action

# HoverState
@docs HoverState

# Helper functions
@docs, init, update
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

type alias Model = HoverState -- set to Hovering if the user is hovering with content over the drop zone

{-| Initializes the HoverState to Normal
-}
init : Model
init = Normal

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
            Hovering
        DragLeave ->
            Normal
        Drop files ->
            Normal

{-| Returns a list of Attributes to add to an element to turn it into a 
"Drpozone". 

    -- Example view, renders a div that acts as a dropzone by 
    -- adding the dragDropEventHandlers
    view : Signal.Address Action -> Model -> Html
    view address model =
        div
        (  dropZoneStyle model.hoverState 
        :: dragDropEventHandlers (Signal.forwardTo address DnD))    
        [ renderImageOrPrompt model
        ]
-}
dragDropEventHandlers : Signal.Address Action -> List Attribute
dragDropEventHandlers address =
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
