# tsnex.py
import sklearn
from sklearn import datasets
from sklearn.manifold import TSNE

import numpy as np
from numpy import linalg
from time import time

iris = datasets.load_digits()

X_train = iris.data[:500]
y = iris.target[:500]
print(X_train.shape)
print(len(y))


def test_embedding():
    old_gradient_fnc = sklearn.manifold.t_sne._gradient_descent

    positions = []

    def _gradient_descent(objective, p0, it, n_iter,
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
        for i in range(it, n_iter):
            # save the current position
            positions.append(p.copy())

            error, grad = objective(p, *args, **kwargs)
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
                    break

        return p, error, i

    sklearn.manifold.t_sne._gradient_descent = _gradient_descent

    tsne = TSNE(n_components=2, random_state=0, n_iter=1000)

    X_projected = tsne.fit_transform(X_train)

    X_iter = np.dstack(position.reshape(-1, 2) for position in positions)
    print(X_iter.shape)

    sklearn.manifold.t_sne._gradient_descent = old_gradient_fnc

    return (X_iter, y)


test_embedding()
