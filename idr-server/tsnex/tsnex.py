# tsnex.py
from sklearn import datasets
from sklearn.manifold import TSNE

iris = datasets.load_iris()

X_train = iris.data
y = iris.target
print(X_train.shape)
print(len(y))


def test_embedding():
    tsne = TSNE(n_components=2, random_state=0)

    X_projected = tsne.fit_transform(X_train)

    print(X_projected.shape)

    return (X_projected, y)
