
import os
import h5py
import numpy as np

import matplotlib.pyplot as plt
plt.rcParams["lines.linewidth"] = 2
plt.rcParams["lines.markersize"] = 5
plt.rcParams["lines.markeredgewidth"] = 2
plt.rcParams["errorbar.capsize"] = 3


target = "data/20210707/generated"


def plotrf():
	data = h5py.File(os.path.join(target, "overlayed_pulses.jld"), "r")
	t = np.array(data["time"])
	instructed = np.array(data["instructed"])
	instructed = instructed["re_"] + 1.0j * instructed["im_"]
	measured = np.array(data["measured"])
	measured = measured["re_"] + 1.0j * measured["im_"]

	s = slice(0, None, 100)
	plt.figure()
	plt.plot(t[s], np.abs(instructed[s]), label="instructed")
	plt.plot(t[s], np.abs(measured[s]), label="measured")

	plt.figure()
	plt.plot(t[s], np.abs(np.cumsum(measured - instructed))[s])
	plt.show()
	return
#
plotrf()

