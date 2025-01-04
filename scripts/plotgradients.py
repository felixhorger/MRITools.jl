
import os
import sys
import re
import numpy as np
import matplotlib.pyplot as plt


with np.load(sys.argv[1]) as f:
	gradients = f["gradients"]
	k = f["k"]
#
time = np.linspace(0, 1e-5 * gradients.shape[0], gradients.shape[0], endpoint=False) # 10musec steps 

fig, axs = plt.subplots(1, 2)
axs[0].set_xlabel("t [s]")
axs[0].set_ylabel("G [mT/m]")
axs[0].plot(time, gradients[:, 0])
axs[0].plot(time, gradients[:, 1])
axs[1].set_xlabel("kx [s mT/m]")
axs[1].set_ylabel("ky [s mT/m]")
axs[1].plot(k[:, 0], k[:, 1])
plt.show()

