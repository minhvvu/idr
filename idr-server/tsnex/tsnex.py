# tsnex.py
# interactive tsne:
# https://www.oreilly.com/learning/an-illustrated-introduction-to-the-t-sne-algorithm

import numpy as np
from numpy import linalg
import sklearn
from sklearn.manifold import TSNE
from sklearn.manifold.t_sne import trustworthiness
from sklearn.metrics.pairwise import pairwise_distances
from sklearn.neighbors import NearestNeighbors
from scipy.spatial.distance import pdist, cdist
from scipy.spatial.distance import squareform
import networkx as nx
from time import time, sleep
import utils
import score


MACHINE_EPSILON = np.finfo(np.double).eps


shared_data = {
    'queue': None,
    'fixed_ids': [],
    'fixed_pos': [],
    'errors': [],
    'grad_norms': [],
    'z_info': None
}


def boostrap_do_embedding(X, shared_queue=None):
    """
    Boostrap to start doing embedding:
    Initialize the tsne object, setup params
    """
    print("[TSNEX] Thread to do embedding is starting ... ")

    shared_data['queue'] = shared_queue
    shared_data['fixed_ids'] = []
    shared_data['fixed_pos'] = []
    shared_data['errors'] = []
    shared_data['grad_norms'] = []
    shared_data['z_info'] = np.zeros(X.shape[0])

    sklearn.manifold.t_sne._gradient_descent = my_gradient_descent
    tsne = TSNE(
        n_components=2,
        random_state=0,
        init='random',
        method='exact',  # use this method to hook into kl_divergence
        perplexity=30.0,
        early_exaggeration=12.0,
        learning_rate=100.0,
        n_iter_without_progress=500,
        verbose=2
    )
    tsne._EXPLORATION_N_ITER = 250

    X_projected = tsne.fit_transform(X)
    return X_projected


