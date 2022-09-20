from matplotlib import pyplot as plt
import numpy as np

x = np.arange(0,6,0.1)

y = [np.sin(i) for i in x]

fig, ax = plt.subplots()
ax.plot(x,y)
plt.show()



