# example MDS

import numpy as np
import matplotlib.pyplot as plt
from sklearn import datasets
from sklearn.decomposition import PCA

iris = datasets.load_iris()
X = iris.data
print('Iris dataset loaded: ', X.shape)

X_reduced = PCA(n_components=2).fit_transform(X)

plt.scatter(X_reduced[:, 0], X_reduced[:, 1], c=iris.target, cmap=plt.cm.Set1)

scatter_data = [ {'x': d[0], 'y': d[1], 'label': iris.target[i]} for (i, d) in enumerate(X_reduced) ]

for d in scatter_data:
	print(d)