# some metric measurement for DR methods

import math
import numpy as np
from numpy.linalg import norm
from scipy.spatial.distance import pdist, squareform
from scipy.stats import pearsonr
from sklearn.preprocessing import scale
from sklearn.isotonic import IsotonicRegression

MACHINE_EPSILON = np.finfo(np.double).eps


class DRMetric(object):
    """ Metric measurements for DR methods
    """

    def __init__(self, X, Y):
        """ Create Metric object
        Args:
            X (ndarray): input data in high dimensional space
            Y (ndarray): embedded result in low dimensional space
        """
        super(DRMetric, self).__init__()
        self.n_samples = X.shape[0]
        # self.n_high_dim = X.shape[1]
        # self.n_low_dim = Y.shape[1]

        self.X = X
        self.Y = Y

        # pre-calculate pairwise distance in high-dim and low-dim
        self.dX = pdist(X, "euclidean")
        self.dY = pdist(Y, "euclidean")
        # self.dX = np.maximum(self.dX, MACHINE_EPSILON)
        # self.dY = np.maximum(self.dY, MACHINE_EPSILON)

        # index of all neighbors with ascending distances
        dXSquare = squareform(self.dX**2)
        dYSquare = squareform(self.dY**2)
        self.idX = np.argsort(dXSquare, axis=1)[:, 1:]
        self.idY = np.argsort(dYSquare, axis=1)[:, 1:]

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
        q_nx = sum([np.intersect1d(a, b, assume_unique=True).size
                    for a, b in zip(Vk, Nk)])
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
        assert 1 <= k <= self.n_samples - 2
        rnx = (self.n_samples - 1) * self._Qnx(k) - k
        rnx /= (self.n_samples - 1 - k)
        return rnx

    def auc_rnx(self):
        """Calculate Area under the $R_{NX}(k)$ curve in the log-scale of $k$
        """
        auc = sum([self._Rnx(k) / k for k in range(1, self.n_samples - 1)])
        norm_const = sum([1 / k for k in range(1, self.n_samples - 1)])
        auc /= norm_const
        assert 0.0 <= auc <= 1.0
        return auc

    def pearsonr(self):
        """Calculate Pearson correlation coefficient b.w. two vectors
        """
        p, _ = pearsonr(self.dX, self.dY)
        return p

    def cca_stress(self):
        """Curvilinear Component Analysis Stress function
            $$ S = \sum_{ij}^{N}
                (d^{x}_{ij} - d^{y}_{ij})^2 F_{\lambda}(d^{y}_{ij})
            $$
            where $d^{x}_{ij}$ is pairwise distance in high-dim,
            $d^{y}_{ij}$ is pairwise distance in low-dim,
            $F_{\lambda}(d^{*}_{ij}$ is decreasing weighting-function.
            For CCA, there are some choises for weighting-function:
            e.g. step function (depends $\lambda$), exponential func or
            $F(d^{y}_{ij}) = 1 - sigmoid(d^{y}_{ij}$.
        """
        dX = scale(self.dX)
        dY = scale(self.dY)
        diff = dX - dY
        weight = 1.0 - 1.0 / (1.0 + np.exp(-dY))
        stress = np.dot(diff**2, weight)
        return stress

    def mds_isotonic(self):
        """Stress function of MDS
            + Pairwise distances vector in high-dim is fitted into an
            Isotonic Regression model
            + The stressMDS function is then applied for the isotonic-fitted
            vector and the pairwise distance vector in low-dim
            $$ S = \sqrt
                { \sum_{ij}^{N} (d^{iso}_{ij} - d^{y}_{ij})^2 }
                { \sum_{ij}^{N} d^{y}_{ij} }
            $$
            where $d^{y}_{ij}$ is pairwise distance in low-dim.
        """
        dX = scale(self.dX)
        dY = scale(self.dY)
        ir = IsotonicRegression()
        dYh = ir.fit_transform(X=dX, y=dY)
        return norm(dYh - dY) / norm(dY)

    def sammon_nlm(self):
        """Stree function for Sammon Nonlinear mapping
            $ S = \frac{1}{\sum_{ij} d^{x}_{ij}}
                \sum_{ij} \frac{ (d^{x}_{ij} - d^{y}_{ij})^2 }{d^{x}_{ij}]}
            $
        """
        dX_inv = 1.0 / self.dX
        dX_inv[np.isinf(dX_inv)] = 0
        diff = self.dX - self.dY
        stress = np.dot((diff ** 2), dX_inv)
        return stress / self.dX.sum()
