@echo off
echo Running minimal FreeCAD script with output capture...
echo Log will be saved to: d:\FreeCad\minimal_script_output.log

REM Run the minimal script and capture all output
C:\Users\admin\scoop\shims\freecadcmd.exe d:\FreeCad\minimal_cube.py > d:\FreeCad\minimal_script_output.log 2>&1

echo Script execution completed!
echo Please check minimal_script_output.log for details.
pause