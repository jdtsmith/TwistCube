# TwistCube: A "Dynamic Component to Ruby and Back Again" interaction
# example.  Creates a dynamic component, including one Component
# option "size" (the starting size of the cubes).  Responds to
# Interact tool presses.  Copyright 2020, J.D. Smith MIT License
#
# This is only a small example illustrating how the DC framework can
# be reused in Ruby.  More careful variable encapsulation and a proper
# plugin architecture for loading/creating the (dynamic) component
# definition would be needed to make this readily distributable.
#
# To load, open the Ruby Console and
#  load "/path/to/twistcube.rb"



$size=100 # Initial cube size


# This observer watches the "dynamic_attributes" attribute dictionary
# (which is itself an entity).  It looks for changes either to the one
# option ("size") or to the "touched" attribute that signifies an
# interaction has occurred, after which it enables an animation via
# the TwistAnimation class and its "nextFrame" method.
class DCObserver < Sketchup::EntityObserver
  def initialize
    @touched=0
    @animator=TwistAnimation.new
  end
  
  def onEraseEntity(entity)
    puts "Entity Erased!"
  end
  
  def onChangeEntity(entity)    # changes to the dynamic_attributes dictionary
    return if entity.deleted?
    if @touched != entity["_touched"].to_i # Touch statechanged
      @touched=entity["_touched"].to_i
      @animator.start(@touched==1)
      $active.active_view.animation = @animator
    elsif $size != entity["size"].to_i # size changes
      $size=entity["size"].to_i
      puts "Size changed to #{$size}"
      build_component $size
    end
  end
end

# This blesses a given component instance as a dynamic component,
# gives it a and returns the new "dynamic_attributes" attribute
# dictionary that makes a component instance dynamic, and adds a
# "_touched" attribute to track interactions.
def initDynamicComponent(entity)
  entity.set_attribute "dynamic_attributes","_formatversion",1.0
  da=entity.attribute_dictionary("dynamic_attributes")
  da["onclick"]="Animate(_touched,0,1)"
  da["_touched"]="0"
  return da
end

# This adds dynamic attributes, with units, labels, etc.  DATTR is the
# dynamic attribute dictionary (as returned for example by
# initDynamicComponent)
def addDynamicAttribute(dattr,attribute, value, units: "INCHES",access: false)
  dattr[attribute]=value
  dattr["_"+attribute+"_label"]=attribute
  if access
    dattr["_"+attribute+"_access"]="TEXTBOX" 
    dattr["_"+attribute+"_formlabel"]=attribute
  end 
  ["","formula"].each{|x| dattr["_"+attribute+"_"+x+"units"]=units}
end

# For this example our interaction will animate over 64 steps, but
# instead of just altering each COPY (from DC parlance), it will
# create (on first interact) and then destroy (on 2nd) new copies
# sequentially.
class TwistAnimation
  MAXSTEPS=64 
  def initialize()
    @cubes=[]
  end

  def start(forward)
    @forward=forward
    @steps = 0
    @zoff=$size
    print "NEW TWIST WITH DIRECTION: ",(@forward and "forward" or "reverse"),"\n"
  end

  def reset
    $group.entities.erase_entities @cubes unless @cubes.empty?
    @steps=0
  end
  
  def nextFrame(view)
    if @forward                 # Build a spiral upwards
      @steps+=1
      frac = @steps.to_f/MAXSTEPS
      sfrac=(1.-frac)*0.8 + 0.2 # 20% cube size at minimum
      tform=Geom::Transformation.rotation(ORIGIN,Geom::Vector3d.new(0,0,1),
                                          frac*8*Math::PI) # 4  orbits
      movex=2.5*frac*$size * Math::sin(frac*Math::PI) # closer, further, closer
      tform*=Geom::Transformation.translation(Geom::Vector3d.new(movex,0,@zoff))
      newcube = $group.entities.add_instance($component, tform)
      center = newcube.definition.bounds.center # to scale about center!
      newcube.transformation *= Geom::Transformation.scaling(center, sfrac)
      @zoff+=sfrac*$size        # z offset for the next guy
      view.show_frame
      @cubes.push newcube
      return @steps < MAXSTEPS
    else                        # Unwind the spiral!
      @cubes.pop.erase!
      return !@cubes.empty?
    end
  end
end

print "Dynamic Component Ruby Interface Example: TwistCube\n\n"
$active=Sketchup.active_model

# Create a Cube component definition
$component = $active.definitions.add("TwistCube");

def build_component(size)
  $component.entities.erase_entities($component.entities.to_a) # erase any pre-existing entities
  points = Array.new  
  points[0] = ORIGIN 
  points[1] = [size, 0 , 0]; points[2] = [size, size, 0]; points[3] = [0 , size, 0]
  face = $component.entities.add_face(points)
  face.reverse! if face.normal.z < 0
  face.pushpull(size)
end

build_component $size

# Create a single TwistCube in a group
$cube = $active.active_entities.add_instance($component, Geom::Transformation.new)
$group = $active.active_entities.add_group($cube)
$group.name = "TwistCube"

# Make this group a dynamic component (so all TwistCube copies will live inside it)
da=initDynamicComponent($group)
addDynamicAttribute(da,"size",$size,access: true) # starting size of cube
da.add_observer(DCObserver.new)
