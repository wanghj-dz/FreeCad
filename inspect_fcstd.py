# -*- coding: utf-8 -*-
"""
Inspect a FreeCAD .FCStd file and list objects with bounding boxes.
Usage (run with FreeCADCmd):
  FreeCADCmd.exe d:\\FreeCad\\inspect_fcstd.py --file d:\\FreeCad\\cube.FCStd
You can also set env FC_FILE to the path if not using --file.
"""
import os, sys
try:
    import FreeCAD as App
except Exception as e:
    sys.stderr.write("Run this with FreeCADCmd.\n" + str(e) + "\n")
    sys.exit(2)


def _parse(argv):
    path = None
    for i in range(1, len(argv)):
        if argv[i] == '--file' and i + 1 < len(argv):
            path = argv[i+1]
            break
    if not path:
        path = os.environ.get('FC_FILE')
    if not path:
        raise SystemExit('Provide --file <path> or set FC_FILE env')
    return path


def main(argv):
    path = _parse(argv)
    norm = os.path.abspath(path)
    if not os.path.isfile(norm):
        print(f"File not found: {norm}")
        return 1
    doc = App.openDocument(norm)
    App.ActiveDocument = doc
    print(f"Opened: {norm}")
    print(f"Objects: {len(doc.Objects)}\n")
    for obj in doc.Objects:
        try:
            bb = obj.Shape.BoundBox
            print(f"- {obj.Name} ({obj.TypeId}) label='{obj.Label}'")
            print(f"  BB: X[{bb.XMin:.3f}, {bb.XMax:.3f}] Y[{bb.YMin:.3f}, {bb.YMax:.3f}] Z[{bb.ZMin:.3f}, {bb.ZMax:.3f}]  Diag={bb.DiagonalLength:.3f}")
        except Exception:
            print(f"- {obj.Name} ({obj.TypeId}) label='{obj.Label}' (no Shape)")
    return 0

if __name__ == '__main__' or 'FreeCAD' in sys.modules:
    sys.exit(main(sys.argv))