# Folk this internal function in
# /opt/anaconda3/lib/python3.6/site-packages/sklearn/manifold/t_sne.py
def my_gradient_descent(objective, p0, it, n_iter,
                        n_iter_check=1, n_iter_without_progress=300,
                        momentum=0.8, learning_rate=200.0, min_gain=0.01,
                        min_grad_norm=1e-7, verbose=0, args=None, kwargs=None):
    if args is None:
        args = []
    if kwargs is None:
        kwargs = {}

    p = p0.copy().ravel()
    update = np.zeros_like(p)
    gains = np.ones_like(p)
    error = np.finfo(np.float).max
    best_error = np.finfo(np.float).max
    best_iter = i = it
    tic = time()

    X_original = utils.get_X()
    dist_X_original = pairwise_distances(X_original, squared=True)
    # weights = pdist(X_original)
    # dist_X_original = squareform(weights)
    # weights = weights / np.sum(weights)
    weights = np.ones_like(dist_X_original)
    np.fill_diagonal(weights, 0.0)

    shared_queue = shared_data['queue']
    must_share = utils.get_server_status(['accumulate'])
    must_share = must_share['accumulate']

    fixed_ids = shared_data['fixed_ids'] if must_share else []
    fixed_pos = shared_data['fixed_pos'] if must_share else []
    errors = shared_data['errors'] if must_share else []
    grad_norms = shared_data['grad_norms'] if must_share else []
    z_info = shared_data['z_info']
    if not must_share:
        z_info = np.zeros(z_info.shape[0])

    # some temporary measurements to plot at client side
    hubs = []
    authors = []
    pageranks = []
    embedding_scores = []
    classification_scores = []
    clustering_scores = []
    penalties = []

    print("\nGradien Descent:")
    i = 0
    while True:
        i += 1
        if n_iter < 500 and i > n_iter:
            break  # early_exaggeration

        status = utils.get_server_status()
        if status['stop'] is True:
            return p, error, i

        # wait for the `ready` flag to become `True` in order to continue
        # note that, this flag can be changed at any time
        # so for consitently checking this flag, get it directly from redis.
        while utils.get_ready_status() is False:
            sleep(status['tick_frequence'])

        if not shared_queue.empty():
            shared_item = shared_queue.get()
            fixed_ids = shared_item['fixed_ids']
            fixed_pos = shared_item['fixed_pos']

        if fixed_ids and fixed_pos:
            # keep the old embedding for calculate neighbors of moved points
            X2d = p.copy().reshape(-1, 2)
            n_neighbors = int(0.05 * X2d.shape[0])
            distances = cdist(X2d[fixed_ids], X2d, 'sqeuclidean')
            knn = np.argsort(distances, axis=1)[:, 1:n_neighbors+1]
            kwargs['fixed_ids'] = fixed_ids
            kwargs['neighbor_ids'] = knn
            kwargs['reg_param'] = 1e-3

            # update position of the newly moved points
            p.reshape(-1, 2)[fixed_ids] = fixed_pos

        # calculate gradient and KL divergence
        error, penalty, grad, divergences = my_kl_divergence2(p, *args, **kwargs)
        z_info += divergences

        # calculate the magnitude of gradient of each point
        grad_per_point = linalg.norm(grad.reshape(-1, 2), axis=1)
        grad_norm = np.sum(grad_per_point)

        # tsne update gradient by momentum
        inc = update * grad < 0.0
        dec = np.invert(inc)
        gains[inc] += 0.2
        gains[dec] *= 0.8
        np.clip(gains, min_gain, np.inf, out=gains)
        grad *= gains
        update = momentum * update - learning_rate * grad
        old_p = p.copy()
        p += update

        # manual fix the pos of moved point
        if fixed_ids and fixed_pos:
            p.reshape(-1, 2)[fixed_ids] = fixed_pos

        if (i % status['n_jump'] == 0):
            if status['measure'] is True:
                trustwth = trustworthiness(dist_X_original, p.reshape(-1, 2),
                                           n_neighbors=10, precomputed=True)
                stability, convergence = score.PIVE_measure(
                    old_p, p, dist_X_original)
                embedding_scores.append((trustwth, stability, convergence))

                # classification_scores.append(score.classify(X_embedded))
                clustering_scores.append(score.clutering(X_embedded))

            errors.append(error)
            penalties.append(penalty)
            grad_norms.append(float(grad_norm))
            client_data = {
                'embedding': p.copy().tostring().decode('latin-1'),
                'z_info': z_info.tolist(),
                'seriesData': [
                    {'name': 'errors, penalty', 'series': [errors, penalties]},
                    {'name': 'gradients norms', 'series': [grad_norms]},
                    # {'name': 'classification accuracy',
                    #     'series': [classification_scores]},
                    {'name': 'vmeasure, silhoutte',
                        'series': [list(t) for t in zip(*clustering_scores)]},
                    {'name': 'trustworthinesses,statbility,convergence',
                        'series': [list(t) for t in zip(*embedding_scores)]},
                ]
            }
            utils.publish_data(client_data)
            # hold for a while so that client can receive this new data
            sleep(status['tick_frequence'])

        if (i + 1) % n_iter_check == 0:
            toc = time()
            duration = toc - tic
            tic = toc

            if verbose >= 2:
                print("[t-SNE] Iteration %d: error = %.7f,"
                      " gradient norm = %.7f"
                      " (%s iterations in %0.3fs)"
                      % (i + 1, error, grad_norm, n_iter_check, duration))

            if error < best_error:
                best_error = error
                best_iter = i
            elif i - best_iter > n_iter_without_progress:
                if verbose >= 2:
                    print("[t-SNE] Iteration %d: did not make any progress "
                          "during the last %d episodes. Finished."
                          % (i + 1, n_iter_without_progress))
                # break
            if grad_norm <= min_grad_norm:
                if verbose >= 2:
                    print("[t-SNE] Iteration %d: gradient norm %f. Finished."
                          % (i + 1, grad_norm))
                # break

    return p, error, i


def share_grad(grad2d, dist_y, fixed_ids, k=10):
    nn = np.argsort(dist_y, axis=1)
    for fixed_id in fixed_ids:
        grad_for_share = grad2d[fixed_id] / k
        if grad_for_share[0] and grad_for_share[1]:
            ki = 0
            for target_i in nn[fixed_id]:
                if target_i not in fixed_ids:
                    grad2d[target_i] += grad_for_share
                    ki += 1
                    if ki == k:
                        break
            grad2d[fixed_id] = 0.0


