include intersect

try:
  case paramStr(1):
    of "r":
      read(paramStr(2))
    of "b":
      discard "Read the VM byte code"
except IndexError:
  echo "File not specified on command line"
except IOError:
 echo "Could not open file"

