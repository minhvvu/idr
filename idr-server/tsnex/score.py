import numpy as np
from sklearn import svm, metrics
from sklearn.metrics.pairwise import pairwise_distances
from sklearn.cluster import KMeans
import utils


def PIVE_measure(old_p, new_p, dist_X, k=10):
    """ Calculate the measurement in PIVE framework [1]

    stability_{t} = 1/(nk) * \sum^{n}_{i} { |
        N_k(y_i^{t}) - N_k(y_i^{t-1})
    | }

    convergence_{t} = 1/(nk) * \sum^{n}_{i} { |
        N_k(y_i^{t}) \intersection N_k(X_i)
    | }

    in which N_k(.) is a set of k nearest neighbors
    and | setA | is the number of elements in setA

    [1]PIVE: Per-Iteration Visualization Environment for Real-Time Interactions
        with Dimension Reduction and Clustering.
    """
    n = dist_X.shape[0]

    dist_old = pairwise_distances(old_p.reshape(-1, 2), squared=True)
    dist_new = pairwise_distances(new_p.reshape(-1, 2), squared=True)

    k_ind_old = np.argsort(dist_old, axis=1)[:, 1:k + 1]
    k_ind_new = np.argsort(dist_new, axis=1)[:, 1:k + 1]
    k_ind_X = np.argsort(dist_X, axis=1)[:, 1:k + 1]

    stability = 0
    for i in range(n):
        set_old = set(k_ind_old[i])
        set_new = set(k_ind_new[i])
        new_but_not_old = set_new - set_old
        stability += len(new_but_not_old)
    stability /= (n * k)

    convergence = 0
    for i in range(n):
        set_embedded = set(k_ind_new[i])
        set_X = set(k_ind_X[i])
        intersection = set_embedded & set_X
        convergence += len(intersection)
    convergence /= (n * k)

    return stability, convergence


def classify(X):
    n = len(X)
    y = utils.get_y()
    classifier = svm.SVC(gamma=0.001)
    classifier.fit(X[:n // 2], y[:n // 2])
    y_true = y[n // 2:]
    y_predict = classifier.predict(X[n // 2:])
    score = metrics.accuracy_score(y_true, y_predict)
    # print("Classification accuracy = {}".format(float(score)))
    return float(score)


def clutering(X):
    labels = utils.get_y()
    n_clusters = len(np.unique(labels))
    kmeans = KMeans(init='k-means++', n_clusters=n_clusters, n_init=10)
    kmeans.fit(X)
    vmeasure = metrics.v_measure_score(labels, kmeans.labels_)
    # mutualInfo = metrics.adjusted_mutual_info_score(labels,  kmeans.labels_)
    silhoutte = metrics.silhouette_score(
        X, kmeans.labels_, metric='euclidean', sample_size=300)

    # print("Clustering measure: vmeasure = {}, silhoutte = {}"
    #       .format(float(vmeasure), float(silhoutte)))
    return (float(vmeasure), float(silhoutte))


if __name__ == '__main__':
    run_classify(X)
