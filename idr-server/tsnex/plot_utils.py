# plot utils

import matplotlib.pyplot as plt
import utils
import datasets
from io import BytesIO
import base64


svgMetaData = """<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Created with matplotlib (http://matplotlib.org/), modified to stack multiple svg elemements -->
<svg version="1.1" width="22" height="22" viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
 <defs>
  <style type="text/css">
    *{stroke-linecap:butt;stroke-linejoin:round;}
    .sprite { display: none;}
    .sprite:target { display: inline; }
    .myimg {  filter: invert(100%); }
  </style>
 </defs>
"""

svgImgTag = """
<g class="sprite" id="{}">
    <image class="myimg" id="img_{}" width="20" height="20" xlink:href="data:image/png;base64,{}"/>
</g>
"""

current_dpi = plt.gcf().get_dpi()
fig = plt.figure(figsize=( 28/current_dpi, 28/current_dpi ))

def generate_figure_data(idx, data, data_size):
    figFile = BytesIO()
    plt.imsave(figFile, data.reshape(data_size, data_size), cmap=plt.cm.gray_r)
    plt.gcf().clear()
    figFile.seek(0)
    return base64.b64encode(figFile.getvalue()).decode('utf-8')


def generate_svg_stack(dataset_name, X, n, data_size):
    outfile = '../data/imgs/{}.svg'.format(dataset_name)
    with open(outfile, "w") as svgFile:
        svgFile.write(svgMetaData)
        for i in range(n):
            utils.print_progress(i, n)
            figData = generate_figure_data(i, X[i], data_size)
            svgFile.write(svgImgTag.format(i, i, figData))
        svgFile.write("</svg>")


def plot_default_tsne():
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

    X, y, labels = datasets.load_dataset(name='MNIST')

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


if __name__ == '__main__':
    # X, y = utils.load_dataset(name='MNIST')
    # data_size = 28
    # generate_svg_stack('mnist-full600-test1', X, 1, data_size)
    pass
