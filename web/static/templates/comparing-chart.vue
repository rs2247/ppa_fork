<template>
  <div style="position: relative;">
    <div class="loader-container centered-loader-container" v-if="loading">
      <div class="loader"></div>
    </div>
    <div style="display: flex; justify-content: flex-end;" v-show="showExportLink">
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
    <line-chart ref="chart" :data="chartData"
     :options="chartOptions"
     :height="baseHeight"></line-chart>
    <line-chart ref="exportChart" :data="exportChartData" style="z-index: -1; position: absolute; width: 100%; top: 0px; height: 100%;"
      :options="exportChartOptions"
      :height="baseHeight"></line-chart>
  </div>
</template>

<script>
import _ from 'lodash';
import moment from 'moment';
import LineChart from '../js/components/vue-charts/line-chart'

export default {
  data() {
    return {
      baseSeriesColors: ['#35b6cc', '#fdc029', '#09b67c', '#bf265f', '#05869B', '#FC8400', '#006386'],
      loading: false,
      chartData: {
        labels: [],
        datasets: []
      },
      exportChartData: {
        labels: [],
        datasets: []
      },
      exportChartOptions: null,
      chartOptions: {
        hover: {
          intersect: false,
        },
        layout: {},
        extended: {
          drawCurrentPointLine: false,
          currentPoint: 0,
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
        elements: { point: { radius: 0 } },
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
            ticks: {
              display: true,
              fontColor: '#ffffff'
            },
          }]
        }
      },
    }
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
  computed: {
    exportFileName() {
      if (_.isNil(this.exportName)) {
        return "chart.png";
      }
      return `${this.exportName}.png`;
    },
    showExportLink() {
      if (!this.exportLink) {
        return false;
      }
      return this.chartData.datasets.length > 0;
    }
  },
  components: {
    LineChart,
  },
  mounted() {
    this.copyOptions();
  },
  methods: {
    setPadding(value) {
      this.chartOptions.layout.padding = value;
    },
    setXAxesAutoSkip(value, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.xAxes[index].ticks.autoSkip = value;
    },
    setYAxesStacked(index) {
      let axesIndex = index;
      if (_.isNil(axesIndex)) {
        axesIndex = 0;
      }
      this.chartOptions.scales.yAxes[axesIndex].stacked = true;
    },
    setXAxesStacked(index) {
      let axesIndex = index;
      if (_.isNil(axesIndex)) {
        axesIndex = 0;
      }
      this.chartOptions.scales.xAxes[axesIndex].stacked = true;
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
        baseName = 'dados';
      }
      var filename = baseName + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
      var content = "Indice";
      for (var i = 0; i < this.chartData.datasets.length; i++) {
        content = content + ',' + this.chartData.datasets[i].label;
      }
      content = content + '\n';
      for (var row = 0; row < this.chartData.labels.length; row++) {
        content = content + this.chartData.labels[row];
        for (var i = 0; i < this.chartData.datasets.length; i++) {
          content = content + ',' + this.emptyNull(this.chartData.datasets[i].data[row]);
        }
        content = content + '\n';
      }
      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
    copyOptions() {
      this.exportChartOptions = _.cloneDeep(this.chartOptions);

      _.forEach(this.exportChartOptions.scales.xAxes, (entry) => {
        entry.ticks.fontColor = '#000000';
        if (!_.isNil(entry.scaleLabel)) {
          entry.scaleLabel.fontColor = '#000000';
        }
      });
      _.forEach(this.exportChartOptions.scales.yAxes, (entry) => {
        entry.ticks.fontColor = '#000000';
        if (!_.isNil(entry.scaleLabel)) {
          entry.scaleLabel.fontColor = '#000000';
        }
      });
      this.exportChartOptions.legend.labels.fontColor = '#000000';

      if (!_.isNil(this.exportChartOptions.extended)) {
        if (this.exportChartOptions.extended.drawCurrentPointLine) {
          this.exportChartOptions.extended.drawCurrentPointFontColor = '#000000';
        }
      }
    },
    onLegendClick(eventData, legendItem) {
      var index = legendItem.datasetIndex;
      var currentChart = this.$refs.chart.$data._chart;
      var exportChart = this.$refs.exportChart.$data._chart;

      var meta = currentChart.getDatasetMeta(index);
      var exportMeta = exportChart.getDatasetMeta(index);

      if (meta.hidden === null) {
        meta.hidden = true;
        exportMeta.hidden = true;
      } else {
        meta.hidden = null;
        exportMeta.hidden = null;
      }

      currentChart.update();
      exportChart.update();
      this.updateExportLink();
    },
    setXAxisTitle(label, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.xAxes[index].scaleLabel = {};
      this.chartOptions.scales.xAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.xAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.xAxes[index].scaleLabel.fontColor = '#ffffff';

      this.copyOptions();
    },
    setYAxisTitle(label, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.yAxes[index].scaleLabel = {};
      this.chartOptions.scales.yAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.yAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.yAxes[index].scaleLabel.fontColor = '#ffffff';

      this.copyOptions();
    },
    setLegend(value) {
      this.chartOptions.legend.display = value;
      this.updateChart();
    },
    setYMax(value, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.yAxes[index].ticks.max = value;
      this.updateChart();
    },
    removeYMax(index) {
      if (_.isNil(index)) {
        index = 0;
      }
      delete this.chartOptions.scales.yAxes[index].ticks['max']
    },
    setYAxes(value) {
      this.chartOptions.scales.yAxes = value;
      this.copyOptions();
    },
    setXAxes(value) {
      this.chartOptions.scales.xAxes = value;
      this.copyOptions();
    },
    setYTick(value) {
      this.chartOptions.scales.yAxes[0].ticks.display = value;
      this.updateChart();
    },
    setXTick(value) {
      this.chartOptions.scales.xAxes[0].ticks.display = value;
      this.updateChart();
    },
    setCurrentPoint(index) {
      this.chartOptions.extended.drawCurrentPointLine = true;
      this.chartOptions.extended.currentPoint = index;
      this.copyOptions();
    },
    setHorizontalPoint(series, value) {
      this.chartOptions.extended.drawHorizontalLine = true;
      this.chartOptions.extended.drawHorizontalLinePoint = value;
      this.chartOptions.extended.drawHorizontalLineDataset = series;
    },
    updateChart() {
      this.$refs.chart.updateChart();
      this.$refs.exportChart.updateChart();

      if (this.exportLink) {
        var element = this.$refs.exportChart.$data._chart.canvas;
        var chart_data = element.toDataURL("image/jpg");
        this.$refs.exportLink.href = chart_data;
      }
    },
    updateExportLink() {
      if (this.exportLink) {
        var element = this.$refs.exportChart.$data._chart.canvas;
        var chart_data = element.toDataURL("image/jpg");
        this.$refs.exportLink.href = chart_data;
      }
    },
    setLoader() {
      this.loading = true;
    },
    resetLoader() {
      this.loading = false;
    },
    clearSeries() {
      while (this.chartData.datasets.length > 0) {
        this.chartData.datasets.splice(0, 1);
      }
      while (this.exportChartData.datasets.length > 0) {
        this.exportChartData.datasets.splice(0, 1);
      }
      this.updateChart();
    },
    setLabels(labels) {
      this.chartData.labels = labels;
    },
    setSeries(index, data, title) {
      let seriesColor = this.baseSeriesColors[index];
      this.setSeriesWithOptions(index, data, title, { seriesColor, fill: false });
    },
    getNextColor(index) {
      var delta = index % this.baseSeriesColors.length;
      var baseColor = this.baseSeriesColors[delta];

      var times = Math.floor(index / this.baseSeriesColors.length);

      var colors = [];
      colors.push(parseInt(baseColor.slice(1,3), 16));
      colors.push(parseInt(baseColor.slice(3,5), 16));
      colors.push(parseInt(baseColor.slice(5,7), 16));

      for (var j = 0; j < times; j++) {
        for (var i = 0; i < 3; i++) {
          colors[i] -= 16;
          if (colors[i] < 0) {
            colors[i] = 255 + colors[i];
          }
        }
      }

      var redHex = colors[0].toString(16).padStart(2, '0');
      var greenHex = colors[1].toString(16).padStart(2, '0');
      var blueHex = colors[2].toString(16).padStart(2, '0');

      let finalColor = `#${redHex}${greenHex}${blueHex}`
      return finalColor;
    },
    setSeriesWithOptions(index, data, title, options) {
      let color = options.seriesColor;
      let fill = options.fill;
      let yAxisID = options.yAxisID;
      let xAxisID = options.xAxisID;
      if (_.isNil(color)) {
        color = this.getNextColor(index);
      }
      if (_.isNil(fill)) {
        fill = false;
      }
      var datasetMap = {
        label: '',
        backgroundColor: color,
        borderColor: color,
        data: [],
        fill: fill,
        borderWidth: 2,
      };
      if (!_.isNil(yAxisID)) {
        datasetMap.yAxisID = yAxisID;
      }
      if (!_.isNil(xAxisID)) {
        datasetMap.xAxisID = xAxisID;
      }
      if (!_.isNil(options.type)) {
        datasetMap.type = options.type;
      }
      if (index >= this.chartData.datasets.length) {
        this.chartData.datasets.push(datasetMap);
      }
      this.chartData.datasets[index].data = data;
      this.chartData.datasets[index].label = title;

      this.exportChartData = _.cloneDeep(this.chartData);
      _.each(this.exportChartData.datasets, (dataset) => {
        dataset.borderWidth = 3;
      });
    }
  }
}
</script>
