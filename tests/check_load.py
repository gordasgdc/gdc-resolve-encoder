#!/usr/bin/env python3
"""dlopen/LoadLibrary smoke test: the packaged plugin must load and export pluginInit.
Usage: check_load.py <path-to-.dvcp>   (run against the BUNDLED plugin, so
FFmpeg dependencies are resolved exactly as Resolve would resolve them)."""
import ctypes, os, sys

path = os.path.abspath(sys.argv[1])
if not os.path.isfile(path):
    sys.exit(f"FAIL: file not found: {path}")
if sys.platform == "win32":
    os.add_dll_directory(os.path.dirname(path))  # FFmpeg DLLs sit next to the plugin
try:
    lib = ctypes.CDLL(path)
except OSError as e:
    sys.exit(f"FAIL: cannot load {path}: {e}")
try:
    getattr(lib, "pluginInit")
except AttributeError:
    sys.exit("FAIL: symbol pluginInit not exported")
print(f"OK: {os.path.basename(path)} loads, pluginInit exported")
