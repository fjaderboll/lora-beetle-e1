#!/usr/bin/env python3
"""Generate the lora-beetle-e1 carrier board (lora-beetle-e1.kicad_pcb) with
the KiCad pcbnew API.

Run inside a KiCad container, e.g.:
    docker run --rm -v "$PWD":/work -w /work/board/pcb kicad/kicad:9.0.4 \
        python3 build_pcb.py

Coordinates are in mm, origin top-left, y pointing down. Layout (top view):
the 18650 holder runs along the left edge; CubeCell (USB-C at the bottom
edge), BH1750 and BME280 sit in a column to the right of it.
"""
import pcbnew
from pcbnew import VECTOR2I, FromMM

FP = "/usr/share/kicad/footprints"
OUT = "lora-beetle-e1.kicad_pcb"

W, H = 56.0, 101.0          # board size
CORNER = 3.0                # board corner radius
HOLE_INSET = 3.5            # M3 hole centre distance from edges

# 18650 holder (Keystone 1042/1042P), long axis vertical
HOLDER_X, HOLDER_Y = 13.35, H / 2

# CubeCell HTCC-AB01 V2: 40.64 x 22.86, header rows 20.28 apart,
# pin 1 of J2/J3 is 10.4 from the USB edge. USB-C at the bottom board edge.
CC_W, CC_L = 22.86, 40.64
CC_X0 = 30.5                # left edge of the CubeCell PCB
CC_Y1 = H - 0.5             # USB edge of the CubeCell PCB
CC_J3_X = CC_X0 + 1.29
CC_J2_X = CC_X0 + CC_W - 1.29
CC_PIN1_Y = CC_Y1 - 10.4

PITCH = 2.54
BUS_X = {"SDA": 39.36, "SCL": 41.90, "GND": 44.44, "VEXT": 46.98}
BH_Y = 53.5                 # BH1750 socket row
BME_Y = 9.0                 # BME280 socket row, near the top edge
BAT_X = 26.7                # battery header
BAT_TRACE_X = 24.6          # vertical run of the BAT- trace

W_BAT, W_PWR, W_SIG = 1.0, 0.5, 0.3


def mm(v):
    return FromMM(v)


def pt(x, y):
    return VECTOR2I(mm(x), mm(y))


board = pcbnew.BOARD()
board.SetCopperLayerCount(2)
tb = board.GetTitleBlock()
tb.SetTitle("lora-beetle-e1 carrier board")
tb.SetRevision("1")
tb.SetDate("2026-10-17")

nets = {}
for name in ("GND", "VEXT", "SCL", "SDA", "BAT+", "BAT-"):
    n = pcbnew.NETINFO_ITEM(board, name)
    board.Add(n)
    nets[name] = n


def footprint(lib, name, ref, x, y, rot=0, value=None, show_ref=False):
    fp = pcbnew.FootprintLoad(f"{FP}/{lib}.pretty", name)
    fp.SetReference(ref)
    fp.SetValue(value or name)
    fp.SetPosition(pt(x, y))
    fp.SetOrientationDegrees(rot)
    fp.Reference().SetVisible(show_ref)
    board.Add(fp)
    return fp


def pad_xy(fp, num):
    p = fp.FindPadByNumber(str(num)).GetPosition()
    return pcbnew.ToMM(p.x), pcbnew.ToMM(p.y)


def connect(fp, num, net):
    fp.FindPadByNumber(str(num)).SetNet(nets[net])


def track(points, net, width, layer=pcbnew.F_Cu):
    for (x1, y1), (x2, y2) in zip(points, points[1:]):
        t = pcbnew.PCB_TRACK(board)
        t.SetStart(pt(x1, y1))
        t.SetEnd(pt(x2, y2))
        t.SetWidth(mm(width))
        t.SetLayer(layer)
        t.SetNet(nets[net])
        board.Add(t)


def line(x1, y1, x2, y2, layer=pcbnew.F_SilkS, width=0.15):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(pt(x1, y1))
    s.SetEnd(pt(x2, y2))
    s.SetLayer(layer)
    s.SetWidth(mm(width))
    board.Add(s)


