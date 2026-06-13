"""Mirror the left socket board into the right board.

Front<->back flip across the vertical axis through the board-outline centre.
Every element mirrors in X and moves to its opposite copper/silk layer, which is
exactly the right-hand variant (matches the original ErgoDash convention of the
right-hand Pro Micro living on B.Cu). Run with KiCad 10's bundled python.
"""
import sys
import pcbnew

path = sys.argv[1]
board = pcbnew.LoadBoard(path)

bb = board.GetBoardEdgesBoundingBox()
cx = (bb.GetLeft() + bb.GetRight()) // 2
cy = (bb.GetTop() + bb.GetBottom()) // 2
centre = pcbnew.VECTOR2I(cx, cy)
direction = pcbnew.FLIP_DIRECTION_LEFT_RIGHT

n_fp = n_tr = n_zone = n_draw = 0

for fp in board.GetFootprints():
    fp.Flip(centre, direction)
    n_fp += 1

for tr in board.GetTracks():          # tracks, arcs, vias
    tr.Flip(centre, direction)
    n_tr += 1

for zone in board.Zones():
    zone.Flip(centre, direction)
    n_zone += 1

for dr in board.GetDrawings():        # gr_line/poly/text/dimension
    dr.Flip(centre, direction)
    n_draw += 1

board.BuildConnectivity()
pcbnew.SaveBoard(path, board)
print(f"mirrored: footprints={n_fp} tracks={n_tr} zones={n_zone} drawings={n_draw}")
print(f"axis x = {cx/1e6:.3f} mm")
