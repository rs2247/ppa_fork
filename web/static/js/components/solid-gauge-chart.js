export default class SolidGaugeChart {

  constructor(id, config) {
    this.id = id;
    this.chart = Highcharts.chart(this.id, {
      chart: {
        type: 'solidgauge',
        backgroundColor: "rgba(255, 255, 255, 0)",
      },
      credits: {
        enabled: false
      },
      title: "",
      pane: {
        center: ['50%', '85%'],
        size: '100%',
        startAngle: -90,
        endAngle: 90,
        background: {
          backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE',
          innerRadius: '60%',
          outerRadius: '100%',
          shape: 'arc'
        }
      },
      yAxis: {
        min: 0,
        max: 100,
        title: {
          y: -170,
          text: config.title,
          style:{
            color: "#c2c9cb",
          }
        },
        stops: [
          [0.1, '#55BF3B'], // green
          [0.5, '#DDDF0D'], // yellow
          [0.9, '#DF5353'] // red
        ],
        lineWidth: 0,
        minorTickInterval: null,
        tickAmount: 2,
        labels: {
          y: 16
        }
      },

      plotOptions: {
        solidgauge: {
          dataLabels: {
            y: 5,
            borderWidth: 0,
            useHTML: true
          }
        }
      },
      series: [{
        name: config.tooltip || "",
        data: [],
        dataLabels: {
          format: '<div style="text-align:center"><span style="font-size:25px;color:' +
          ((Highcharts.theme && Highcharts.theme.contrastTextColor) || '#c2c9cb') + '">{y:.1f}</span></div>'
        },
        tooltip: {
          valueSuffix: ' %'
        }
       }]
    });

  }

  getSeries(index) {
    return this.chart.series[index];
  }
};

