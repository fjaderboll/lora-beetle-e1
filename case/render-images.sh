#!/bin/bash -e

cd "$(dirname "$0")"

# `--camera` takes translate x, y, z, rotate x, y, z and distance, the same 
# values the OpenSCAD status bar shows for the current view.
# `--colorscheme=Monotone` is the default yellow without the green that
# OpenSCAD draws on some inner faces (the inside of the lid would be all green).
# `--view=axes,scales` add axes and scales.

openscad -o images/beetle-assembly.png \
	--render \
	--imgsize=1114,770 \
	--colorscheme=Monotone \
	--camera=0,-11.2,18.3,64.1,0,-33.8,245.6 \
	beetle-assembly.scad
openscad -o images/beetle-base.png \
	--render \
	--imgsize=1114,770 \
	--colorscheme=Monotone \
	--camera=0,0.2,7.3,38,0,-118,282.3 \
	beetle-base.scad
openscad -o images/beetle-lid.png \
	--render \
	--imgsize=1114,770 \
	--colorscheme=Monotone \
	-Dupside_down=true \
	--camera=0,0.5,-13.4,45,0,-118,260.7 \
	beetle-lid.scad
