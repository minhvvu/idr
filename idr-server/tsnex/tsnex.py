# tsnex.py
# interactive tsne:
# https://www.oreilly.com/learning/an-illustrated-introduction-to-the-t-sne-algorithm

import sklearn
from sklearn.manifold import TSNE
import numpy as np
from numpy import linalg
from time import time, sleep
import json
import utils

import matplotlib.pyplot as plt

shared_interaction = {'queue': None}

def boostrap_do_embedding(X, max_iter=500, shared_queue=None):
    """
    Boostrap to start doing embedding:
    Initialize the tsne object, setup params
    """
    print("[TSNEX] Thread to do embedding is starting ... ")

    shared_interaction['queue'] = shared_queue

    sklearn.manifold.t_sne._gradient_descent = my_gradient_descent
    tsne = TSNE(
        n_components=2,
        random_state=0,
        n_iter_without_progress=500,
        n_iter=max_iter,
        verbose=1
    )
    tsne._EXPLORATION_N_ITER = 250
    tsne.init = 'random'

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

    shared_queue = shared_interaction['queue']
    fixed_ids = []
    fixed_pos = []

    print("\nGradien Descent:")
    for i in range(it, n_iter):

        status = utils.get_server_status(['n_jump', 'tick_frequence'])
        if (i % status['n_jump'] == 0):
            utils.publish_data(p.copy())
            utils.print_progress(i, n_iter)
            
            # pause, while the other thread sends the published data to client
            sleep(status['tick_frequence'])

        # wait for the `ready` flag to become `True` in order to continue
        # note that, this flag can be changed at any time
        # so for consitently checking this flag, get it directly from redis.
        while False == utils.get_ready_status():
            sleep(status['tick_frequence'])

        # get newest moved points from client
        if not shared_queue.empty():
            shared_item = shared_queue.get()
            fixed_ids = shared_item['fixed_ids']
            fixed_pos = shared_item['fixed_pos']

        # set the fixed points
        if fixed_ids and fixed_pos:
            p2d = p.reshape(-1, 2)
            p2d[fixed_ids] = fixed_pos
            p = p2d.ravel()
        
        error, grad = objective(p, *args, **kwargs)
        if fixed_ids:
            grad2d = grad.reshape(-1, 2)
            grad2d[fixed_ids] = 0
            grad = grad2d.ravel()
        grad_norm = linalg.norm(grad)

        inc = update * grad < 0.0
        dec = np.invert(inc)
        gains[inc] += 0.2
        gains[dec] *= 0.8
        np.clip(gains, min_gain, np.inf, out=gains)
        grad *= gains
        update = momentum * update - learning_rate * grad
        p += update

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
                break
            if grad_norm <= min_grad_norm:
                if verbose >= 2:
                    print("[t-SNE] Iteration %d: gradient norm %f. Finished."
                          % (i + 1, grad_norm))
                # break

    return p, error, i


if __name__ == '__main__':
    X, y = utils.load_dataset(name='MNIST')
    tsne = TSNE(
        n_components=2,
        random_state=0,
        init='random',
        n_iter_without_progress=500,
        n_iter=1000,
        verbose=1
    )
    X_2d = tsne.fit_transform(X)
    target_ids = range(len(y))

    plt.figure(figsize=(6, 5))
    colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]
    for i, c, label in zip(target_ids, colors, y):
        plt.scatter(X_2d[y == i, 0], X_2d[y == i, 1], c=c, label=label)
    plt.legend()
    plt.show()

    