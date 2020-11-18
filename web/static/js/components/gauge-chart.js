export default class GaugeChart {

  constructor(id, config) {
    this.id = id;
    this.chart = Highcharts.chart(this.id, {
      chart: {
        type: 'gauge',
        backgroundColor: "rgba(255, 255, 255, 0)",
        plotBackgroundColor: null,
        plotBackgroundImage: null,
        plotBorderWidth: 0,
        plotShadow: false
      },

      credits: {
        enabled: false
      },

      title: {
        text: config.title,
        style:{
          color: "#c2c9cb",
          fontSize: "18px"
        }
      },

      pane: {
        startAngle: -150,
        endAngle: 150,
        background: [{
          backgroundColor: {
            linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
            stops: [
              [0, '#FFF'],
              [1, '#333']
            ]
          },
          borderWidth: 0,
          outerRadius: '109%'
        }, {
          backgroundColor: {
            linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
            stops: [
              [0, '#333'],
              [1, '#FFF']
            ]
          },
          borderWidth: 1,
          outerRadius: '107%'
        }, {
          // default background
        }, {
          backgroundColor: '#DDD',
          borderWidth: 0,
          outerRadius: '105%',
          innerRadius: '103%'
        }]
      },

      // the value axis
      yAxis: {
        min: 0,
        max: 200,

        minorTickInterval: 'auto',
        minorTickWidth: 1,
        minorTickLength: 10,
        minorTickPosition: 'inside',
        minorTickColor: '#666',

        tickPixelInterval: 30,
        tickWidth: 2,
        tickPosition: 'inside',
        tickLength: 10,
        tickColor: '#666',
        labels: {
          step: 2,
          rotation: 'auto'
        },
        title: {
          text: config.innerTitle || `% ${config.title}`
        },
        plotBands: [{
          from: 0,
          to: 100,
          color: '#DF5353' // green
        }, {
          from: 100,
          to: 200,
          color: '#55BF3B' // yellow
        }]
      },
      series: [{
        name: config.title,
        data: [ 0 ],
        tooltip: {
          valueSuffix: config.tooltip
        }
      }]
    });

  }

  getSeries(index) {
    return this.chart.series[index];
  }

  destroy() {
    this.chart.destroy();
  }
};
