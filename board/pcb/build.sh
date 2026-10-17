#!/bin/sh
# Rebuild the board, run DRC, export PCBWay fabrication files and renders.
# Needs only Docker; KiCad runs from the official image.
set -eu
cd "$(dirname "$0")"

IMAGE=kicad/kicad:9.0.4
kicad() {
	docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp \
		-v "$PWD/..":/work -w /work/pcb "$IMAGE" "$@"
}

kicad python3 build_pcb.py

kicad kicad-cli pcb drc --severity-all --exit-code-violations \
	-o /tmp/drc.rpt lora-beetle-e1.kicad_pcb

rm -rf gerbers lora-beetle-e1-gerbers.zip
mkdir gerbers
kicad kicad-cli pcb export gerbers -o gerbers/ \
	-l F.Cu,B.Cu,F.Mask,B.Mask,F.Silkscreen,B.Silkscreen,Edge.Cuts \
	lora-beetle-e1.kicad_pcb
kicad kicad-cli pcb export drill -o gerbers/ --format excellon \
	--excellon-units mm --generate-map --map-format gerberx2 lora-beetle-e1.kicad_pcb
(cd gerbers && zip -q ../lora-beetle-e1-gerbers.zip ./*)

kicad kicad-cli pcb render --side top --quality high --background opaque \
	-w 1600 -h 2400 -o ../images/pcb-top.png lora-beetle-e1.kicad_pcb
kicad kicad-cli pcb render --side bottom --quality high --background opaque \
	-w 1600 -h 2400 -o ../images/pcb-bottom.png lora-beetle-e1.kicad_pcb
kicad kicad-cli pcb render --side top --quality high --background opaque \
	--perspective --rotate 320,0,335 --zoom 0.8 -w 2000 -h 1500 \
	-o ../images/pcb-3d.png lora-beetle-e1.kicad_pcb

# Routing view: both copper layers without the GND pours, on a dark background.
kicad sh -c 'python3 routing_view.py lora-beetle-e1.kicad_pcb /tmp/routing.kicad_pcb &&
	kicad-cli pcb export svg --mode-single --page-size-mode 2 \
		--exclude-drawing-sheet -l B.Cu,F.Cu,F.Silkscreen,Edge.Cuts \
		-o ../images/pcb-routing.svg /tmp/routing.kicad_pcb'
sed -i '/viewBox=/a <rect x="0" y="0" width="100%" height="100%" fill="#1b1f24"/>' \
	../images/pcb-routing.svg

rm -f lora-beetle-e1.kicad_prl
echo "Done: lora-beetle-e1-gerbers.zip"
