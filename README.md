#Elm Dropzone

Provides helpers to make it easy to add a "dropzone" into a webapp and pass the the dropped files onto the [FileReader library](https://github.com/simonh1000/file-reader) to read.

The library does not yet have a dependency on FileReader because FileReader has not passed native review yet. At the moment using it with FileReader is the primary intended use case.

A full example of how to use this library is provided in the examples folder. Please note that you have to clone the filereader library manually into the examples folder. 

There are 3 basic steps to get DropZone working in your application:

### Store the DropZone.Model as part of your model

```elm
type alias Model =
    { dropZone : DropZone.Model -- this is the dropzone model you need to store
    , ... -- other parts of your model
    }

init : Model
init =
    { dropZone = DropZone.init
    , ... -- init other parts 
    }
```

### Update the DropZone.Model as part of your update function
```elm
type Action
    = DropZoneAction (DropZone.Action (List FileReader.NativeFile)) 
    | .. -- other actions

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        -- Drop is the only action that you will want to handle yourself as well
        DropZoneAction (Drop files) -> 
            ( { model -- Make sure to update the DropZone model
              | dropZone = DropZone.update (Drop files) model.dropZone   
              , .. -- maybe store the files in your own model
              }
            , Effects.batch <|
                List.map (readTextFile << .blob) files 
              -- in this example the dropped files are all read 
              -- with FileReader.readTextFile
            )
        DropZoneAction a ->  
            -- These are the other DropZone actions that are not exposed, 
            -- but you still need to hand it to DropZone.update so 
            -- the DropZone model stays consistent
            ( { model | dropZone = DropZone.update a model.dropZone }
            , Effects.none
            )
        .. -- other action handling here
```
### Render the view for your dropzone

Here the important thing is that you are in full control of rendering your dropzone. All you need
to do to make sure it works as a DropZone is add the attributes you get from a call to
dropZoneEventHandlers. If you like you can use the isHovering method to render your dropzone
differently when the user is hovering over it with a DnD operation.

dropZoneEventHandlers takes a Json.decoder to extract the "payload" from the native JS drop event.
We use the FileReader.parseDroppedFiles here to extract a List of native JS File objects.

```elm
-- Write a function that renders your dropzone and use dropzoneEventHandlers to 
-- turn it into a dropzone. 
dropZoneView : Signal.Address Action -> Model -> Html
dropZoneView address model =
    div 
      ( (hoveringDependentStyles model.dropZoneModel)
      :: dropZoneEventHandlers FileReader.parseDroppedFiles (Signal.forwardTo address DnD))
      []

hoveringDependentStyles : DropZone.Model -> Html.Attribute
hoveringDependentStyles dropZoneModel =
  if (DropZone.isHovering dropZoneModel) then
    style [( "border", "3px dashed red")]
  else
    style [( "border", "3px dashed steelblue")]
```

by Daniel Bachler, Simon Hampton