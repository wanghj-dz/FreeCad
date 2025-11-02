# -*- coding: utf-8 -*-
"""
Register a temporary toolbar with commands wrapping the macros in this folder.
Run this inside FreeCAD GUI Python console or with FreeCAD (not FreeCADCmd) to add a toolbar for this session.
"""
import os
import FreeCAD as App
import FreeCADGui as Gui
try:
    from PySide2 import QtWidgets
except Exception:
    from PySide import QtGui as QtWidgets  # fallback for older builds

def _find_root():
    """Find the folder where macros are located.
    Tries multiple candidates to work even if __file__ is undefined (e.g., GUI console exec).
    """
    candidates = []
    # 1) Explicit env var override
    env_root = os.environ.get('FC_MACRO_ROOT')
    if env_root:
        candidates.append(env_root)
    # 2) User macro dir (preferred)
    try:
        user_app = App.getUserAppDataDir()  # e.g. C:\\Users\\<name>\\AppData\\Roaming\\FreeCAD\\
        macro_dir = os.path.join(user_app, 'Macro')
        candidates.append(macro_dir)
    except Exception:
        # fallback via APPDATA env
        appdata = os.environ.get('APPDATA')
        if appdata:
            candidates.append(os.path.join(appdata, 'FreeCAD', 'Macro'))

    # 3) Directory of this script if available
    this_file = globals().get('__file__')
    if this_file:
        candidates.append(os.path.dirname(os.path.abspath(this_file)))
    # 4) Current working directory
    try:
        candidates.append(os.getcwd())
    except Exception:
        pass
    # 5) Project default
    candidates.append(r'd:\\FreeCad')

    macro_names = [
        'ShowBodyFit.FCMacro', 'FilletEdges.FCMacro', 'ChamferEdges.FCMacro',
        'ToggleBaseVisibility.FCMacro', 'ToggleDisplayMode.FCMacro', 'SetColor.FCMacro'
    ]
    for c in candidates:
        try:
            if c and all(os.path.isfile(os.path.join(c, m)) for m in macro_names):
                return c
        except Exception:
            continue
    # Fallback to cwd even if macros not all present
    return candidates[0] if candidates else r'd:\\FreeCad'

ROOT = _find_root()

# Log FreeCAD version
try:
    ver = App.Version()
    App.Console.PrintMessage('[register_toolbar] FreeCAD Version: %s\n' % (' '.join(ver)))
except Exception:
    pass
MACROS = {
    'ShowBodyFit': os.path.join(ROOT, 'ShowBodyFit.FCMacro'),
    'FilletEdges': os.path.join(ROOT, 'FilletEdges.FCMacro'),
    'ChamferEdges': os.path.join(ROOT, 'ChamferEdges.FCMacro'),
    'ToggleBaseVisibility': os.path.join(ROOT, 'ToggleBaseVisibility.FCMacro'),
    'ToggleDisplayMode': os.path.join(ROOT, 'ToggleDisplayMode.FCMacro'),
    'SetColor': os.path.join(ROOT, 'SetColor.FCMacro'),
    'SaveExportFit': os.path.join(ROOT, 'SaveExportFit.FCMacro'),
}

class _MacroCommand:
    def __init__(self, name, path):
        self.name = name
        self.path = path
    def GetResources(self):
        return {'MenuText': self.name, 'ToolTip': self.path}
    def IsActive(self):
        return True
    def Activated(self):
        _exec_macro(self.path)

def _exec_macro(path):
    """Execute a macro file by reading and exec'ing its contents.
    This avoids relying on Gui.MacroManager which may not exist in some builds.
    """
    try:
        with open(path, 'rb') as f:
            code = f.read()
        ns = {'__file__': path, '__name__': '__main__'}
        exec(compile(code, path, 'exec'), ns)
    except Exception as e:
        App.Console.PrintError('[register_toolbar] run macro failed: %s\n' % e)

# Register commands
for name, path in MACROS.items():
    Gui.addCommand(name, _MacroCommand(name, path))

# Create toolbar (compatible way without relying on CommandManager)
mw = Gui.getMainWindow()
if mw is not None:
    tb = mw.findChild(QtWidgets.QToolBar, 'MyFreeCADMacros')
    if tb is None:
        tb = QtWidgets.QToolBar('MyFreeCADMacros')
        tb.setObjectName('MyFreeCADMacros')
        mw.addToolBar(tb)
    tb.clear()
    for name, path in MACROS.items():
        # Create a QAction bound to executing the macro file
        act = QtWidgets.QAction(name, mw)
        act.setObjectName(f"Action_{name}")
        def _make_cb(p):
            def _cb(checked=False):
                _exec_macro(p)
            return _cb
        act.triggered.connect(_make_cb(path))
        tb.addAction(act)
App.Console.PrintMessage('[register_toolbar] 工具栏已创建：MyFreeCADMacros。\n')
