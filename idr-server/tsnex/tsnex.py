# tsnex.py
# interactive tsne:
# https://www.oreilly.com/learning/an-illustrated-introduction-to-the-t-sne-algorithm

import sklearn
from sklearn.manifold import TSNE
from sklearn.manifold.t_sne import trustworthiness
from sklearn.metrics.pairwise import pairwise_distances
import numpy as np
from numpy import linalg
import networkx as nx
from time import time, sleep
import utils
from classifier import run_classify


shared_data = {
    'queue': None,
    'gradients_acc': None,
    'fixed_ids': [],
    'fixed_pos': [],
    'errors': [],
    'grad_norms': [],
    'classification_scores': [],
    'trustworthinesses': [],
    'stabilities': [],
    'convergences': []
}


def boostrap_do_embedding(X, shared_queue=None):
    """
    Boostrap to start doing embedding:
    Initialize the tsne object, setup params
    """
    print("[TSNEX] Thread to do embedding is starting ... ")

    shared_data['queue'] = shared_queue
    shared_data['gradients_acc'] = np.zeros(X.shape[0])
    shared_data['fixed_ids'] = []
    shared_data['fixed_pos'] = []
    shared_data['errors'] = []
    shared_data['grad_norms'] = []
    shared_data['classification_scores'] = [],
    shared_data['trustworthinesses'] = []
    shared_data['stabilities'] = []
    shared_data['convergences'] = []

    sklearn.manifold.t_sne._gradient_descent = my_gradient_descent
    tsne = TSNE(
        n_components=2,
        random_state=0,
        init='random',
        perplexity=50,
        n_iter_without_progress=500,
        verbose=2
    )
    tsne._EXPLORATION_N_ITER = 300

    X_projected = tsne.fit_transform(X)
    return X_projected


