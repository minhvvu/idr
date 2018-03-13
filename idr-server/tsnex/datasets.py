from sklearn import datasets
from sklearn.metrics.pairwise import pairwise_distances
from sklearn.utils import shuffle
import numpy as np
import networkx as nx
import pickle
from functools import partial


def load_dataset(name='MNIST-SMALL'):
    return {
        'COIL20': load_coil20,
        'MNIST': load_mnist_full,
        'MNIST-SMALL': load_mnist_mini,
        'WIKI-FR-1K': partial(load_wiki, 'fr'),
        'WIKI-EN-1K': partial(load_wiki, 'en'),
        'WIKI-FR-3K': partial(load_wiki, 'fr', 3000),
        'WIKI-EN-3K': partial(load_wiki, 'en', 3000),
        'COUNTRY1999': partial(load_country, 1999),
        'COUNTRY2013': partial(load_country, 2013),
        'COUNTRY2014': partial(load_country, 2014),
        'COUNTRY2015': partial(load_country, 2015),
        'CARS04': partial(load_pickle, 'cars04'),
        'BREAST-CANCER95': partial(load_pickle, 'breastCancer'),
        'DIABETES': partial(load_pickle, 'diabetes'),
        'MPI': partial(load_pickle, 'MPI_national'),
        'INSURANCE': partial(load_pickle, 'insurance'),
        'FIFA18': partial(load_pickle, 'fifa18', 2000),
        'FR_SALARY': partial(load_pickle, 'FR_net_salary', 2000),
    }[name]()


def load_coil20():
    import scipy.io
    mat = scipy.io.loadmat("../data/COIL20.mat")
    X, y = mat['X'], mat['Y'][:, 0]
    X, y = shuffle(X, y, n_samples=len(y), random_state=0)
    labels = list(map(str, y.tolist()))
    return X, y, labels


def load_mnist_mini():
    dataset = datasets.load_digits()
    X, y = dataset.data, dataset.target
    labels = list(map(str, range(len(y))))
    return X, y, labels


def load_mnist_full(n_samples=2000):
    from sklearn.datasets import fetch_mldata
    dataset = fetch_mldata('MNIST original', data_home='../data/')
    X, y = dataset.data, dataset.target
    X, y = shuffle(X, y, n_samples=n_samples, random_state=0)
    y = y.astype(int)
    labels = list(map(str, range(len(y))))
    return X, y, labels


def load_pickle(name, limit_size=2000):
    inputName = '../data/{}.pickle'.format(name)
    dataset = pickle.load(open(inputName, 'rb'))
    X, labels = dataset['data'], dataset['labels']
    n = min(limit_size, X.shape[0])
    X = X[:n]
    labels = labels[:n]
    if 'y' in dataset:
        y = dataset['y'][:n]
    else:
        y = np.zeros(n)
    print("Data from pickle: ", X.shape, y.shape, len(labels))
    return X, y, labels


def load_wiki(lang='en', n=1000): return load_pickle(name='wiki_{}_n{}_d300'.format(lang,n))


def load_country(year): return load_pickle(name='country_indicators_{}'.format(year))


def calculate_distances(X, k=100):
    distances = pairwise_distances(X, squared=True)
    neighbors = np.argsort(dist, axis=1)[:, 1:k + 1]
    return {'distances': distances.tolist(), 'neighbors': neighbors.tolist()}


def read_bytes_file(inputName):
    inputName = "../data/iris_tensors.bytes"
    import numpy as np
    import struct
    with open(inputName, 'rb') as f:
        print(struct.unpack('f', f.read(4)))


def top_words(outName, k):
    n, d = map(int, input().split(' '))
    data = []
    labels = []
    for i in range(k):
        word, *vec = input().split(' ')[:-1]
        vec = list(map(float, vec))
        labels.append(word)
        data.append(vec)
    pickle.dump({'data': np.array(data), 'labels': labels},
                open(outName, 'wb'))


def pre_calculate(X, k=100, ntop=50, use_pagerank=True):
    """ Calculate the k-nearest neighbors matrix
        Calculate Hubs or Pagerank for each points
    """
    from sklearn.neighbors import NearestNeighbors
    model = NearestNeighbors(n_neighbors=k, algorithm='ball_tree')
    model.fit(X)

    print("Calculate distance")
    distances, indices = model.kneighbors()

    print("Build knn graph")
    nn = model.kneighbors_graph(mode='distance')
    g = nx.from_scipy_sparse_matrix(nn)

    if use_pagerank:
        print("Calculate pagerank", end=',')
        pageranks = nx.pagerank_scipy(g)
        top_important = sorted(pageranks, key=pageranks.get, reverse=True)
    else:
        print("Calculate hits", end=',')
        hubs, authorities = nx.hits_scipy(g)
        top_important = sorted(hubs, key=hubs.get, reverse=True)
    print("\tDone!")

    return {'distances': [],  # distances.tolist(),
            'neighbors': list(map(lambda s: list(map(str, s)), indices)),
            'importantPoints': list(map(str, top_important[:ntop])),
            'infoMsg': 'Dataset size: {}, important points: {}'.format(X.shape, ntop)}



def load_newsgroups():
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.datasets import fetch_20newsgroups
    cats = [
        'comp.graphics',
        'comp.os.ms-windows.misc',
        'comp.sys.ibm.pc.hardware',
        'comp.sys.mac.hardware',
        'comp.windows.x']
    newsgroups_train = fetch_20newsgroups(
        subset='train',
        remove=('headers', 'footers', 'quotes'),
        categories=cats)

    from pprint import pprint
    pprint(list(newsgroups_train.target_names))

    vectorizer = TfidfVectorizer()
    X = vectorizer.fit_transform(newsgroups_train.data)

    y = newsgroups_train.target
    labels = [cats[i] for i in y]

    return X.toarray(), y, labels


if __name__ == '__main__':
    # inputBytesFile = "../data/iris_tensors.bytes"
    # read_bytes_file(inputBytesFile)

    # # run command: cat '/home/vmvu/Dataset/FastText/wiki.fr.vec' | python datasets.py
    # lang, k = 'fr', 1000
    # outputVecFile = '../data/wiki_{}_n{}_d300.pickle'.format(lang,k)
    # top_words(outputVecFile, k)

    # wiki_name = 'wiki_fr_n{}_d300'.format(k)
    # data, y, labels = load_wiki(wiki_name)
    # print(data.shape, y.shape, len(labels))

    # X, y, labels = load_dataset(name='MNIST-SMALL')
    # res = pre_calculate(X)
    # print(res['neighbors'])

    X, y, labels = load_dataset(name='BREAST-CANCER95')
    print(X.shape, y.shape, len(labels))
