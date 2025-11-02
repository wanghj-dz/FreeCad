# -*- coding: utf-8 -*-
"""
Create a cube (Part::Box) in FreeCAD via script.

Usages (run with FreeCADCmd.exe, not plain python):
  FreeCADCmd.exe d:\\FreeCad\\create_cube.py --length 20 --width 15 --height 10 \
      --fcstd d:\\FreeCad\\cube.FCStd --stl d:\\FreeCad\\cube.stl

Notes:
- This script must run inside FreeCAD's Python (GUI or FreeCADCmd). Normal Python won't have FreeCAD modules.
- All dimensions are in millimeters.
- Arguments are optional; defaults are L=W=H=10mm. If no --fcstd provided, a timestamped .FCStd is saved in script folder.
"""
from __future__ import annotations
import os
import sys
import time

# FreeCAD environment imports (available when running within FreeCAD/FreeCADCmd)
try:
    import FreeCAD as App  # type: ignore
    import Part  # type: ignore
    # Mesh export is optional; only used if --stl provided
    try:
        import Mesh  # type: ignore
    except Exception:  # pragma: no cover
        Mesh = None  # type: ignore
    try:
        import MeshPart  # type: ignore
    except Exception:  # pragma: no cover
        MeshPart = None  # type: ignore
except Exception as e:
    sys.stderr.write("This script must be executed by FreeCAD or FreeCADCmd.\n")
    sys.stderr.write(str(e) + "\n")
    sys.exit(2)


def _parse_args(argv):
    """Very small arg parser to avoid argparse dependency differences in FreeCAD env.
    Supported flags (case-sensitive):
      --length <mm>
      --width  <mm>
      --height <mm>
      --fcstd  <output .FCStd path>
      --stl    <output .stl path>
    --name   <object name, default MyCube>
    --pos    <x,y,z> placement position in mm (e.g. 0,0,0)
    --rot    <rx,ry,rz> rotation in degrees about X,Y,Z (e.g. 0,0,0)
    --holeRadius <mm>  through-hole radius along Z at cube center
    --holeAxis <X|Y|Z> axis for through-hole (default Z)
    """
    # defaults
    cfg = {
        "length": 10.0,
        "width": 10.0,
        "height": 10.0,
        "fcstd": None,
        "stl": None,
        "name": "MyCube",
        "pos": None,          # "x,y,z"
        "rot": None,          # "rx,ry,rz" degrees
        "holeRadius": 0.0,
        "holeAxis": "Z",
    }
    it = iter(range(1, len(argv)))
    i = 1
    while i < len(argv):
        a = argv[i]
        if a in ("--length", "--width", "--height"):
            if i + 1 >= len(argv):
                raise SystemExit(f"Missing value after {a}")
            try:
                cfg[a.lstrip("-")] = float(argv[i + 1])
            except ValueError:
                raise SystemExit(f"{a} expects a number (mm)")
            i += 2
            continue
        if a in ("--fcstd", "--stl", "--name", "--pos", "--rot", "--holeAxis"):
            if i + 1 >= len(argv):
                raise SystemExit(f"Missing value after {a}")
            cfg[a.lstrip("-")] = argv[i + 1]
            i += 2
            continue
        if a in ("--holeRadius",):
            if i + 1 >= len(argv):
                raise SystemExit(f"Missing value after {a}")
            try:
                cfg[a.lstrip("-")] = float(argv[i + 1])
            except ValueError:
                raise SystemExit(f"{a} expects a number (mm)")
            i += 2
            continue
        # ignore unknown tokens (allows FreeCAD to pass internal args)
        i += 1
    return cfg


def create_cube(length=10.0, width=10.0, height=10.0, name="MyCube"):
    """Create a new FreeCAD document and add a Part::Box.

    Returns (doc, cube_obj)
    """
    App.Console.PrintMessage("[create_cube] start\n")
    doc = App.ActiveDocument
    if doc is None:
        App.Console.PrintMessage("[create_cube] new document\n")
        doc = App.newDocument("CubeDoc")
    else:
        App.Console.PrintMessage(f"[create_cube] reuse document: {doc.Name}\n")
    cube = doc.addObject("Part::Box", name)
    cube.Length = float(length)
    cube.Width = float(width)
    cube.Height = float(height)
    App.Console.PrintMessage(f"[create_cube] set size L={float(cube.Length)} mm, W={float(cube.Width)} mm, H={float(cube.Height)} mm\n")
    doc.recompute()
    App.Console.PrintMessage("[create_cube] recompute done\n")
    return doc, cube


