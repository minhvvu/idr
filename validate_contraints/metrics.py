# some metric measurement for DR methods

import numpy as np
from scipy.spatial.distance import pdist, squareform


class DRMetric(object):
    """ Metric measurement for DR methods
    """

    def __init__(self, X, Y):
        """ Create Metric object
        Args:
            X (ndarray): input data in high dimensional space
            Y (ndarray): embedded result in low dimensional space

        """
        super(DRMetric, self).__init__()
        # data shape
        self.n_samples = X.shape[0]
        self.n_high_dim = X.shape[1]
        self.n_low_dim = Y.shape[1]

        # store high-dim and low-dim data
        self.X = X
        self.Y = Y

        # pre-calculate pairwise distance in high-dim and low-dim
        self.dX = squareform(pdist(self.X, "sqeuclidean"))
        self.dY = squareform(pdist(self.Y, "sqeuclidean"))

        # index of all neighbors with ascending distances
        self.idX = np.argsort(self.dX, axis=1)[:, 1:]
        self.idY = np.argsort(self.dY, axis=1)[:, 1:]

    def _Qnx(self, k):
        """Calculate $Q_{NX}(k)= \\
          \frac{1}{Nk} \sum_{i=1}^{N} |v_{i}^{k} \cap n_{i}^{k}| $
        Args:
            k (int): number of neighbors
        Returns:
            float: value of Q
        """
        assert 1 <= k <= self.n_samples - 1
        Vk = self.idX[:, :k]
        Nk = self.idY[:, :k]
        q_nx = sum([len(set(a) & set(b)) for a, b in zip(Vk, Nk)])
        q_nx /= (k * self.n_samples)

        assert 0.0 <= q_nx <= 1.0
        return q_nx

    def _Rnx(self, k):
        """Calculate rescaled version of $Q_{NX}(k)$
          $R_{NX}(k) =  \frac{(N-1) Q_{NX}(k) - k}{N - 1 - k} $
        Args:
            k (int): number of neighbors
        Returns:
            float: value of R
        """
        return ((self.n_samples - 1) * self._Qnx(k) - k) / \
            (self.n_samples - 1 - k)

    def auc_rnx(self):
        """Calculate Area under the $R_{NX}(k)$ curve in the log-scale of $k$
        """
        numerator = sum([self._Rnx(k) / k for k in range(1, self.n_samples-1)])
        denominator = sum([1.0 / k for k in range(1, self.n_samples - 1)])
        return numerator / denominator
