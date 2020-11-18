<template>
  <div class="container-fluid" style="position: relative;">
    <!-- snow-flakes></snow-flakes -->

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          <!-- como ter um combobox aqui que defina que esta puchando a home do usuario ou um consolidado? -->
          {{ identifier }} - <span v-if="baseDate">Meta móvel atualizada em: {{ baseDate }}</span>
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

        <div :class="chartsClass">
          <div class="transparent-loader" v-if="loadingSazonality">
            <div class="loader"></div>
          </div>
          <div class="panel">
            <div class="panel-body">
              <span style="color: #c2c9cb; display: flex; justify-content: center;">
                <b>Sazonalidade: </b>
                <span style="padding-left: 5px;">{{ currentPercent }}</span>
                <span class="glyphicon glyphicon-download-alt clickable" style="padding-left: 5px;" @click="exportSazonalityData"></span>
                <template v-if="hasSazonalityOptions">
                  <select v-model="sazonalityOption" style="color: #000000; background-color: #ffffff; border-radius: 5px; margin-left: 10px;">
                    <template v-for="option in sazonalityOptions">
                       <option :value="option.id">
                         {{ option.name }}
                       </option>
                    </template>
                  </select>
                </template>
              </span>
              <comparing-chart ref="cumSazonality" :export-link="false" :base-height="150" export-name="sazonalidade_acumulada"></comparing-chart>
              <comparing-chart ref="sazonality" :export-link="false" :base-height="150" export-name="sazonalidade"></comparing-chart>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="row" v-if="hasProductLineOptions">
            <div style="float: right; margin-top: -10px">
              <label>LINHA DE PRODUTO</label>
              <multiselect v-model="productLineOption" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
            </div>

            <div style="float: right; margin-top: -10px; margin-right: 20px" v-if="hasRegionFilter">
              <label>REGIÃO</label>
              <multiselect v-model="farmRegionOption" :options="farmRegionOptions" label="name" track-by="id" placeholder="Todas as regiões" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
            </div>
          </div>
          <div class="panel-body no-lat-padding">
            <div v-if="hasData">
              <table id="report-table" class="data-table sticky-header">
                <thead id="table-header">
                  <tr>
                    <th>IES ID</th>
                    <th>IES</th>
                    <th>Grupo ID</th>
                    <th>Grupo</th>
                    <th>Região</th>
                    <th>Segmento</th>
                    <th>Período</th>
                    <th>Farm</th>
                    <th>Qualidade</th>
                    <th>Meta semestre (R$)</th>
                    <th>Meta móvel (R$)</th>
                    <th>Meta móvel (intermediária) (R$)</th>
                    <th>Realizado (R$)</th>
                    <th>LTV Speed (%)</th>
                    <th>LTV Speed (intermediária) (%)</th>
                    <th>Speed (%)</th>
                    <th>Visitas em ofertas</th>
                    <th>Ordens</th>
                    <th>Faturamento por ordem (R$)</th>
                    <th>Conversão</th>
                    <th>Atratividade</th>
                    <th>Sucesso</th>
                    <th>Accountable</th>
                    <th>Speed 1D (%)</th>
                    <th>Speed 7D (%)</th>
                    <th>Goal 7D (R$)</th>
                    <th>Revenue 7D (R$)</th>
                    <th>Carteira</th>
                  </tr>
                </thead>
                <tbody>
                    <tr v-for="university in tableData">
                      <td>{{ university.university_id }}</td>
                      <td>{{ university.university_name }}</td>
                      <td>{{ university.education_group_id }}</td>
                      <td>{{ university.education_group_name }}</td>
                      <td>{{ university.farm_region }}</td>
                      <td>{{ university.product_line_name }}</td>
                      <td>{{ university.period }}</td>
                      <td>{{ university.owner }}</td>
                      <td>{{ university.quality_owner }}</td>
                      <td>{{ university.semester_goal }}</td>
                      <td>{{ university.mobile_goal }}</td>
                      <td>{{ university.mobile_goal_intermediate }}</td>
                      <td>{{ university.realized }}</td>
                      <td>{{ university.speed }}</td>
                      <td>{{ university.speed_intermediate }}</td>
                      <td>{{ university.legacy_speed }}</td>
                      <td>{{ university.visits }}</td>
                      <td>{{ university.initiateds }} </td>
                      <td>{{ university.mean_income }}</td>
                      <td>{{ university.conversion }}</td>
                      <td>{{ university.new_orders_per_visits }}</td> <!-- Taxa de Atratividade -->
                      <td>{{ university.paid_per_new_orders }}</td>     <!-- Taxa de Sucesso -->
                      <td>{{ university.accountable }} </td>
                      <td>{{ university.last_day_velocity }} </td>
                      <td>{{ university.last_week_velocity }} </td>
                      <td>{{ university.last_week_goal }} </td>
                      <td>{{ university.last_week_revenue }} </td>
                      <td>C{{ university.account_type }}</td>
                    </tr>
                </tbody>
                <tfoot>
                  <tr>
                    <td colspan="9" style="text-align: right"><b>Totais:</b></td>
                    <td><span class="no-wrap" id="total-goal">{{ totalGoal }}</span></td>
                    <td><span class="no-wrap" id="mobile-goal"></span></td>
                    <td><span class="no-wrap" id="mobile-goal-intermediate"></span></td>
                    <td><span class="no-wrap" id="total-realized"></span></td>
                    <td colspan="13"></td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash';