def save_fcstd(doc, out_path: str):
    folder = os.path.dirname(out_path)
    if folder and not os.path.isdir(folder):
        os.makedirs(folder, exist_ok=True)
    # Normalize path for FreeCAD (forward slashes help on Windows)
    norm_path = out_path.replace("\\", "/")
    App.Console.PrintMessage(f"[save_fcstd] saving to: {norm_path}\n")
    doc.saveAs(norm_path)
    App.Console.PrintMessage("[save_fcstd] save done\n")
    return norm_path


def export_stl(objs, out_path: str):
    folder = os.path.dirname(out_path)
    if folder and not os.path.isdir(folder):
        os.makedirs(folder, exist_ok=True)
    if 'Mesh' in globals() and Mesh is not None:
        try:
            Mesh.export(list(objs), out_path)
            return out_path
        except Exception:
            pass
    # Fallback: mesh via MeshPart if available
    if 'MeshPart' in globals() and MeshPart is not None:
        try:
            for obj in objs:
                mesh = MeshPart.meshFromShape(Shape=obj.Shape, LinearDeflection=0.1, AngularDeflection=0.523599, Relative=False)
                mesh.write(out_path)
            return out_path
        except Exception:
            pass
    raise RuntimeError("No Mesh export available in this FreeCAD environment")

def _gui_show_and_fit(doc, target):
    try:
        import FreeCADGui as Gui  # type: ignore
    except Exception:
        return
    try:
        # Hide other shape-bearing objects to declutter
        candidates = [o for o in doc.Objects if hasattr(o, 'Shape') and getattr(o,'Shape',None) is not None and not o.Shape.isNull()]
        for o in candidates:
            try:
                o.ViewObject.Visibility = (o == target)
            except Exception:
                pass
        try:
            Gui.Selection.clearSelection()
            Gui.Selection.addSelection(target)
        except Exception:
            pass
        try:
            av = Gui.ActiveDocument.ActiveView
            av.viewAxonometric()
            Gui.SendMsgToActiveView('ViewFit')
        except Exception:
            pass
    except Exception:
        pass