def rect(x1, y1, x2, y2, layer=pcbnew.F_SilkS, width=0.15):
    line(x1, y1, x2, y1, layer, width)
    line(x2, y1, x2, y2, layer, width)
    line(x2, y2, x1, y2, layer, width)
    line(x1, y2, x1, y1, layer, width)


def arc(start, mid, end, layer=pcbnew.Edge_Cuts, width=0.1):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_ARC)
    s.SetArcGeometry(pt(*start), pt(*mid), pt(*end))
    s.SetLayer(layer)
    s.SetWidth(mm(width))
    board.Add(s)


def text(s, x, y, size=1.0, layer=pcbnew.F_SilkS, rot=0, bold=False,
         justify=None):
    t = pcbnew.PCB_TEXT(board)
    t.SetText(s)
    t.SetPosition(pt(x, y))
    t.SetLayer(layer)
    t.SetTextSize(VECTOR2I(mm(size), mm(size)))
    t.SetTextThickness(mm(size * (0.2 if bold else 0.15)))
    t.SetTextAngleDegrees(rot)
    if justify == "left":
        t.SetHorizJustify(pcbnew.GR_TEXT_H_ALIGN_LEFT)
    elif justify == "right":
        t.SetHorizJustify(pcbnew.GR_TEXT_H_ALIGN_RIGHT)
    if layer == pcbnew.B_SilkS:
        t.SetMirrored(True)
    board.Add(t)


def zone(layer, net):
    z = pcbnew.ZONE(board)
    z.SetLayer(layer)
    z.SetNet(nets[net])
    o = z.Outline()
    o.NewOutline()
    inset = 0.3
    for x, y in ((inset, inset), (W - inset, inset),
                 (W - inset, H - inset), (inset, H - inset)):
        o.Append(mm(x), mm(y))
    z.SetLocalClearance(mm(0.3))
    z.SetMinThickness(mm(0.25))
    z.SetPadConnection(pcbnew.ZONE_CONNECTION_THERMAL)
    z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)
    board.Add(z)


# ---------------------------------------------------------------- outline
r = CORNER
line(r, 0, W - r, 0, pcbnew.Edge_Cuts, 0.1)
line(W, r, W, H - r, pcbnew.Edge_Cuts, 0.1)
line(W - r, H, r, H, pcbnew.Edge_Cuts, 0.1)
line(0, H - r, 0, r, pcbnew.Edge_Cuts, 0.1)
k = r * (1 - 0.7071067811865476)
arc((0, r), (k, k), (r, 0))
arc((W - r, 0), (W - k, k), (W, r))
arc((W, H - r), (W - k, H - k), (W - r, H))
arc((r, H), (k, H - k), (0, H - r))

# --------------------------------------------------------- mounting holes
for i, (x, y) in enumerate(((HOLE_INSET, HOLE_INSET),
                            (W - HOLE_INSET, HOLE_INSET),
                            (HOLE_INSET, H - HOLE_INSET),
                            (W - HOLE_INSET, H - HOLE_INSET)), 1):
    footprint("MountingHole", "MountingHole_3.2mm_M3", f"H{i}", x, y,
              value="M3")

# ------------------------------------------------------------- battery
# Rotated so pad 1 (+, the end with the small polarising peg) is at the
# bottom, next to the battery header.
bt = footprint("Battery", "BatteryHolder_Keystone_1042_1x18650", "BT1",
               HOLDER_X, HOLDER_Y, rot=90, value="Keystone 1042P 18650")
connect(bt, 1, "BAT+")
connect(bt, 2, "BAT-")
bp_x, bp_y = pad_xy(bt, 1)
bn_x, bn_y = pad_xy(bt, 2)
assert bp_y > bn_y, "holder pad 1 (+) should be at the bottom"

# 2-pin header for the JST lead to the CubeCell battery socket.
# Pin 1 = BAT+ (bottom), pin 2 = BAT- (above it).
jb = footprint("Connector_PinSocket_2.54mm", "PinSocket_1x02_P2.54mm_Vertical",
               "J1", BAT_X, bp_y, rot=180, value="BAT")