# Folk this internal function in
# /opt/anaconda3/lib/python3.6/site-packages/sklearn/manifold/t_sne.py
def my_gradient_descent(objective, p0, it, n_iter,
                        n_iter_check=1, n_iter_without_progress=300,
                        momentum=0.8, learning_rate=200.0, min_gain=0.01,
                        min_grad_norm=1e-7, verbose=0, args=None, kwargs=None):
    """Batch gradient descent with momentum and individual gains.

        Parameters
        ----------
        objective : function or callable
            Should return a tuple of cost and gradient for a given parameter
            vector. When expensive to compute, the cost can optionally
            be None and can be computed every n_iter_check steps using
            the objective_error function.

        p0 : array-like, shape (n_params,)
            Initial parameter vector.

        it : int
            Current number of iterations (this function will be called more than
            once during the optimization).

        n_iter : int
            Maximum number of gradient descent iterations.

        n_iter_check : int
            Number of iterations before evaluating the global error. If the error
            is sufficiently low, we abort the optimization.

        n_iter_without_progress : int, optional (default: 300)
            Maximum number of iterations without progress before we abort the
            optimization.

        momentum : float, within (0.0, 1.0), optional (default: 0.8)
            The momentum generates a weight for previous gradients that decays
            exponentially.

        learning_rate : float, optional (default: 200.0)
            The learning rate for t-SNE is usually in the range [10.0, 1000.0]. If
            the learning rate is too high, the data may look like a 'ball' with any
            point approximately equidistant from its nearest neighbours. If the
            learning rate is too low, most points may look compressed in a dense
            cloud with few outliers.

        min_gain : float, optional (default: 0.01)
            Minimum individual gain for each parameter.

        min_grad_norm : float, optional (default: 1e-7)
            If the gradient norm is below this threshold, the optimization will
            be aborted.

        verbose : int, optional (default: 0)
            Verbosity level.

        args : sequence
            Arguments to pass to objective function.

        kwargs : dict
            Keyword arguments to pass to objective function.

        Returns
        -------
        p : array, shape (n_params,)
            Optimum parameters.

        error : float
            Optimum.

        i : int
            Last iteration.
    """

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

    shared_queue = shared_data['queue']
    must_share = utils.get_server_status(['accumulate'])
    must_share = must_share['accumulate']

    gradients_acc = shared_data['gradients_acc']
    if not must_share:
        gradients_acc = np.zeros(gradients_acc.shape[0])

    fixed_ids = shared_data['fixed_ids'] if must_share else []
    fixed_pos = shared_data['fixed_pos'] if must_share else []
    errors = shared_data['errors'] if must_share else []
    grad_norms = shared_data['grad_norms'] if must_share else []
    classification_scores = shared_data['classification_scores'] if must_share else []
    trustworthinesses = shared_data['trustworthinesses'] if must_share else []
    stabilities = shared_data['stabilities'] if must_share else []
    convergences = shared_data['convergences'] if must_share else []

    X_original = utils.get_X()
    dist_X_original = pairwise_distances(X_original, squared=True)
    hubs = pageranks = []

    print("\nGradien Descent:")
    while True:
        i += 1
        if n_iter < 500 and i > n_iter:  # early_exaggeration
            break

        status = utils.get_server_status(
            ['n_jump', 'tick_frequence', 'n_neighbors', 'share_grad',
             'measure', 'use_pagerank', 'hard_move', 'stop'])
        if status['stop'] is True:
            return p, error, i

        # wait for the `ready` flag to become `True` in order to continue
        # note that, this flag can be changed at any time
        # so for consitently checking this flag, get it directly from redis.
        while utils.get_ready_status() is False:
            sleep(status['tick_frequence'])

        # use the fixed points from previous iteration or not
        if status['hard_move'] is False:
            fixed_ids = []
            fixed_pos = []

        # get newest moved points from client
        if not shared_queue.empty():
            shared_item = shared_queue.get()
            fixed_ids = shared_item['fixed_ids']
            fixed_pos = shared_item['fixed_pos']

        # set the fixed points
        if fixed_ids and fixed_pos:
            p.reshape(-1, 2)[fixed_ids] = fixed_pos

        # calculate gradient and KL divergence
        error, grad = objective(p, *args, **kwargs)

        X_embedded = p.copy().reshape(-1, 2)
        dist_y = pairwise_distances(X_embedded, squared=True)

        if fixed_ids:
            if status['share_grad']:
                share_grad(grad.reshape(-1, 2), dist_y, fixed_ids)
            else:
                grad.reshape(-1, 2)[fixed_ids] = 0.0

        # calculate the magnitude of gradient of each point
        grad_per_point = linalg.norm(grad.reshape(-1, 2), axis=1)
        gradients_acc += grad_per_point
        # grad_norm = linalg.norm(grad)
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

        if (i % status['n_jump'] == 0):           
            if status['use_pagerank'] and i % 50 == 0:
                print("Iteration: {}: calculate pagerank...".format(i), end='')
                
                min_d, max_d = np.min(dist_y), np.max(dist_y)
                threshold = (max_d - min_d) * 0.001
                mask = dist_y < threshold
                g = nx.from_numpy_matrix(1.0*mask)
                pageranks = list(nx.pagerank_numpy(g).values())
                hubs = list(nx.hits_numpy(g)[0].values())
                # gradients_acc = np.array(list(ranks.values()))
                print("Done!")
            else:
                # gradients_acc += grad_per_point
                pass

            if status['measure'] is True:
                trustwth = trustworthiness(dist_X_original, X_embedded,
                                           n_neighbors=10, precomputed=True)
                trustworthinesses.append(trustwth)

                stability, convergence = PIVE_measure(
                    old_p, p, dist_X_original)
                stabilities.append(stability)
                convergences.append(convergence)

                score = run_classify(X_embedded)
                classification_scores.append(score)

                errors.append(error)
                grad_norms.append(float(grad_norm))

                client_data = {
                    'embedding': X_embedded.ravel().tostring().decode('latin-1'),
                    'gradients': gradients_acc.tolist(),
                    'seriesData': [
                        {'name': 'errors', 'series': [errors]},
                        {'name': 'classification score', 'series': [classification_scores]},
                        {'name': 'trustworthinesses,statbility,convergence',
                            'series': [trustworthinesses, stabilities, convergences]},
                        {'name': 'gradients norms', 'series': [grad_norms]},
                        {'name': 'HUBS', 'series': [hubs]},
                        {'name': 'Pageranks', 'series': [pageranks]}
                    ]
                }
                utils.publish_data(client_data)

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


def share_grad(grad2d, dist_y, fixed_ids, k = 10):
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


if __name__ == '__main__':
    import matplotlib.pyplot as plt

    plt.figure(figsize=(6, 5))
    colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
              "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]

    def plot(X_2d, y, name='../results/tsne_plot.png'):
        target_ids = range(len(y))
        for i, c, label in zip(target_ids, colors, y):
            plt.scatter(X_2d[y == i, 0], X_2d[y == i, 1], c=c, label=label)
        plt.legend()
        plt.savefig(name)
        plt.gcf().clear()

    X, y = utils.load_dataset(name='MNIST')

    perplexity_to_try = [50]  # range(5, 51, 5)
    max_iter_to_try = [4000]  # range(1000, 5001, 1000)

    all_runs = len(perplexity_to_try) * len(max_iter_to_try)
    n_run = 0

    for perplexity in perplexity_to_try:
        for max_iter in max_iter_to_try:
            n_run += 1
            print("\n\n[START]Run {}: per={}, it={} \n".format(
                n_run, perplexity, max_iter))

            tic = time()
            tsne = TSNE(
                n_components=2,
                random_state=0,
                init='random',
                n_iter_without_progress=300,
                n_iter=max_iter,
                perplexity=perplexity,
                verbose=2
            )
            X_2d = tsne.fit_transform(X)
            toc = time()
            duration = toc - tic
            print("[DONE]Duration={}\n".format(duration))

            output_name = '../results/tsne_full_perp{}_it{}.png'.format(
                perplexity, max_iter)
            plot(X_2d, y, output_name)
