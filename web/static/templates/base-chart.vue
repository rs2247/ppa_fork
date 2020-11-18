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
    <bar-chart ref="chart"
      :data="chartData"
      :options="chartOptions"
      :height="baseHeight">
    </bar-chart>
    <bar-chart ref="exportChart" :data="exportChartData" style="z-index: -1; position: absolute; width: 100%; top: 0px;"
      :options="exportChartOptions"
      :height="baseHeight"></bar-chart>
  </div>
</template>

<script>
import _ from 'lodash';
import BarChart from '../js/components/vue-charts/bar-chart';
import moment from 'moment';

export default {
  data() {
    return {
      loading: false,
      baseSeriesColors: ['#35b6cc', '#fdc029', '#09b67c', '#bf265f', '#05869B', '#FC8400', '#006386'],
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
        hover: {
          intersect: false,
        },
        layout: {
          padding: {
            left: 0,
            right: 0,
            top: 0,
            bottom: 0
          }
        },
        tooltips: {
          enabled: true,
        },
        extended: {
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
        elements: { point: { radius: 0 } },
        scales: {
          xAxes: [{
            ticks: {
              autoSkip: false,
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
    BarChart,
  },
  computed: {
    showExportLink() {
      if (!this.exportLink) {
        return false;
      }
      return this.chartData.datasets.length > 0;
    },
    exportFileName() {
      if (_.isNil(this.exportName)) {
        return "chart.png";
      }
      return `${this.exportName}.png`;
    },
  },
  methods: {
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
    setXAxesBarPercentage(value, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.xAxes[index].barPercentage = value;
      this.copyOptionsToExport();
    },
    setXAxesAutoSkip(value, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.xAxes[index].ticks.autoSkip = value;
      this.copyOptionsToExport();
    },
    setPadding(value) {
      this.chartOptions.layout.padding = value;
      this.copyOptionsToExport();
    },
    setXAxisTitle(label, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.xAxes[index].scaleLabel = {};
      this.chartOptions.scales.xAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.xAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.xAxes[index].scaleLabel.fontColor = '#ffffff';
    },
    setYAxisTitle(label, index) {
      if (_.isNil(index)) {
        index = 0;
      }
      this.chartOptions.scales.yAxes[index].scaleLabel = {};
      this.chartOptions.scales.yAxes[index].scaleLabel.labelString = label;
      this.chartOptions.scales.yAxes[index].scaleLabel.display = true;
      this.chartOptions.scales.yAxes[index].scaleLabel.fontColor = '#ffffff';
    },
    setYAxes(value) {
      this.chartOptions.scales.yAxes = value;
    },
    setXAxes(value) {
      this.chartOptions.scales.xAxes = value;
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
    clearSeries() {
      while (this.chartData.datasets.length > 0) {
        this.chartData.datasets.splice(0, 1);
        this.exportChartData.datasets.splice(0, 1);
      }
      this.updateChart();
    },
    copyOptionsToExport() {
      this.exportChartOptions = _.cloneDeep(this.chartOptions);
      this.exportChartOptions.scales.xAxes[0].ticks.fontColor = '#000000';
      this.exportChartOptions.scales.yAxes[0].ticks.fontColor = '#000000';
      this.exportChartOptions.legend.labels.fontColor = '#000000';
      this.exportChartOptions.extended.drawValuesColor = '#000000';
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
    setDrawValues(value, fontSize, fontStyle) {
      this.chartOptions.extended.drawValuesInChart = value;
      this.chartOptions.extended.drawValuesColor = '#ffffff';
      if (!_.isNil(fontSize)) {
        this.chartOptions.extended.drawValuesSize = fontSize;
      }
      if (!_.isNil(fontStyle)) {
        this.chartOptions.extended.drawValueStyle = fontStyle;
      }
      this.copyOptionsToExport();
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

      this.$nextTick(() => {
        this.updateExportLink();
      });
    },
    updateExportLink() {
      if (this.exportLink) {
        var element = this.$refs.exportChart.$data._chart.canvas;
        var chart_data = element.toDataURL("image/jpg");
        this.$refs.exportLink.href = chart_data;
      }
    },
    setLabels(labels) {
      this.chartData.labels = labels;
    },
    setSeries(index, data, title) {
      //let seriesColor = this.baseSeriesColors[index];
      //this.setSeriesWithOptions(index, data, title, { seriesColor, fill: false });
      this.setSeriesWithOptions(index, data, title, {});
    },
    setSeriesWithOptions(index, data, title, options) {
      let color = options.seriesColor;
      let fill = options.fill;
      let yAxisID = options.yAxisID;
      let xAxisID = options.xAxisID;
      let borderWidth = options.borderWidth;
      if (_.isNil(borderWidth)) {
        borderWidth = 1;
      }
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
        labelsData: [],
        fill: fill,
        borderWidth: borderWidth,
      };
      if (options.labelsData) {
        datasetMap.labelsData = options.labelsData;
      }
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
    // setSeriesWithOptions(index, data, title, options) {
    //   if (index >= this.chartData.datasets.length) {
    //     var color = options.seriesColor;
    //     var fill = options.fill;
    //     if (_.isNil(color)) {
    //       color = this.baseSeriesColors[index];
    //     }
    //     if (_.isNil(fill)) {
    //       fill = false;
    //     }
    //     var dataSetProperties = {
    //       label: '',
    //       backgroundColor: color,
    //       borderColor: color,
    //       data: [],
    //       labelsData: [],
    //       fill: fill,
    //       borderWidth: 2,
    //     };
    //     if (!_.isNil(options.type)) {
    //       dataSetProperties.type = options.type;
    //     }
    //     this.chartData.datasets.push(dataSetProperties);
    //   }
    //   this.chartData.datasets[index].data = data;
    //   this.chartData.datasets[index].label = title;
    //
    //   if (options.labelsData) {
    //     this.chartData.datasets[index].labelsData = options.labelsData;
    //   }
    //
    //   this.exportChartData = _.cloneDeep(this.chartData);
    //   _.each(this.exportChartData.datasets, (dataset) => {
    //     dataset.borderWidth = 3;
    //   });
    // }
  },
}

</script>
