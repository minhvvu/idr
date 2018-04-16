import dash
import dash_html_components as html
import dash_core_components as dcc
import plotly.graph_objs as go
from scipy.spatial.distance import cosine
from dataset_utils import load_dataset

import random

# some global vars for easily access
dataX = None
target_labels = None
target_names = None

constraints = []

datasets = {
    "MNIST mini": "MNIST-SMALL",
    "COIL-20": "COIL20",
    "MNIST 2000 samples": "MNIST-2000",
    "Country Indicators 1999": "COUNTRY1999",
    "Country Indicators 2013": "COUNTRY2013",
    "Country Indicators 2014": "COUNTRY2014",
    "Country Indicators 2015": "COUNTRY2015",
    "Cars and Trucks 2004": "CARS04",
    "Breast Cancer Wisconsin (Diagnostic)": "BREAST-CANCER95",
    "Pima Indians Diabetes": "DIABETES",
    "Multidimensional Poverty Measures": "MPI"
}


app = dash.Dash()
app.layout = html.Div([
    dcc.Dropdown(
        id='datasetX',
        options=[{'label': k, 'value': v} for k, v in datasets.items()],
        value=''
    ),
    html.Div(id='dataset-info', children='Dataset Info'),

    dcc.Graph(
        id='scatterX'
    ),

    dcc.RadioItems(
        id='targetLabelX',
        options=[{'label': i, 'value': i} for i in ['Mustlink', 'CannotLink']],
        value='',
        labelStyle={'display': 'inline-block'}
    ),

    html.Div(id='debug-msg', children='Debug message'),
    html.Div(id='support-info', children='Supported Info'),

    html.Button('Submit', id='btn-submit'),
    html.Button('Next', id='btn-next'),
    html.Button('Done', id='btn-done'),
])


@app.callback(dash.dependencies.Output('dataset-info', 'children'),
              [dash.dependencies.Input('datasetX', 'value')])
def update_dataset(dataset_name):
    if not dataset_name:
        return 'Please select a dataset!'

    global dataX
    global target_labels
    global target_names
    dataX, target_labels, target_names = load_dataset(dataset_name)
    dataset_info = 'dataX: {}'.format(dataX.shape)
    return dataset_info


def _rand_pair(n_max):
    i1 = random.randint(0, n_max - 1)
    i2 = random.randint(0, n_max - 1)
    if i1 == i2:
        return _rand_pair(n_max)
    return (i1, i2)


@app.callback(dash.dependencies.Output('scatterX', 'figure'),
              [dash.dependencies.Input('btn-next', 'n_clicks')])
def show_pair(_):
    if dataX is None or target_names is None:
        return

    n = dataX.shape[0]
    i1, i2 = _rand_pair(n)

    epsilon = 1e-5
    data1 = dataX[i1]
    data2 = dataX[i2]
    sim1 = cosine(data1, data2)

    name1 = target_names[i1]
    name2 = target_names[i2]
    selected_idx = []
    for i in range(len(data1)):
        # consider the features that are different enough
        if abs(data1[i] - data2[i]) > epsilon:
            selected_idx.append(i)

    data1 = data1[selected_idx]
    data2 = data2[selected_idx]

    data1 = data1.tolist() + [data1[0]]
    data2 = data2.tolist() + [data2[0]]
    theta = ['i{}'.format(i) for i in range(len(data1))]

    max_val = max(max(data1), max(data2))

    data = [
        go.Scatterpolar(
            r=data1,
            theta=theta,
            fill='toself',
            name=name1,
        ),
        go.Scatterpolar(
            r=data2,
            theta=theta,
            fill='toself',
            name=name2
        ),
    ]

    layout = go.Layout(
        title="""
            {} distinguishable features.
            Cosine distance = {:.4f}.
        """.format(len(data1), sim1),
        polar=dict(
            radialaxis=dict(
                visible=False,
                range=[0.0, max_val]
            ),
            angularaxis=dict(
                visible=True,
                showticklabels=False
            )
        ),
        showlegend=True,
        legend=dict(orientation="h")
    )

    return {'data': data, 'layout': layout}


@app.callback(
    dash.dependencies.Output('debug-msg', 'children'),
    [dash.dependencies.Input('btn-submit', 'n_clicks')],
    [dash.dependencies.State('targetLabelX', 'value')])
def update_output(_, link_type):
    return 'You decision: {}'.format(link_type)


if __name__ == '__main__':
    app.run_server(debug=True)