def my_kl_divergence(params, P, degrees_of_freedom, n_samples, n_components,
                     skip_num_points=0, weights=None):

    # for idx in range(len(fixed_ids)):
    #     src_id = fixed_ids[idx]
    #     targets = knn[idx]

    #     for idx2 in range(len(targets)):
    #         target_id = targets[idx2]

    #         if target_id != src_id:
    #             dist = float(distances[idx][idx2])
    #             weights[src_id][target_id] = weights[target_id][src_id] = \
    #                 float(status['use_weight'])
    use_weights_on_Q = True
    X_embedded = params.reshape(n_samples, n_components)

    # Q is a heavy-tailed distribution: Student's t-distribution
    dist = pdist(X_embedded, "sqeuclidean")
    if weights is None:
        weights = np.ones_like(dist)
    else:
        weights = squareform(weights)

    if use_weights_on_Q:
        """ q_{ij} = \frac
                {(1 + w_{ij} * \norm^2{y_i - y_j})^{-1}}
                {\sum_{k,l}(1 + w_{kl} * \norm^2{y_k - y_l})^{-1}}
        """
        dist *= weights

    dist /= degrees_of_freedom
    dist += 1.
    dist **= (degrees_of_freedom + 1.0) / -2.0
    Q = np.maximum(dist / (2.0 * np.sum(dist)), MACHINE_EPSILON)

    # Optimization trick below: np.dot(x, y) is faster than
    # np.sum(x * y) because it calls BLAS

    # Objective: C (Kullback-Leibler divergence of P and Q)
    # kl_divergence_original = 2.0 * np.dot(P, np.log(np.maximum(P, MACHINE_EPSILON) / Q))
    divergences = P * np.log(np.maximum(P, MACHINE_EPSILON) / Q)
    if not use_weights_on_Q:
        # use simple weight: KL(P||Q) = \sum_i \sum_j w_{ij} * p_{ij} * log (p_{ij}/q_{ij})
        divergences *= weights
    kl_divergence = 2.0 * np.sum(divergences)
    divergences = squareform(divergences)
    divergences = np.sum(divergences, axis=1)

    # Gradient: dC/dY
    grad = np.ndarray((n_samples, n_components), dtype=params.dtype)

    if use_weights_on_Q:
        PQd = squareform((P - Q) * dist * weights)
    else:
        PQd = squareform((P - Q) * dist)

    for i in range(skip_num_points, n_samples):
        grad[i] = np.dot(np.ravel(PQd[i], order='K'),
                         X_embedded[i] - X_embedded)

    grad = grad.ravel()
    c = 2.0 * (degrees_of_freedom + 1.0) / degrees_of_freedom
    grad *= c

    return kl_divergence, grad, divergences


def my_kl_divergence2(params, P, degrees_of_freedom, n_samples, n_components,
                      skip_num_points=0,
                      reg_param=0, fixed_ids=None, neighbor_ids=None):

    X_embedded = params.reshape(n_samples, n_components)

    # Q is a heavy-tailed distribution: Student's t-distribution
    dist = pdist(X_embedded, "sqeuclidean")
    dist /= degrees_of_freedom
    dist += 1.
    dist **= (degrees_of_freedom + 1.0) / -2.0
    Q = np.maximum(dist / (2.0 * np.sum(dist)), MACHINE_EPSILON)

    # Optimization trick below: np.dot(x, y) is faster than
    # np.sum(x * y) because it calls BLAS

    # Objective: C (Kullback-Leibler divergence of P and Q)
    # kl_divergence = 2.0 * np.dot(P, np.log(np.maximum(P, MACHINE_EPSILON) / Q))
    divergences = P * np.log(np.maximum(P, MACHINE_EPSILON) / Q)
    kl_divergence = 2.0 * np.sum(divergences)
    divergences = squareform(divergences)
    divergences = np.sum(divergences, axis=1)

    # add penalty term for moved points
    penalty = 0.0
    if fixed_ids is not None and neighbor_ids is not None:
        for idx, fixed_id in enumerate(fixed_ids):
            nbs = neighbor_ids[idx]
            penalty += np.sum((X_embedded[fixed_id] - X_embedded[nbs])**2)
        penalty /= (len(fixed_ids) * len(neighbor_ids[0]))
        penalty *= reg_param
    kl_divergence += penalty

    # Gradient: dC/dY
    grad = np.ndarray((n_samples, n_components), dtype=params.dtype)
    PQd = squareform((P - Q) * dist)
    for i in range(skip_num_points, n_samples):
        grad[i] = np.dot(np.ravel(PQd[i], order='K'),
                         X_embedded[i] - X_embedded)
    c = 2.0 * (degrees_of_freedom + 1.0) / degrees_of_freedom
    grad *= c

    # gradient of penalty only for the involved points
    if fixed_ids is not None and neighbor_ids is not None:
        for idx, fixed_id in enumerate(fixed_ids):
            nbs = neighbor_ids[idx]
            const = -2 * reg_param / len(nbs)
            grad[nbs] += const * (X_embedded[fixed_id] - X_embedded[nbs])
        grad[fixed_ids] = 0.0

    grad = grad.ravel()
    return kl_divergence, penalty, grad, divergences
