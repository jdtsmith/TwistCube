# TwistCube
An example Sketchup Ruby -> Dynamic Component interaction toy.


Creates a dynamic component, including one Component option "size" (the starting size of the cubes).  Responds to
Interact tool presses.  

This is only a small example illustrating how the DC framework can be reused in Ruby.  More careful variable encapsulation and a proper plugin architecture for loading/creating the (dynamic) component definition would be needed to make this readily distributable.

To load, open the Ruby Console and:
```
load "/path/to/twistcube.rb"
```
