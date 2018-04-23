"""
    Auto generated constraints or pre-defined constraints
"""

import numpy as np
import random
import pickle

fixed_random_seed = 0
random.seed(fixed_random_seed)


def get_constraints(target_labels=None, dataset_name=None, n_take=0):
    if target_labels is None:
        return _fixed_constraints(dataset_name)
    else:
        return _generated_constraints(target_labels, n_take)


def _generated_constraints(target_labels, n_take, nlimit=1000):
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


def _fixed_constraints(dataset_name, n_take):
    base_dir = 'manual_constraints'
    input_name = '{}/done_{}.pkl'.format(base_dir, dataset_name)
    pkl_data = pickle.load(open(input_name, 'rb'))
    mustlinks = np.array(pkl_data['mustlinks'][:n_take])
    cannotlinks = np.array(pkl_data['cannotlinks'][:n_take])
    return mustlinks, cannotlinks


if __name__ == '__main__':
    mls, cls = _fixed_constraints(dataset_name='DIABETES', n_take=10)
    print(mls, cls)