connect(jb, 1, "BAT+")
connect(jb, 2, "BAT-")
jp = pad_xy(jb, 1)
jn = pad_xy(jb, 2)
track([(bp_x, bp_y), jp], "BAT+", W_BAT)
track([(bn_x, bn_y), (BAT_TRACE_X, bn_y), (BAT_TRACE_X, jn[1]), jn],
      "BAT-", W_BAT)

# ------------------------------------------------------------- CubeCell
j2 = footprint("Connector_PinSocket_2.54mm", "PinSocket_1x11_P2.54mm_Vertical",
               "J2", CC_J2_X, CC_PIN1_Y, rot=180, value="CubeCell J2")
j3 = footprint("Connector_PinSocket_2.54mm", "PinSocket_1x11_P2.54mm_Vertical",
               "J3", CC_J3_X, CC_PIN1_Y, rot=180, value="CubeCell J3")
assert pad_xy(j2, 11)[1] < pad_xy(j2, 1)[1]
for fp, num, net in ((j2, 1, "GND"), (j2, 4, "VEXT"), (j2, 5, "GND"),
                     (j2, 6, "SCL"), (j2, 7, "SDA"), (j3, 1, "GND")):
    connect(fp, num, net)

# ------------------------------------------------------------- sensors
# Pin 1 (VCC) on the right. The BH1750 faces up with its body towards the
# top of the board; the BME280 faces down with its body towards the bottom,
# so the two bodies point at each other across the gap between the rows.
def sensor_socket(ref, pins, y, value):
    fp = footprint("Connector_PinSocket_2.54mm",
                   f"PinSocket_1x{pins:02d}_P2.54mm_Vertical",
                   ref, BUS_X["VEXT"], y, rot=270, value=value)
    assert pad_xy(fp, 2)[0] < pad_xy(fp, 1)[0]
    for num, net in ((1, "VEXT"), (2, "GND"), (3, "SCL"), (4, "SDA")):
        connect(fp, num, net)
    return fp


bme = sensor_socket("J4", 6, BME_Y, "BME280 (GY-BME280)")
bh = sensor_socket("J5", 5, BH_Y, "BH1750 (GY-302)")
connect(bh, 5, "GND")       # ADDR low (0x23) without relying on module pull-down

# I2C + power bus. SCL on top copper, VEXT on bottom copper, SDA starts on
# top and drops to the bottom so the three nets never cross.
x2 = CC_J2_X
y_vext, y_scl, y_sda = (pad_xy(j2, n)[1] for n in (4, 6, 7))
via_x = 45.0
track([(x2, y_scl), (BUS_X["SCL"], y_scl), (BUS_X["SCL"], BH_Y),
       (BUS_X["SCL"], BME_Y)], "SCL", W_SIG)
track([(x2, y_vext), (BUS_X["VEXT"], y_vext), (BUS_X["VEXT"], BH_Y),
       (BUS_X["VEXT"], BME_Y)], "VEXT", W_PWR, pcbnew.B_Cu)
track([(x2, y_sda), (via_x, y_sda)], "SDA", W_SIG)
track([(via_x, y_sda), (BUS_X["SDA"], y_sda), (BUS_X["SDA"], BH_Y),
       (BUS_X["SDA"], BME_Y)], "SDA", W_SIG, pcbnew.B_Cu)
v = pcbnew.PCB_VIA(board)
v.SetPosition(pt(via_x, y_sda))
v.SetDrill(mm(0.4))
v.SetWidth(mm(0.8))
v.SetNet(nets["SDA"])
board.Add(v)

# ----------------------------------------------------------- copper pours
zone(pcbnew.F_Cu, "GND")
zone(pcbnew.B_Cu, "GND")

