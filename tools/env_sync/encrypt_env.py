#!/usr/bin/env python3
from pathlib import Path
import runpy
import sys

script = Path(__file__).with_name("env_sync.py")
sys.argv = [str(script), "encrypt", *sys.argv[1:]]
runpy.run_path(str(script), run_name="__main__")
