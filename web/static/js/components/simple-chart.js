const DEFAULT_COLOR = "#18ACC4";
const WHITE_COLOR = "#FFFFFF";
const BLACK_COLOR = "#000000";

export default class SimpleChart {

  constructor(id, config) {
    this.id = id;
    this.chart = Highcharts.chart(this.id, {
      chart: {
        type: config.type,
        backgroundColor: "rgba(255, 255, 255, 0)",
      },
      title: {
        text: ''
      },
      legend: {
        enabled: true,
        itemStyle: {
          color: "#EEE",
        },
      },
      credits: {
        enabled: false
      },
      pane: {
        center: ['50%', '85%'],
        size: '100%',
        startAngle: -90,
        endAngle: 90,
        background: {
          backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE',
          innerRadius: '60%',
          outerRadius: '90%',
          shape: 'arc'
        }
      },
      xAxis: {
        categories: config.xAxisLabels,
        labels: {
          style:{
            color: WHITE_COLOR,
            fontSize: '15px',
          }
        },
        title: {
          style:{
            color: "#00FF0",
          }
        },
      },
      yAxis: {
        min: 0,
        labels: {
          style:{
            color: WHITE_COLOR,
            fontSize: '15px',
          }
        },
        title: '',
        gridLineColor: "#7D8C93"
      },
      plotOptions: {
        solidgauge: {
          dataLabels: {
            y: 5,
            borderWidth: 0,
            useHTML: true
          }
        },
        column: {
          dataLabels: {
            enabled: true,
            crop: false,
            overflow: 'none',
            color: WHITE_COLOR
          },
          color: DEFAULT_COLOR,
          borderWidth: 0
        },
        line: {
          color: DEFAULT_COLOR
        }
      },
      series: config.series,
      navigation: {
        buttonOptions: {
          text: "EXPORT"
        }
      },
      exporting: {
        chartOptions: {
          title: {
            text: config.title,
            color: BLACK_COLOR
          },
          plotOptions: {
            series: {
              dataLabels: {
                color: BLACK_COLOR
              }
            }
          },
          xAxis: {
            labels: {
              style:{
                color: BLACK_COLOR,
              }
            },
            title: {
              style:{
                color: BLACK_COLOR,
              }
            },
          },
          yAxis: {
            min: 0,
            labels: {
              style:{
                color: BLACK_COLOR,
              }
            }
          }
        }
      }
    });

  }

  getSeries(index) {
    return this.chart.series[index];
  }
};
