# example MDS

# import numpy as np
# import json
# import matplotlib.pyplot as plt
from sklearn import datasets
from sklearn.decomposition import PCA


def iris_pca():
    iris = datasets.load_iris()
    X = iris.data
    print('Iris dataset loaded: ', X.shape)

    X_reduced = PCA(n_components=2).fit_transform(X)

    # plt.scatter(X_reduced[:, 0], X_reduced[:, 1],
    #             c=iris.target, cmap=plt.cm.Set1)

    scatter_data = [{'x': d[0], 'y': d[1], 'label': float(iris.target[i])}
                    for (i, d) in enumerate(X_reduced)]

    return scatter_data


if __name__ == '__main__':
    data = iris_pca()
    print(data)
