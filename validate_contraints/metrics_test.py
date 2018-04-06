# test metrics

import math
import numpy as np
import timeit

# import all Adrien's metric function
from Adrien_metrics.Correlation_Coefficient import Correlation_Coefficient as Corr
from Adrien_metrics.Curvilinear_Component_Analysis import CCA as CCA
from Adrien_metrics.K_Neighborhood import K_Neighborhood as logRNX
from Adrien_metrics.Sammon_s_Non_Linear_Mapping import NLM as SOM
from Adrien_metrics.Stress_Function import Stress as MDSStress


# import Minh's metric function
from metrics import DRMetric

# import sklearn
from sklearn import datasets
from sklearn.manifold import TSNE

rel_tol = 1e-3

# prepare test dataset
ds = datasets.load_iris()
X_hd = ds.data
target_labels = ds.target

# run tsne to get embedded result in low dim.
tsne = TSNE(random_state=None)
print(tsne)
X_ld = tsne.fit_transform(X_hd)

# create DRMetric object
drMetric = DRMetric(X_hd, X_ld)

# test logRNX
m1 = logRNX.compute(X_hd, X_ld)
m2 = drMetric.auc_rnx()
print('Test logRNX', m1, m2)
# np.testing.assert_almost_equal(m1, m2)
assert math.isclose(m1, m2, rel_tol=rel_tol, abs_tol=0.0) is True

# test correlation coefficient
m1 = Corr.compute(X_hd, X_ld)
m2 = drMetric.pearsonr()
print('Test correlation coefficient', m1, m2)
# np.testing.assert_almost_equal(m1, m2)
assert math.isclose(m1, m2, rel_tol=rel_tol, abs_tol=0.0) is True

# def f1(): return Corr.compute(X_hd, X_ld)
# t1 = timeit.timeit(f1, number=20)
# t2 = timeit.timeit(drMetric.pearsonr, number=20)
# print(t1, t2)