# test metrics

import math
import numpy as np
import time
import timeit

# import all Adrien's metric function
from Adrien_metrics.Correlation_Coefficient import Correlation_Coefficient as Corr
from Adrien_metrics.K_Neighborhood import K_Neighborhood as LogRNX
from Adrien_metrics.Curvilinear_Component_Analysis import CCA as CCA
from Adrien_metrics.Sammon_s_Non_Linear_Mapping import NLM as NLM
from Adrien_metrics.Stress_Function import Stress as MDS


# import Minh's metric function
from metrics import DRMetric

# import sklearn
from sklearn import datasets
from sklearn.manifold import TSNE

rel_tol = 1e-3

# prepare test dataset
# ds = datasets.load_iris()
# X_hd = ds.data
# target_labels = ds.target

X_hd, target_labels = datasets.samples_generator.make_swiss_roll(
    n_samples=100, random_state=0) # make_s_curve


# run tsne to get embedded result in low dim.
tsne = TSNE(random_state=0)
print(tsne)
X_ld = tsne.fit_transform(X_hd)

# create DRMetric object
tic = time.time()
drMetric = DRMetric(X_hd, X_ld)
init_time = time.time() - tic

test_suites = {
    'Test logRNX': [LogRNX.compute, drMetric.auc_rnx],
    'Test CorrCoef': [Corr.compute, drMetric.pearsonr],
    'Test MDS Stress': [MDS.compute, drMetric.mds_isotonic],
    'Test CCA Stress': [CCA.compute, drMetric.cca_stress],
    #'Test Sammon NLM': [NLM.compute, drMetric.sammon_nlm],
}

print("Start test suite")
for test_name, funcs in test_suites.items():
    print(test_name)
    tic = time.time()
    m1 = funcs[0](X_hd, X_ld)
    run1 = time.time() - tic
    print("m1 = {:10.4f} ({:10.4f} s)".format(m1, run1))

    tic = time.time()
    m2 = funcs[1]()
    run2 = time.time() - tic
    print("m2 = {:10.4f} ({:10.4f} s)".format(m2, run2))

    assert math.isclose(m1, m2, rel_tol=rel_tol, abs_tol=0.0) is True
