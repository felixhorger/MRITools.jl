
import os
import sys
import re
import numpy as np

txtfile = sys.argv[1]

f = open(txtfile)
re_start = re.compile("; Start Time = ([0-9]+)  SRT")
re_end = re.compile("; End Time = ([0-9]+)  SRT")
line = f.readline()
start = None
end = None
while len(line) > 0:
	match = re_start.match(line)
	if match is not None:
		start = match[1]
	#
	match = re_end.match(line)
	if match is not None:
		end = match[1]
	#
	if start is not None and end is not None: break
	line = f.readline()
#
if start is None or end is None: raise Exception("Could not find start/end time")
start = int(start)
end = int(end)

gradients = np.ones(((end-start) // 10 + 1, 3), np.float64)

line = f.readline()
i = 0
while len(line) > 0:
	line = line.strip()
	if len(line) == 0 or line[0] == ";":
		line = f.readline()
		continue
	#
	x, y, z = line.split()
	gradients[i, :] = (float(x), float(y), float(z))
	i += 1
	line = f.readline()
#
f.close()

k = np.cumsum(gradients, axis=0)
np.savez_compressed(os.path.join(os.path.dirname(txtfile), "gradients.npz"), gradients=gradients, k=k)

