# plot utils

import matplotlib.pyplot as plt
import utils

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


if __name__ == '__main__':
    X, y = utils.load_dataset(name='MNIST')
    data_size = 28
    generate_svg_stack('mnist-full600-test1', X, 1, data_size)
