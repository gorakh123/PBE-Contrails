import numpy as np
import matplotlib.pyplot as plt
import os

print(os.getcwd())
data = np.loadtxt('pbe\psd_sp.out')

x = data[:, 0]
y = data[:, 1]

plt.plot(x, y)

plt.show()