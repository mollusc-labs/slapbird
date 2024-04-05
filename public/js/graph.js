const DASHBOARD_GRAPH_ELEM = document.getElementById('dashboardGraph');
const DASHBOARD_GRAPH_URI = DASHBOARD_GRAPH_ELEM.getAttribute('value');
const NUM_FACTORS = 500.0;

const makeGraph = (data) => {
  const urlParams = new URLSearchParams(window.location.search);

  let from = Number.parseFloat(urlParams.get('from') ?? Date.now() - 3_600_000);
  let to = Number.parseFloat(urlParams.get('to') ?? Date.now());
  let d = to - from;
  let iter = d / NUM_FACTORS;

  let labelMillis = [];

  for (let i = 0; i <= NUM_FACTORS - 1; i++) {
    labelMillis.push(from + (iter * i));
  }

  let labels = labelMillis.map(n => new Date(n));

  const temp = [...Array(1000).keys()].map(() => 0);

  let bgColor = 'rgba(0, 0, 0, 0)';
  let plotBgColor = 'rgba(0,0,0,0)';
  let fontColor = '#888';

  let warnColor = '#947600';
  let successColor = '#257942';
  let errorColor = '#CC0F35';

  let errorOptions = {
    hovertemplate:
      '<i>Requests</i>: %{y}' +
      '<br>%{x}<br>',
    x: labels,
    type: 'scatter',
    mode: 'lines',
    name: 'Errors',
    line: {
      color: errorColor
    },
    y: [...temp]
  };

  let warnOptions = {
    hovertemplate:
      '<i>Requests</i>: %{y}' +
      '<br>%{x}<br>',
    x: labels,
    type: 'scatter',
    mode: 'lines',
    name: 'Warnings',
    line: {
      color: warnColor
    },
    y: [...temp]
  };

  let normOptions = {
    hovertemplate:
      '<i>Requests</i>: %{y}' +
      '<br>%{x}<br>',
    x: labels,
    type: 'scatter',
    mode: 'lines',
    name: 'Success',
    line: {
      color: successColor
    },
    y: [...temp]
  };

  const _makeGraph = () => {
    Plotly.newPlot('dashboardGraph', [normOptions, warnOptions, errorOptions], {
      displayModeBar: false,
      responsive: true,
      paper_bgcolor: bgColor,
      plot_bgcolor: plotBgColor,
      margin: {
        t: 20,
        l: 70,
        r: 20,
        b: 20
      },
      xaxis: {
        automargin: true,
        showgrid: false
      },
      yaxis: {
        automargin: true,
        showgrid: false,
        title: {
          text: 'Requests',
          font: {
            size: 18,
            color: fontColor
          }
        }
      },
      font: {
        color: fontColor,
        font: {
          family: '$family-primary'
        }
      }
    });
  };

  if (!data.length) {
    _makeGraph();
    return;
  }

  let curr = data.shift();

  const dispatchCurr = (idx) => {
    if (curr.was_error) {
      errorOptions.y[idx]++;
    } else if (curr.response_code >= 400 && curr.response_code < 500) {
      warnOptions.y[idx]++;
    } else {
      normOptions.y[idx]++;
    }
  };

  for (let i = 0; i < labelMillis.length; i++) {
    if (!curr) {
      break;
    }

    if (i === 0) {
      while (curr && curr.start_time >= labelMillis[i - 1]) {
        dispatchCurr(i);
        curr = data.shift();
      }
    }

    if (i === labelMillis.length - 1) {
      while (curr && curr.start_time <= labelMillis[i + 1]) {
        dispatchCurr(i);
        curr = data.shift();
      }
    }

    while (curr &&
      curr.start_time >= labelMillis[i - 1] &&
      curr.start_time <= labelMillis[i + 1]
    ) {
      dispatchCurr(i);
      curr = data.shift();
    }
  }

  _makeGraph();
};

const refreshGraph = () => {
  axios.get(DASHBOARD_GRAPH_URI)
    .then(response => {
      makeGraph(response.data);
    })
    .catch(error => {
      if (error &&
        error.response &&
        error.response.status === 409) {
        makeGraph([]);
        return;
      }
      DASHBOARD_GRAPH_ELEM.innerHTML = `
      <article class="message is-danger">
        <div class="message-body">
          Something went wrong loading this services graph. Please try again later.
        </div>
      </article>
    `;
    });
};

refreshGraph();