def main(argv):
    # marker to confirm script actually runs
    try:
        open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cube_ran.txt'), 'w').write('ran')
    except Exception:
        pass
    App.Console.PrintMessage("[main] parsing args\n")
    cfg = _parse_args(argv)
    # Allow overriding via environment variables (safer than CLI args which FreeCAD may intercept)
    env_map = {
        "length": os.environ.get("FC_LENGTH"),
        "width": os.environ.get("FC_WIDTH"),
        "height": os.environ.get("FC_HEIGHT"),
        "fcstd": os.environ.get("FC_FCSTD"),
        "stl": os.environ.get("FC_STL"),
        "name": os.environ.get("FC_NAME"),
        "pos": os.environ.get("FC_POS"),
        "rot": os.environ.get("FC_ROT"),
        "holeRadius": os.environ.get("FC_HOLE_RADIUS"),
        "holeAxis": os.environ.get("FC_HOLE_AXIS"),
    }
    for k, v in env_map.items():
        if v is None or v == "":
            continue
        if k in ("length", "width", "height", "holeRadius"):
            try:
                cfg[k] = float(v)
            except Exception:
                App.Console.PrintError(f"[main] invalid env for {k}: {v}\n")
        else:
            cfg[k] = v
    App.Console.PrintMessage(f"[main] args: {cfg}\n")
    doc, cube = create_cube(cfg["length"], cfg["width"], cfg["height"], cfg["name"])

    # Placement (position and rotation)
    def _parse_vec3(s):
        parts = [p.strip() for p in s.split(',')]
        if len(parts) != 3:
            raise ValueError
        return [float(parts[0]), float(parts[1]), float(parts[2])]

    # default placement
    pos = [0.0, 0.0, 0.0]
    rot = [0.0, 0.0, 0.0]  # rx, ry, rz (deg)
    if cfg.get("pos"):
        try:
            pos = _parse_vec3(cfg["pos"])  # mm
        except Exception:
            App.Console.PrintError(f"[main] invalid pos: {cfg['pos']} expected x,y,z\n")
    if cfg.get("rot"):
        try:
            rot = _parse_vec3(cfg["rot"])  # deg
        except Exception:
            App.Console.PrintError(f"[main] invalid rot: {cfg['rot']} expected rx,ry,rz\n")

    if any(abs(v) > 1e-12 for v in pos) or any(abs(v) > 1e-12 for v in rot):
        App.Console.PrintMessage(f"[placement] pos={pos}, rot={rot}\n")
        v = App.Vector(*pos)
        rx, ry, rz = rot
        # Compose rotations about X, then Y, then Z
        r = App.Rotation(App.Vector(1,0,0), rx)
        r = App.Rotation(App.Vector(0,1,0), ry).multiply(r)
        r = App.Rotation(App.Vector(0,0,1), rz).multiply(r)
        cube.Placement = App.Placement(v, r)
        doc.recompute()

    # Optional through-hole at cube center along specified axis
    result_obj = cube
    hole_r = float(cfg.get("holeRadius") or 0.0)
    hole_axis = (cfg.get("holeAxis") or "Z").upper()
    if hole_r > 0.0:
        App.Console.PrintMessage(f"[hole] radius={hole_r} mm axis={hole_axis}\n")
        cyl = doc.addObject("Part::Cylinder", "Hole")
        cyl.Radius = hole_r
        # Determine hole axis and sizing
        L = float(cube.Length)
        W = float(cube.Width)
        H = float(cube.Height)
        margin = 2.0
        if hole_axis == 'X':
            cyl.Height = L + margin
            # rotate cylinder to align with X axis: rotate +90deg about Y
            rot_cyl = App.Rotation(App.Vector(0,1,0), 90)
            base = App.Vector(-margin/2.0, W/2.0, H/2.0)
        elif hole_axis == 'Y':
            cyl.Height = W + margin
            # align with Y axis: rotate -90deg about X
            rot_cyl = App.Rotation(App.Vector(1,0,0), -90)
            base = App.Vector(L/2.0, -margin/2.0, H/2.0)
        else:
            cyl.Height = H + margin
            rot_cyl = App.Rotation()  # default Z axis
            base = App.Vector(L/2.0, W/2.0, -margin/2.0)
        cyl.Placement = App.Placement(base, rot_cyl)

        cut = doc.addObject("Part::Cut", "Body")
        cut.Base = result_obj
        cut.Tool = cyl
        doc.recompute()
        result_obj = cut

    # Decide output paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if not cfg["fcstd"]:
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        cfg["fcstd"] = os.path.join(script_dir, f"cube-{timestamp}.FCStd")
    fcstd_path = save_fcstd(doc, cfg["fcstd"]) if cfg["fcstd"] else None
    if fcstd_path and not os.path.exists(fcstd_path.replace("/", "\\")):
        App.Console.PrintError(f"[main] save failed or path not found: {fcstd_path}\n")

    stl_path = None
    if cfg["stl"]:
        stl_path = export_stl([result_obj], cfg["stl"])  # may raise

    # Log summary
    App.Console.PrintMessage("Created cube:\n")
    App.Console.PrintMessage(f"  Name   : {result_obj.Name}\n")
    App.Console.PrintMessage(f"  Size   : L={float(cube.Length)} mm, W={float(cube.Width)} mm, H={float(cube.Height)} mm\n")
    if fcstd_path:
        App.Console.PrintMessage(f"  Saved  : {fcstd_path}\n")
    if stl_path:
        App.Console.PrintMessage(f"  STL    : {stl_path}\n")
    # If running in GUI, show final result and fit view now (after save so file has geometry either way)
    _gui_show_and_fit(doc, result_obj)
    return 0


if __name__ == "__main__" or ("FreeCAD" in sys.modules):
    sys.exit(main(sys.argv))
