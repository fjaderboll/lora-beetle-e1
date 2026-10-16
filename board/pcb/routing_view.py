#!/usr/bin/env python3
"""Save a copy of the board without copper pours, so an SVG export shows
every trace on both layers (the pours would otherwise hide them)."""
import sys
import pcbnew

board = pcbnew.LoadBoard(sys.argv[1])
for z in list(board.Zones()):
    board.Remove(z)
board.Save(sys.argv[2])
