import numpy as np
import pickle

from sklearn.neighbors import NearestNeighbors
from sklearn.manifold.t_sne import _joint_probabilities_nn
from scipy.spatial.distance import pdist
from scipy.spatial.distance import squareform

from dataset_utils import load_dataset, output_folder
from constraint_utils import get_constraints


MACHINE_EPSILON = np.finfo(np.double).eps


def compute_P(X, perplexity):
    """ utils function to calculate P matrix in high dim
        /opt/anaconda3/lib/python3.6/site-packages/sklearn/manifold/t_sne.py
        TODO: try to cache
    """

    n_samples = X.shape[0]

    # Compute the number of nearest neighbors to find.
    # LvdM uses 3 * perplexity as the number of neighbors.
    # In the event that we have very small # of points
    # set the neighbors to n - 1.
    k = min(n_samples - 1, int(3. * perplexity + 1))

    # Find the nearest neighbors for every point
    knn = NearestNeighbors(algorithm='auto', n_neighbors=k)
    knn.fit(X)
    distances_nn, neighbors_nn = knn.kneighbors(None, n_neighbors=k)

    # Free the memory used by the ball_tree
    del knn

    # knn return the euclidean distance but we need it squared
    # to be consistent with the 'exact' method. Note that the
    # the method was derived using the euclidean method as in the
    # input space. Not sure of the implication of using a different
    # metric.
    distances_nn **= 2

    # compute the joint probability distribution for the input space
    P = _joint_probabilities_nn(
        distances_nn, neighbors_nn, perplexity, verbose=0)
    # return P.todense()
    return np.maximum(P.todense(), MACHINE_EPSILON)


def compute_Q(X_embedded):
    degrees_of_freedom = 1
    X_embedded = X_embedded.reshape(-1, 2)

    dist = pdist(X_embedded, "sqeuclidean")
    dist /= degrees_of_freedom
    dist += 1.
    dist **= (degrees_of_freedom + 1.0) / -2.0
    Q = np.maximum(dist / (2.0 * np.sum(dist)), MACHINE_EPSILON)

    return squareform(Q)


def _neg_log_likelihood(X, mls, cls):
    log_loss_ml = np.sum(np.log(X[mls[:, 0], mls[:, 1]])) / len(mls)
    log_loss_cl = np.sum(1.0 - np.log(X[cls[:, 0], cls[:, 1]])) / len(cls)
    return -log_loss_ml, -log_loss_cl


def calculate_nll(X_original, item, mls, cls):
    # lr = item['learning_rate']
    perp = item['perplexity']
    X_embedded = item['embedding']

    P = compute_P(X_original, perp)
    p_ml, p_cl = _neg_log_likelihood(P, mls, cls)
    item['p_ml'] = p_ml
    item['p_cl'] = p_cl
    item['p_link'] = p_ml + p_cl

    Q = compute_Q(X_embedded)
    q_ml, q_cl = _neg_log_likelihood(Q, mls, cls)
    item['q_ml'] = q_ml
    item['q_cl'] = q_cl
    item['q_link'] = q_ml + q_cl


def pre_calculate_loss(dataset_name):
    # prepare original dataset
    X_original, y_original, labels_original = load_dataset(dataset_name)
    dist_X_original = pdist(X_original, "sqeuclidean")
    dist_X_original = squareform(dist_X_original)

    # prepare constraints
    num_constraints = 10
    mustlinks, cannotlinks = get_constraints(
        target_labels=y_original, n_take=num_constraints)

    # get pre-calculated tsne results
    pkl_name = '{}/tsne_{}.pkl'.format(output_folder, dataset_name)
    pkl_data = pickle.load(open(pkl_name, 'rb'))

    # calculate neg. log. likelihood for constrainted points
    for item in pkl_data['results']:
        calculate_nll(X_original, item, mustlinks, cannotlinks)
        # TODO calculate metric

    # add constraints into pickle object
    pkl_data['mustlinks'] = mustlinks
    pkl_data['cannotlinnks'] = cannotlinks

    # save pickle data for reuse
    out_name = '{}/plot_{}.pickle'.format(output_folder, dataset_name)
    pickle.dump(pkl_data, open(out_name, 'wb'))


if __name__ == '__main__':
    dataset_name = 'COUNTRY1999'  # 'MNIST-SMALL'
    pre_calculate_loss(dataset_name)
