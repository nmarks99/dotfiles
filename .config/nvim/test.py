from matplotlib import pyplot as plt 
import numpy as np 

x = np.arange(0,2*np.pi,0.01)
y = [np.sin(i) for i in x]


fig, ax = plt.subplots()
ax.plot(x,y)
plt.show()
