"""Flip every keyswitch/socket footprint to mount the socket on the FRONT (F.Cu).

Option B, stage 1 (geometry only). Each hotswap socket footprint is flipped in
place about its own anchor (the switch centre). This is the physically correct
"socket on the other side" operation:

  - the socket SMD pads move from B.Cu to F.Cu (socket now on the front),
  - the switch electrical through-holes move from the MX front-insertion pattern
    {(-3.81,-2.54),(2.54,-5.08)} to the left-right-mirrored back-insertion
    pattern (the switch is now inserted from the back / plate side),
  - the keycap centre, centre pole and mounting pegs stay put.

This DISCONNECTS the matrix routing (the old traces fed the B.Cu socket pads /
the old hole positions). Rerouting the matrix to the new hole positions is done
by hand in KiCad afterwards -- this script only prepares the geometry.

Run with KiCad 10's bundled python:
  python flip_sockets_front.py Rev1.2-socket-left/ergodash.kicad_pcb
"""
import sys
import pcbnew

path = sys.argv[1]
board = pcbnew.LoadBoard(path)
direction = pcbnew.FLIP_DIRECTION_LEFT_RIGHT

# Post-flip rotation fix-ups (degrees, applied after the flip). After flipping,
# the socket "wings" (SMD pads) of a couple of edge thumb keys point off the
# board outline; rotating them brings the socket fully onto the board.
#   SW40 is a 2U key -> only 180 deg is allowed (90 would make it a vertical 2U).
#   SW35 is a 1U (square) key -> any 90 deg step is fine; +270 clears the edge.
ROTATE = {"SW40": 180, "SW35": 270}

n = 0
for fp in board.GetFootprints():
    if "Hotswap" in str(fp.GetFPID().GetLibItemName()):
        fp.Flip(fp.GetPosition(), direction)   # flip about own anchor -> stays in place
        extra = ROTATE.get(fp.GetReference())
        if extra:
            fp.Rotate(fp.GetPosition(), pcbnew.EDA_ANGLE(extra, pcbnew.DEGREES_T))
        n += 1

board.BuildConnectivity()
pcbnew.SaveBoard(path, board)
print(f"flipped {n} socket footprints to F.Cu "
      f"(rotated {', '.join(ROTATE)} to fit on board)")
