<template>
  <div style="position: relative;">
    <div class="loader-container centered-loader-container" v-if="loading">
      <div class="loader"></div>
    </div>
    <div style="display: flex; justify-content: flex-end;" v-show="exportLink">
      <div  class="dropdown" style="height: auto !important; border: 0 !important;" data-ref="export-data">
        <div class="" style="height: auto !important;" data-toggle="dropdown">
          <span style="" class="glyphicon glyphicon-download"></span>
        </div>
        <ul class="dropdown-menu dropdown-menu-right">
          <li><a class="clickable" :download="exportFileName" ref="exportLink">Figura</a></li>
          <li><a class="clickable" @click="exportData()">Dados</a></li>
        </ul>
      </div>
    </div>

    <scatter-chart ref="chart"
      :data="chartData"
      :options="chartOptions"
      :height="baseHeight">
    </scatter-chart>
    <scatter-chart ref="exportChart" :data="exportChartData" style="z-index: -1; position: absolute; width: 100%; top: 19px;"
      :options="exportChartOptions"
      :height="baseHeight"></scatter-chart>
  </div>
</template>

<script>
import _ from 'lodash';
import ScatterChart from '../js/components/vue-charts/scatter-chart'
import Chartjs from 'chart.js'
import moment from 'moment';

export default {
  data() {
    return {
      loading: false,
      baseSeriesColors: ['#35b6cc', '#fdc029', '#09b67c', '#bf265f'],
      chartData: {
        labels: [],
        datasets: []
      },
      exportChartData:  {
        labels: [],
        datasets: []
      },
      exportChartOptions: {},
      chartOptions: {
        layout: {
          padding: {
            left: 0,
            right: 0,
            top: 50,
            bottom: 0
          }
        },
        tooltips: {
          enabled: true,
        },
        extended: {
          drawRectangles: false,
          rectangles: [],
          drawValuesInChart: false,
          drawPercentageValuesInChart: false,
          useAlternativeDataSet: false,
        },
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        legend: {
          position: 'bottom',
          labels: {
            fontColor: 'white',
            usePointStyle: true,
          },
          onClick: this.onLegendClick,
        },
        elements: { point: { radius: 2 } },
        scales: {
          xAxes: [{
            ticks: {
              display: true,
              fontColor: '#ffffff'
            },
            gridLines: {
              display: true,
              drawBorder: true,
            },
            style: {
              color: '#ffffff',
            },
          }],
          yAxes: [{
            position: 'left',
            id: 'y-axis-0',
            ticks: {
              beginAtZero: true,
              display: true,
              fontColor: '#ffffff'
            },
          },{
            position: 'right',
            id: 'y-axis-1',
            ticks: {
              //beginAtZero: true,
              display: true,
              fontColor: '#ffffff'
            },
          }]
        }
      },
    }
  },
  mounted() {
    this.copyOptionsToExport();
  },
  props: {
    exportName: String,
    exportLink: {
      type: Boolean,
      default: function() { return true; },
    },
    baseHeight: {
      type: Number,
      default: function() { return 300; },
    },
  },
  components: {
    ScatterChart,
  },
  computed: {
    exportFileName() {
      if (_.isNil(this.exportName)) {
        return "chart.png";
      }
      return `${this.exportName}.png`;
    },
  },
  methods: {
    nDots(input) {
      if (typeof(input) === 'number') {
        return 1;
      }
      //console.log("nDots: TYPE: " + typeof(input) + " input: " + input);
      var nDots = 0;
      var i = -1;
      while ((i = input.indexOf('.', i+1)) != -1){
        nDots++;
      }
      return nDots;
    },
    removeAditionalDots(input) {
      let first = input.indexOf('.');
      var i = -1;
      //if ((i = input.indexOf('.', first+1)) != -1) {
      while ((i = input.indexOf('.', first+1)) != -1) {
        input = input.slice(0, i) + input.slice(i + 1);
        //console.log("i: " + i + " FIL: " + input);
      }
      return eval(input);
    },
    emptyNull(value) {
      if (_.isNil(value)) {
        return "";
      }
      return value;
    },
    exportData() {
      var baseName = this.exportName;
      if (_.isNil(baseName)) {
        baseName = 'scatter_data';
      }
      var filename = baseName + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
      var content = "Indice";
      //> header
      if (!_.isNil(this.chartOptions.scales.xAxes[0].scaleLabel.labelString)) {
        content = this.chartOptions.scales.xAxes[0].scaleLabel.labelString;
      }
      for (var i = 0; i < this.chartData.datasets.length; i++) {
        content = content + ';' + this.chartData.datasets[i].label;
      }
      content = content + '\n';
      //> content
      let firstDataset = this.chartData.datasets.values().next().value;
      for (var row = 0; row < firstDataset.data.length; row++) {
        content = content + firstDataset.data[row].x;
        for (var i = 0; i < this.chartData.datasets.length; i++) {
          content = content + ';' + this.emptyNull(this.chartData.datasets[`${i}`].data[row].y);
        }
        content = content + '\n';
      }
      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
    solvePlotData(point, index) {
      let chartInstance = this.$refs.chart.$data._chart;
      let mappedData = _.map(chartInstance.data.datasets[index].data, (entry) => {
        return {_model: {x: entry.x, y: entry.y, skip: false}};
      });

      //console.log("mappedData: " + JSON.stringify(mappedData));

      //interpolate!
      let curve = Chartjs.helpers.splineCurveMonotone(mappedData);
      //console.log("curve: " + curve + " mappedData: " + JSON.stringify(mappedData) +" datasets[0]: " + JSON.stringify(chartInstance.data.datasets[0].data[0]));


      let finalMapped = _.reduce(mappedData, (acc, entry) => {
        //console.log("entry._model: " + JSON.stringify(entry._model));
        if (!_.isNil(entry._model["controlPointPreviousX"])) {
          let xValue = eval(entry._model["controlPointPreviousX"]);
          let yValue = entry._model["controlPointPreviousY"];
          if (typeof(yValue) === 'string') {
            if (yValue.indexOf('-') != -1) {
              yValue = eval(yValue);
            } else {
              if (this.nDots(yValue) > 1) {
                //console.log("yValue COM PROBLEMA: " + yValue);
                yValue = this.removeAditionalDots(yValue);
              } else {
                yValue = eval(yValue);
              }
            }
          }

          acc.push({x: xValue, y: yValue });
        }
        acc.push({x: entry._model.x, y: entry._model.y });
        if (!_.isNil(entry._model["controlPointNextX"])) {
          let xValue = eval(entry._model["controlPointNextX"]);
          let yValue = entry._model["controlPointNextY"];
          if (typeof(yValue) === 'string') {
            if (yValue.indexOf('-') != -1) {
              yValue = eval(yValue);
            } else {
              if (this.nDots(yValue) > 1) {
                //console.log("yValue COM PROBLEMA: " + yValue);
                yValue = this.removeAditionalDots(yValue);
              } else {
                yValue = eval(yValue);
              }
            }
          }

          acc.push({x: xValue, y: yValue });
        }
        return acc;
      }, []);


      //se nao tiver um dos pontos, tem que resolver pela curva!
      var xScale = point.x;
      var yScale = point.y;

      if (_.isNil(yScale)) {


        var current = null;
        for (var j = 0; j < finalMapped.length; j++) {
          let next = finalMapped[j];
          let xPoint = point.x;
          if (!_.isNil(current)) {
            if (current.x > next.x) {
              if (xPoint > next.x && xPoint <= current.x) {
                console.log("yScale) ESTA DETRO DO INTERVALO 1 (" + current.x + ", " + current.y + ") - (" + next.x + ", " + next.y + ")");


                var diffX = current.x - next.x;
                let diffY = current.y - next.y;

                //console.log("diffY:" + diffY + " diffX: " + diffX);
                //codigo que resolve os problemas
                var minY = next.y;
                var refX = current.x;
                if (diffY < 0) {
                  diffY = next.y - current.y;
                  refX = next.x;
                  minY = current.y;
                }

                let relation = diffY / diffX;

                //console.log("relation: " + relation + " diffY:" + diffY + " diffX: " + diffX);

                var xRelationDelta = xPoint - refX;
                if (xRelationDelta < 0) {
                  xRelationDelta = refX - xPoint;
                }
                let yInterpolated = (xRelationDelta * relation) + eval(minY);
                //console.log("yInterpolated: " + yInterpolated);

                yScale = yInterpolated;

              }
            } else {
              if (xPoint > current.x && xPoint <= next.x) {
                console.log("yScale) ESTA DETRO DO INTERVALO 2 (" + current.x + ", " + current.y + ") - (" + next.x + ", " + next.y + ")");
                //next.y > current.y
                //TODO!
              }
            }
          }
          //yScale = 60;
          current = next;
        }
      }

      if (_.isNil(xScale)) {
        var current = null;
        for (var j = 0; j < finalMapped.length; j++) {
          let next = finalMapped[j];
          let yPoint = point.y;
          if (!_.isNil(current)) {
            //console.log("compara: CY: " + current.y + " NY: " + next.y + " P: " + yPoint);
            if (current.y > next.y) {
              if (yPoint > next.y && yPoint <= current.y) {
                console.log("xScale) ESTA DETRO DO INTERVALO 1 (" + current.x + ", " + current.y + ") - (" + next.x + ", " + next.y + ")");
                //TODO!
              }
            } else {
              if (yPoint > current.y && yPoint <= next.y) {
                // console.log("xScale) ESTA DETRO DO INTERVALO 2 (" + current.x + ", " + current.y + ") - (" + next.x + ", " + next.y + ")");
                //next.y > current.y
                let diffY = next.y - current.y;

                var diffX = next.x - current.x;
                var minX = current.x;
                var refY = current.y;
                if (diffX < 0) {
                  diffX = current.x - next.x;
                  minX = next.x;
                  refY = next.y;
                }
                let relation = diffX / diffY;

                var yRelationDelta = yPoint - refY;
                if (yRelationDelta < 0) {
                  yRelationDelta = refY - yPoint;
                }
                let xInterpolated = (yRelationDelta * relation) + eval(minX);

                xScale = xInterpolated;
              }
            }
          }
          current = next;
        }
      }
      return { x: xScale, y: yScale };
    },
    onLegendClick(eventData, legendItem) {
      //console.log("onLegendClick: legendItem: " + JSON.stringify(legendItem) + " DATA: " + JSON.stringify(eventData) + " CHART: " + JSON.stringify(Object.keys(this.$refs.chart.$data)));
      var index = legendItem.datasetIndex;
      var currentChart = this.$refs.chart.$data._chart;

      var meta = currentChart.getDatasetMeta(index);

      if (meta.hidden === null) {
        meta.hidden = true;
      } else {
        meta.hidden = null;
      }

      currentChart.update();

      var exportChart = this.$refs.exportChart.$data._chart;

      var newExportSet = [];
      _.each(this.chartData.datasets, (entry, index) => {
        var meta = currentChart.getDatasetMeta(index);
        if (meta.hidden) {
          //console.log("HIDDEN index: " + index);
        } else {
          newExportSet.push(this.chartData.datasets[index]);
        }
      });

      this.exportChartData.datasets = newExportSet;

      exportChart.update();

      this.setExportChartLink();
    },
    setRectangles(rectangles) {
      this.chartOptions.extended.drawRectangles = true;
      this.chartOptions.extended.rectangles = rectangles;
    },
    setXAxisTitle(index, label) {
      this.chartOptions.scales.xAxes[index].scaleLabel = {};
      this.chartOptions.scales.xAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.xAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.xAxes[index].scaleLabel.fontColor = '#ffffff';
    },
    setYAxisTitle(index, label) {
      this.chartOptions.scales.yAxes[index].scaleLabel = {};
      this.chartOptions.scales.yAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.yAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.yAxes[index].scaleLabel.fontColor = '#ffffff';
    },
    clearSeries() {
      while (this.chartData.datasets.length > 0) {
        this.chartData.datasets.splice(0, 1);
        this.exportChartData.datasets.splice(0, 1);
      }
      this.updateChart();
    },
    copyOptionsToExport() {
      this.exportChartOptions = _.cloneDeep(this.chartOptions);
      this.exportChartOptions.legend.labels.fontSize = 16;
      this.exportChartOptions.legend.labels.fontColor = '#000000';
      this.exportChartOptions.extended.drawValuesColor = '#000000';

      if (!_.isNil(this.exportChartOptions.extended)) {
        if (!_.isNil(this.exportChartOptions.extended.rectangles)) {
          _.each(this.exportChartOptions.extended.rectangles, (entry) => {
            entry.legendColor = '#000000';
          });
        }
      }

      _.each(this.exportChartOptions.scales.yAxes, (entry) => {
        if (!_.isNil(entry.scaleLabel)) {
          entry.scaleLabel.fontSize = 16;
          entry.scaleLabel.fontColor = '#000000';
          entry.ticks.fontSize = 16;
          entry.ticks.fontColor = '#000000';
        }
      });

      _.each(this.exportChartOptions.scales.xAxes, (entry) => {
        if (!_.isNil(entry.scaleLabel)) {
          entry.scaleLabel.fontSize = 16;
          entry.scaleLabel.fontColor = '#000000';
          entry.ticks.fontSize = 16;
          entry.ticks.fontColor = '#000000';
        }
      });

    },
    setDisplayLegend(value) {
      this.chartOptions.legend.display = value;
    },
    setYBeginAtZero(value) {
      this.chartOptions.scales.yAxes[0].ticks.beginAtZero = value;
    },
    setAlternativeDataSet(value) {
      this.chartOptions.extended.useAlternativeDataSet = value;
    },
    setToolTips(value) {
      this.chartOptions.tooltips.enabled = value;
    },
    setDrawValues(value) {
      this.chartOptions.extended.drawValuesInChart = value;
      this.chartOptions.extended.drawValuesColor = '#ffffff';
    },
    setYMax(value) {
      this.chartOptions.scales.yAxes[0].ticks.max = value;
      this.updateChart();
    },
    setLoader() {
      this.loading = true;
    },
    resetLoader() {
      this.loading = false;
    },
    updateChart() {
      this.$refs.chart.updateChart();
      this.copyOptionsToExport();
      this.$refs.exportChart.updateChart();

      this.setExportChartLink();
    },
    setExportChartLink() {
      this.$nextTick(() => {
        if (this.exportLink) {
          var element = this.$refs.exportChart.$data._chart.canvas;
          var chart_data = element.toDataURL("image/jpg");
          this.$refs.exportLink.href = chart_data;
        }
      });
    },
    setLabels(labels) {
      this.chartData.labels = labels;
    },
    setSeries(index, data, title) {
      this.setSeriesWithOptions(index, data, title, {});
    },
    setSeriesWithOptions(index, data, title, options) {
      if (index >= this.chartData.datasets.length) {
        var color = options.seriesColor;
        var fill = options.fill;
        if (_.isNil(color)) {
          color = this.baseSeriesColors[index];
        }
        if (_.isNil(fill)) {
          fill = false;
        }
        this.chartData.datasets.push({
          label: '',
          backgroundColor: color,
          borderColor: color,
          data: [],
          labelsData: [],
          fill: fill,
          borderWidth: 3,
          showLine: true,
          xAxisID: 'x-axis-1',
          yAxisID: `y-axis-${index}`,
          cubicInterpolationMode: 'monotone',
        });
      }
      this.chartData.datasets[index].data = data;
      this.chartData.datasets[index].label = title;

      if (options.labelsData) {
        this.chartData.datasets[index].labelsData = options.labelsData;
      }

      this.exportChartData = _.cloneDeep(this.chartData);
      _.each(this.exportChartData.datasets, (dataset) => {
        dataset.borderWidth = 3;
      });
    }
  },
}

</script>
