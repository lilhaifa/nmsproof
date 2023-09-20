#!/usr/bin/python3

import sys
import re
import os


argc = len(sys.argv) - 1
lclibpath = os.environ["HOME"] + "dev/monsim/bin"

try: os.environ["PYTHONPATH"]
except KeyError:
      os.environ["PYTHONPATH"] = lclibpath
else:
      os.environ["PYTHONPATH"] = os.environ["PYTHONPATH"] + ":" + lclibpath 

print("total arguments received = ",argc)

for var in os.environ:
        pypathenvar = os.environ[var]
        print(var, "  = ", os.environ[var])

sys.exit(0)





