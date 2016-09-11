This directory contains a simple example that shows how to use DropZone together with
the (File Reader)[https://github.com/simonh1000/file-reader] library to provide a dropzone,
read the dropped files as text and display the contents.

For this example to work you need to have a copy of simonh1000/filereader
in this 'examples' directory. Since filereader has not passed native review as of writing this,
you need to directly clone the filereader repository into this directory. The elm-package.json
is already configured to look for the source of filereader inside this directory.

Note that at the time of writing (Mid September 2016), simonh1000/fileraeder has not yet merged
the updates to 0.17 to mainline. Meanwhile, you can use e.g. this fork: https://github.com/jtojnar/file-reader.

To clone, please run this command from inside the examples directory:
```
git clone https://github.com/simonh1000/file-reader
```
