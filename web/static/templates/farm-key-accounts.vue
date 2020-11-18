<template>
  <div class="container-fluid">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          <template v-if="isManager">
            <select v-model="rankingSelection" style="color: #000000; background-color: #ffffff; border-radius: 5px; margin-left: 10px;">
              <option value="">{{ panelType }}</option>
              <option value="all">All {{ panelType }}</option>
            </select>
          </template>
          <template v-else>
            {{ title }}
          </template>
           - Meta móvel atualizada em: {{ lastDate }}
         </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="charts-panels col-md-12">
        <div :class="chartsClass">
          <div class="panel">
            <div class="panel-body">
              <div id="time-chart-farmer" class="chart chart-padding"></div>
            </div>
          </div>
        </div>

        <div :class="chartsClass" v-show="hasIntermediateChart">
          <div class="panel">
            <div class="panel-body">
              <div id="time-chart-farmer-intermediate" class="chart chart-padding"></div>
            </div>
          </div>
        </div>

        <div :class="chartsClass">
          <div class="panel">
            <div class="panel-body">
              <div id="time-chart-total" class="chart chart-padding"></div>
            </div>
          </div>
        </div>

        <sazonality-chart :class="chartsClass" ref="sazonalityChart" v-model="sazonalityOption"></sazonality-chart>

      </div>
    </div>

    <div class="row">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="row" v-if="hasProductLineOptions">
            <div style="float: right; margin-right: 10px">
              <label>LINHA DE PRODUTO</label>
              <multiselect v-model="productLineFilter" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
            </div>
          </div>
          <div class="panel-body no-lat-padding">

            <div v-if="hasData">
              <table id="report-table" class="data-table">
                <thead>
                  <tr>
                    <th>Key Account</th>
                    <th>Carteira</th>
                    <th>Região</th>
                    <th>Segmento</th>
                    <th>Meta semestre (R$)</th>
                    <th>Meta móvel (R$)</th>
                    <th>Meta móvel (intermediária) (R$)</th>
                    <th>Realizado QAP (R$)</th>
                    <th>LTV Speed (%)</th>
                    <th>LTV Speed (intermediária) (%)</th>
                    <th>Speed (%)</th>
                    <th>Realizado (R$)</th>
                    <th>Visitas em ofertas</th>
                    <th>Faturamento por ordem (R$)</th>
                    <th>Conversão</th>
                    <th>Atratividade</th>
                    <th>Sucesso</th>
                    <th>Gap Atual (R$)</th>
                    <th>Gap Semestre (R$)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.owner }}</td>
                    <td>
                      <template v-for="account_type in entry.account_types">
                         C{{ account_type }}
                      </template>
                    </td>
                    <td>
                      <template v-for="region in entry.regions">
                         {{ region }}
                      </template>
                    </td>
                    <td>{{ entry.product_line_name }}</td>
                    <td>{{ entry.semester_goal | toDelimited }}</span></td>
                    <td>{{ entry.mobile_goal | toDelimited }}</span></td>
                    <td>{{ entry.mobile_goal_intermediate | toDelimited }}</span></td>
                    <td>{{ entry.realized | toDelimited }}</span></td>
                    <td>{{ entry.speed | toPercentage }}</td>
                    <td>{{ entry.speed_intermediate | toPercentage }}</td>
                    <td>{{ entry.legacy_speed | toPercentage }}</td>
                    <td>{{ entry.legacy_realized | toDelimited }}</span></td>
                    <td>{{ entry.visits }}</td>
                    <td>{{ entry.mean_income | toDelimited }}</td>
                    <td>{{ entry.conversion | toPercentage }}</td>
                    <td>{{ entry.atraction | toPercentage }}</td>
                    <td>{{ entry.success | toPercentage }}</td>
                    <td>{{ entry.current_goal_gap | toDelimited }}</td>
                    <td>{{ entry.goal_gap | toDelimited }}</td>

                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>


  </div>
