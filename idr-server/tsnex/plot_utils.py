# plot utils

import matplotlib.pyplot as plt
import utils

from io import BytesIO
import base64

svgMetaData = """<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Created with matplotlib (http://matplotlib.org/), modified to stack multiple svg elemements -->
<svg version="1.1" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
 <defs>
  <style type="text/css">
    *{stroke-linecap:butt;stroke-linejoin:round;}
    .sprite { display: none; }
    .sprite:target { display: inline; }
  </style>

  <clipPath id="common-clippath">
   <rect height="20" width="20" x="28" y="6"/>
  </clipPath>

 </defs>
"""

svgImgTag = """
<g class="sprite" id="{}" clip-path="url(#common-clippath)">
    <image id="img_{}" xlink:href="data:image/png;base64,{}"/>
</g>
"""

current_dpi = plt.gcf().get_dpi()
plt.figure(figsize=( 28/current_dpi, 28/current_dpi ))

def generate_figure_data(idx, data, data_size):
    figFile = BytesIO()
    plt.imshow(data.reshape(data_size, data_size),
        cmap=plt.cm.gray_r, interpolation='nearest')
    plt.axis('off')
    plt.savefig(figFile, bbox_inches='tight', pad_inches = 0, dpi=current_dpi)
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
    X, y = utils.load_dataset(name='MNIST-SMALL')
    data_size = 8
    generate_svg_stack('mnist-small', X, len(y), data_size)