import moment from 'moment';
import GaugeChart from "../js/components/gauge-chart";
import SolidGaugeChart from "../js/components/solid-gauge-chart";
import DataTable from "../js/components/datatable";
import SnowFlakes from "./snow-flakes";
import ComparingChart from './comparing-chart';
import Multiselect from 'vue-multiselect'

export default {
  data() {
    return {
      totalGoal: '',
      loading: true,
      loadingSazonality: true,
      identifier: '',
      baseDate: null,
      tableData: [],
      hideSensitiveData: false,
      totalChart: null,
      farmChart: null,
      farmChartIntermediate: null,
      currentPercent: null,
      rawSazonality: [],
      sazonalityDates: [],
      sazonalityOptions: [],
      //captureChart: null,
      table: null,
      sazonalityOption: null,
      filterLevels: null,
      levelOptions: [],
      productLineOption: null,
      productLineOptions:[],
      farmRegionOption: null,
      farmRegionOptions: [],
      hasData: false,
      initialized: false,
      capturePeriod: null,
      fullVelocimeter: null,
    }
  },
  mounted() {
    HomeChannel.on('tableData', (payload) => this.receiveTableData(payload));
    HomeChannel.on('sazonalityData', (payload) => this.receiveSazonalityData(payload));
    HomeChannel.on('filterData', (payload) => this.receiveFilterData(payload));
    HomeChannel.on('totalGoal', (payload) => this.receiveTotalGoal(payload));


    this.loadFilters();
    this.loadTotalGoal();

    this.capturePeriod = document.getElementById("capture-period").value;
  },
  watch: {
    sazonalityOption: function (value) {
      if (!this.initialized) {
        return;
      }
      this.loadSazonality();
    },

    productLineOption: function (value) {
      if (!_.isNil(value)) {
        this.sazonalityOption = value.id;
      }
      if (!this.initialized) {
        return;
      }
      this.loadData();
    },

    farmRegionOption: function (value) {
      if (!this.initialized) {
        return;
      }
      this.loadData();
    },
  },
  components: {
    SnowFlakes,
    ComparingChart,
    Multiselect,
  },
  computed: {
    chartsClass() {
      if (this.capturePeriod != 6 || (!_.isNil(this.productLineOption) && this.productLineOption.id == 8)) {
        return "col-md-4 col-sm-12 no-padding";
      }
      return "col-md-3 col-sm-12 no-padding";
    },
    hasIntermediateChart() {
      if (this.capturePeriod != 6  || (!_.isNil(this.productLineOption) && this.productLineOption.id == 8)) {
        return false;
      }
      return true;
    },
    hasSazonalityOptions() {
      return this.sazonalityOptions.length > 0;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 1;
    },
    hasRegionFilter() {
      return !_.isNil(this.productLineOption) && this.productLineOption.id == 10;
    },
  },
  methods: {
    loadTotalGoal() {
      HomeChannel.push('loadTotalGoal').receive('timeout', () => {
        console.log('loadTotalGoal fimeout');
      });
    },
    createCharts() {
      this.farmChart = new GaugeChart('time-chart-farmer', {
        title: 'Meta total',
        tooltip: ' % de parcerias'
      });

      this.farmChartIntermediate = new GaugeChart('time-chart-farmer-intermediate', {
        title: 'Meta intermediária',
        tooltip: ' % de parcerias'
      });

      this.createFullGoalChart();
    },
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
    loadSazonality() {
      console.log("loadSazonality");
      let params = {
        product_line_id: this.sazonalityOption
      }
      this.loadingSazonality = true;
      HomeChannel.push('loadSazonality', params).receive('timeout', () => {
        console.log('loadSazonality fimeout');
      });
    },
    loadFilters(){
      HomeChannel.push('loadFilters').receive('timeout', () => {
        console.log('filters fimeout');
      });
    },

    exportSazonalityData() {
      var filename = "sazonalidade" + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
      var content = "Data;Sazonalidade\n"
      _.each(this.sazonalityDates, (item, itemIndex) => {
        content = content + item + ";"
          + this.rawSazonality[itemIndex] + "\n";
      });

      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
    receiveTotalGoal(data) {
      this.fullVelocimeter = data.total_goal;
      this.createFullGoalChart();
    },
    receiveSazonalityData(data) {
      console.log("receiveSazonalityData");

      this.sazonalityDates = data.dates;
      this.rawSazonality = data.raw_daily_contribution;
      this.sazonalityOptions = data.sazonality_options;
      this.sazonalityOption = data.current_sazonality;
      this.currentPercent = data.current_value_cum_contribution;

      this.$refs.cumSazonality.setXTick(false);
      this.$refs.cumSazonality.setYMax(100);
      //this.$refs.cumSazonality.setLegend(false);
      this.$refs.cumSazonality.setLabels(data.dates);
      this.$refs.cumSazonality.setSeries(0, data.cum_contribution, "Sazonalidade Acumuldada");
      this.$refs.cumSazonality.setSeriesWithOptions(1, data.current_cum_contribution, "Atual", { seriesColor: '#fdc029', fill: true });
      this.$refs.cumSazonality.resetLoader();


      this.$refs.sazonality.setXTick(false);
      this.$refs.sazonality.setYTick(false);
      //this.$refs.sazonality.setLegend(false);
      this.$refs.sazonality.setLabels(data.dates);
      this.$refs.sazonality.setSeries(0, data.daily_contribution, "Sazonalidade");
      this.$refs.sazonality.setSeriesWithOptions(1, data.current_daily_contribution, "Atual", { seriesColor: '#fdc029', fill: true });
      this.$refs.sazonality.resetLoader();

      this.$refs.cumSazonality.updateChart();
      this.$refs.sazonality.updateChart();

      this.$nextTick(() => {
        this.loadingSazonality = false;
      })
    },

    receiveFilterData(data){
      this.productLineOptions = data.productLineOptions;
      this.farmRegionOptions =  data.farm_regions;
      if (!_.isNil(data.current_product_line)) {
        let filteredOptions = _.filter(this.productLineOptions, (entry) => {
          return entry.id === data.current_product_line;
        })
        this.productLineOption = filteredOptions[0];
      }
      this.$nextTick(() => {
        this.loadData();
        this.loadSazonality();
        this.initialized = true; //libera o disparo de eventos
      });
    },
    // clearVelocimeter() {
    //   this.farmChart.getSeries(0).setData([]);
    //   this.farmChartIntermediate.getSeries(0).setData([]);
    // },
    receiveTableData(data) {
      this.tableData = data.university_goals;
      this.baseDate = data.last_date;
      this.identifier = data.panel_identification;
      this.totalGoal = data.total_goal;
      this.loading = false;
      this.hasData = true;

      this.createCharts();

      var columnDefs = [];
      if (this.capturePeriod != 6) {
        columnDefs = [
          { targets: [ 11, 14 ], visible: false },
        ];
      }

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          columnDefs: columnDefs,
          order: [ 9, 'desc' ]
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
    recalculateTotals() {
      let newPercent = 0;
      let newPercentIntermediate = 0;
      let nRows = this.table.getFilteredRows().nodes().length;
      if (nRows > 0) {
        let filteredData = this.table.getFilteredRows().data();


        let movelGoalColumn = 10;
        let intermediateMovelGoalColumn = 11;
        let realizedColumn = 12;
        //esta somando dados na tabela!
        //nao tem acesso aos dados na forma base?
          //precisa iterar sobre o filtro!
        let realized = 0;
        let movel_goal = 0;
        let movel_goal_intermediate = 0;
        for (var i = 0; i < nRows; i++) {
          if (filteredData[i][22] === 'Sim') {
            movel_goal += filteredData[i][movelGoalColumn].parseMoney();
            movel_goal_intermediate += filteredData[i][intermediateMovelGoalColumn].parseMoney();
            realized += filteredData[i][realizedColumn].parseMoney();
          }
        }

        $("#mobile-goal").text(movel_goal.formatMoney(2));
        $("#mobile-goal-intermediate").text(movel_goal_intermediate.formatMoney(2));
        $("#total-realized").text(realized.formatMoney(2));

        console.log("movel_goal: " + movel_goal + " movel_goal_intermediate+ " + movel_goal_intermediate + " realized: " + realized);

        newPercent = parseFloat((( realized / movel_goal ) * 100).toFixed(2));
        newPercentIntermediate = parseFloat((( realized / movel_goal_intermediate ) * 100).toFixed(2));
      }

      this.farmChart.getSeries(0).setData([]);
      this.farmChart.getSeries(0).addPoint(newPercent)

      this.farmChartIntermediate.getSeries(0).setData([]);
      this.farmChartIntermediate.getSeries(0).addPoint(newPercentIntermediate)
    },
    destroyCharts() {
      if (!_.isNil(this.farmChart) ) {
        this.farmChart.destroy();
      }
      if (!_.isNil(this.farmChartIntermediate) ) {
        this.farmChartIntermediate.destroy();
      }
    },
    loadData() {
      this.destroyCharts();
      let params = {};
      if (!_.isNil(this.productLineOption)) {
        params.product_line_id =  this.productLineOption.id;
      }

      if (!_.isNil(this.farmRegionOption)) {
        params.farm_region =  this.farmRegionOption.id;
      }
      this.loading = true;
      this.hasData = false;

      HomeChannel.push("loadData", params).receive('timeout', () => {
        console.log("load timeout");
      });

      this.$nextTick(() => {
        this.createFullGoalChart();
      });
    },
  },
};

</script>
