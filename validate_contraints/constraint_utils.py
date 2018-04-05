"""
    Auto generated constraints or pre-defined constraints
"""

import numpy as np
import random
fixed_random_seed = 0
random.seed(fixed_random_seed)


def get_constraints(target_labels=None, dataset_name=None, n_take=0):
    if target_labels is None:
        return _fix_constraints(dataset_name)
    else:
        return _generate_constraints(target_labels, n_take)


def _generate_constraints(target_labels, n_take, nlimit=1000):
    mustlinks = []
    cannotlinks = []
    cnt = 0
    while cnt < nlimit:
        i1 = random.randint(0, len(target_labels) - 1)
        i2 = random.randint(0, len(target_labels) - 1)
        if i1 == i2:
            continue
        if target_labels[i1] == target_labels[i2]:
            mustlinks.append([i1, i2])
        else:
            cannotlinks.append([i1, i2])
        cnt += 1

    mustlinks = np.array(mustlinks[:n_take])
    cannotlinks = np.array(cannotlinks[:n_take])
    return mustlinks, cannotlinks


def _fix_constraints(dataset_name):
    pass