# ------------------------------------------------------------- silkscreen
S = pcbnew.F_SilkS
# Holder
text("BT1  18650", HOLDER_X, HOLDER_Y, 1.5, rot=90, bold=True)
text("Keystone 1042P", HOLDER_X + 3, HOLDER_Y, 1.0, rot=90)
text("−", 5.0, bn_y, 2.0, bold=True)  # the footprint already marks +
# Battery header
text("BAT", BAT_X, jn[1] - 2.8, 0.9, bold=True)
text("−", BAT_X + 2.1, jn[1], 1.2, bold=True)
text("+", BAT_X + 2.1, jp[1], 1.2, bold=True)

# CubeCell outline and labels
cc_y0 = CC_Y1 - CC_L
# Drawn 0.4 mm outside the CubeCell so it clears the socket silkscreen;
# the USB edge coincides with the board edge, so it is left open, and the
# sides stop short of the M3 hole under the CubeCell.
o = 0.4
line(CC_X0 - o, CC_Y1 - 6.5, CC_X0 - o, cc_y0 - o)
line(CC_X0 - o, cc_y0 - o, CC_X0 + CC_W + o, cc_y0 - o)
line(CC_X0 + CC_W + o, cc_y0 - o, CC_X0 + CC_W + o, CC_Y1 - 6.5)
cx = CC_X0 + CC_W / 2
text("U1", cx, cc_y0 + 6, 1.5, bold=True)
text("CubeCell", cx, cc_y0 + 9, 1.2)
text("HTCC-AB01 V2", cx, cc_y0 + 11, 1.0)
text("USB-C", cx, CC_Y1 - 4.2, 1.2, bold=True)
line(cx, CC_Y1 - 3.2, cx, CC_Y1 - 1.3, S, 0.2)
line(cx - 0.9, CC_Y1 - 2.2, cx, CC_Y1 - 1.3, S, 0.2)
line(cx + 0.9, CC_Y1 - 2.2, cx, CC_Y1 - 1.3, S, 0.2)
text("J3", CC_J3_X + 2.6, CC_PIN1_Y, 0.9)
text("J2", CC_J2_X - 2.6, CC_PIN1_Y, 0.9)


PIN_EDGE = 1.3              # module edge to pin row centre


def sensor_labels(fp, y, names, ref, title, body_h, body_w, down):
    """Pin labels, reference and the module body outline. `down` means the
    body extends towards the bottom of the board from the pin row."""
    for num, name in enumerate(names, 1):
        x, _ = pad_xy(fp, num)
        text(name, x, y + 1.9, 0.8, rot=90, justify="right")
    xs = [pad_xy(fp, n)[0] for n in range(1, len(names) + 1)]
    mid = (min(xs) + max(xs)) / 2
    d = 1 if down else -1
    near = y - d * PIN_EDGE
    far = near + d * body_h
    x1, x2 = mid - body_w / 2, mid + body_w / 2
    rect(x1, near, x2, far, pcbnew.F_Fab, 0.1)
    # Silkscreen outline without the edge at the pin row, so it clears the
    # socket outline and shows which way the module points.
    start = y + d * 1.9
    line(x1, start, x1, far, S, 0.12)
    line(x1, far, x2, far, S, 0.12)
    line(x2, far, x2, start, S, 0.12)
    text(ref, mid, y - 3.2, 1.2, bold=True)
    text(title, mid, y - 5.0, 1.0)


sensor_labels(bme, BME_Y, ("VCC", "GND", "SCL", "SDA", "CSB", "SDO"),
              "U2", "BME280", 12.0, 15.5, down=True)
sensor_labels(bh, BH_Y, ("VCC", "GND", "SCL", "SDA", "ADDR"),
              "U3", "BH1750", 18.0, 13.9, down=False)

# Back side: identification
B = pcbnew.B_SilkS
text("lora-beetle-e1", W / 2, 40, 2.0, B, bold=True)
text("carrier board rev 1", W / 2, 44, 1.2, B)
text("2026-10-17", W / 2, 46.5, 1.0, B)

# ------------------------------------------------------------------ fill
# Filling a board that was built in memory crashes; reload it from disk first.
board.Save(OUT)
board = pcbnew.LoadBoard(OUT)
pcbnew.ZONE_FILLER(board).Fill(board.Zones())
board.Save(OUT)
print("wrote", OUT)