</template>

<script>
import _ from 'lodash'

import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import CDatePicker from './custom-date-picker'
import ModalDialog from './modal-dialog'
import MessageDialog from "../js/components/message-dialog";
import LocationFilter from './location-filter';


import SazonalityChart from './sazonality-chart';

import GaugeChart from "../js/components/gauge-chart";
import ComparingChart from './comparing-chart'
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import DataTable from "../js/components/datatable";

export default {
  data() {
    return {
      title: null,
      lastDate: null,
      tableData: [],
      hasData: false,
      loading: true,
      productLineFilter: null,
      productLineOptions: [],
      totalChart: null,
      farmChart: null,
      farmChartIntermediate: null,
      sazonalityOption: null,
      table: null,
      managerAccess: null,
      rankingSelection: '',
      capturePeriod: null,
      fullVelocimeter: null,
    }
  },
  components: {
    Multiselect,
    SazonalityChart,
  },
  computed: {
    chartsClass() {
      if (this.capturePeriod != 6 || (!_.isNil(this.productLineFilter) && this.productLineFilter.id == 8)) {
        return "col-md-4 col-sm-12 no-padding";
      }
      return "col-md-3 col-sm-12 no-padding";
    },
    hasIntermediateChart() {
      if (this.capturePeriod != 6  || (!_.isNil(this.productLineFilter) && this.productLineFilter.id == 8)) {
        return false;
      }
      return true;
    },
    isManager() {
      return !_.isNil(this.managerAccess) && this.managerAccess.manager;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 1;
    },
  },
  mounted() {
    FarmKeyAccountChannel.on('farmData', (payload) => this.receiveTableData(payload));
    FarmKeyAccountChannel.on('filterData', (payload) => this.receiveFilters(payload));
    FarmKeyAccountChannel.on('sazonalityData', (payload) => this.receiveSazonalityData(payload));
    FarmKeyAccountChannel.on('totalGoal', (payload) => this.receiveTotalGoal(payload));

    this.capturePeriod = document.getElementById("capture-period").value;


    this.loadFilters();
    this.loadSazonality();
    this.loadTotalGoal();
  },
  watch: {
    productLineFilter: function(value) {
      //this.clearVelocimeter();
      this.loadData();
      if (!_.isNil(value)) {
        this.sazonalityOption = value.id;
      }
    },
    sazonalityOption: function(value) {
      this.loadSazonality();
    },
    rankingSelection: function(value) {
      console.log("rankingSelection");
      //this.clearVelocimeter();
      this.loadData();
    },
  },
  props: {
    panelType: {
      type: String,
      default: 'Farm'
    },
  },
  methods: {
    createFullGoalChart() {
      if (!_.isNil(this.totalChart) ) {
        this.totalChart.destroy();
      }

      this.totalChart = new GaugeChart('time-chart-total', {
        title: 'Meta empresa',
        tooltip: ' % de parcerias'
      });

      this.totalChart.getSeries(0).setData([]);
      this.totalChart.getSeries(0).addPoint(this.fullVelocimeter)
    },
    loadTotalGoal() {
      FarmKeyAccountChannel.push('loadTotalGoal').receive('timeout', () => {
        console.log('loadTotalGoal fimeout');
      });
    },
    createCharts() {

      this.farmChart = new GaugeChart('time-chart-farmer', {
        title: 'Meta Total',
        tooltip: ' % de parcerias'
      });

      this.farmChartIntermediate = new GaugeChart('time-chart-farmer-intermediate', {
        title: 'Meta intermediária',
        tooltip: ' % de parcerias'
      });

      this.createFullGoalChart();
    },
    destroyCharts() {
      if (!_.isNil(this.farmChart) ) {
        this.farmChart.destroy();
      }
      if (!_.isNil(this.farmChartIntermediate) ) {
        this.farmChartIntermediate.destroy();
      }
    },
    // clearVelocimeter() {
    //   this.farmChart.getSeries(0).setData([]);
    // },
    receiveTotalGoal(data) {
      this.fullVelocimeter = data.total_goal;
      this.createFullGoalChart();
    },
    receiveSazonalityData(data) {
      this.$refs.sazonalityChart.setCurrentSazonality(data);
    },
    loadSazonality() {
      let params = {
        product_line_id: this.sazonalityOption
      }
      this.$refs.sazonalityChart.setLoader();
      FarmKeyAccountChannel.push('loadSazonality', params).receive('ok', (data) => {
        console.log("received: ok");
      });
    },
    receiveTableData(data) {

      this.createCharts();

      this.tableData = data.ranking_data;
      this.lastDate = data.last_date;
      this.title = data.title;
      this.loading = false;
      this.hasData = true;

      console.log("receiveTableData# access_map: " + JSON.stringify(data.access_map))

      this.managerAccess = data.access_map;

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          deferRender: true,
          searchDelay: 500,
          order: [ 8, 'desc' ]
        });
        this.recalculateTotals();
        var instance = this;
        this.table.onFilter(() => {
          setTimeout(function() {
            instance.recalculateTotals();
          }, 300);
        });
      });
    },
    receiveFilters(data) {
      this.productLineOptions = data.product_lines;
      if (!_.isNil(data.current_product_line)) {
        let filteredOptions = _.filter(this.productLineOptions, (entry) => {
          return entry.id === data.current_product_line;
        })
        console.log("filteredOptions: " + JSON.stringify(filteredOptions));
        this.productLineFilter = filteredOptions[0];
        //vai disparar load data! devia ser mais explicito?
        //deveria ter uma clause guard no watch pra nao disparar nesse caso?
        //flag de inicializado?
      } else {
        this.loadData();
      }
    },
    loadFilters() {
      FarmKeyAccountChannel.push('loadFilters').receive('timeout', () => {
        console.log("loadFilter timeout");
      });
    },
    recalculateTotals() {
      let newPercent = null;
      let newPercentIntermediate = null;
      let nRows = this.table.getFilteredRows().nodes().length;
      if (nRows > 0) {
        let filteredData = this.table.getFilteredRows().data();

        let movelGoalColumn = 5;
        let movelGoalIntermediateColumn = 6;
        let realizedColumn = 7;

        let realized = 0;
        let movel_goal = 0;
        let movel_goal_intermediate = 0;
        for (var i = 0; i < nRows; i++) {
          movel_goal += filteredData[i][movelGoalColumn].parseMoney();
          movel_goal_intermediate += filteredData[i][movelGoalIntermediateColumn].parseMoney();
          realized += filteredData[i][realizedColumn].parseMoney();
        }

        newPercent = parseFloat((( realized / movel_goal ) * 100).toFixed(2));
        newPercentIntermediate = parseFloat((( realized / movel_goal_intermediate ) * 100).toFixed(2));
      }
      if (!_.isNil(newPercent)) {
        this.farmChart.getSeries(0).setData([]);
        this.farmChart.getSeries(0).addPoint(newPercent)
      }
      if (!_.isNil(newPercentIntermediate)) {
        this.farmChartIntermediate.getSeries(0).setData([]);
        this.farmChartIntermediate.getSeries(0).addPoint(newPercentIntermediate)
      }
    },
    loadData() {
      this.destroyCharts();
      let params = {};
      if (!_.isNil(this.productLineFilter)) {
        params.productLine = this.productLineFilter.id;
      }
      params.ranking = this.rankingSelection;
      this.loading = true;
      this.hasData = false;
      var channelCall = 'load';
      if (this.panelType == 'Quali') {
        channelCall = 'loadQuali';
      }
      FarmKeyAccountChannel.push(channelCall, params).receive('timeout', () => {
        console.log("load timeout");
      });

      this.$nextTick(() => {
        this.createFullGoalChart();
      });
    },
  }
}
</script>
