import sys, os
print("Hello from FreeCAD Python")
open(os.path.join(os.path.dirname(__file__), 'marker.txt'), 'w').write('ok')
