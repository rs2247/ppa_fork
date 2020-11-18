<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel de exibições na busca
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loadingFilters || dataLoading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">

            <div class="row">
              <div class="col-md-11">
                <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-group-options="universityGroupOptions" :university-options="universityOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
              </div>
            </div>

            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div class="">
                  <label for="date">PERÍODO</label>
                  <c-date-picker v-model="dateRange"></c-date-picker>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADE</label>
                  <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Selecione uma modalidade" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadData">
                    Atualizar
                  </button>

                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row" v-show="hasCompareChartData">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Número de exibições em primeira página por usuário distinto
          </div>
          <base-chart :base-height="600" ref="compareChart" :export-name="'impressoes_na_busca'"></base-chart>
        </div>
      </div>
    </div>

    <div class="row" v-show="hasChartData">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Percentual de visualizações por página de aparição
          </div>
          <base-chart :base-height="600" ref="rankingChart" :export-name="'impressoes_na_busca'"></base-chart>
        </div>
      </div>


      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Percentual de visualizações por posição de aparição + Visitas com origem na busca
          </div>
          <base-chart :base-height="600" ref="rankingChartEx" :export-name="'impressoes_na_busca'"></base-chart>
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import _ from 'lodash'

import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import LocationFilter from './location-filter';
import BaseChart from './base-chart'
import ComparingChart from './comparing-chart'
import CDatePicker from './custom-date-picker'

import exportToCsv from "../js/utils/export";

export default {
  data() {
    return {
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],

      kindOptions: [],
      levelOptions: [],

      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      accountTypeOptions: [],

      groupOptions: [],

      filterKinds: null,
      filterLevels: null,
      filterCity: null,

      tableData: [],
      table: null,
      hasChartData: false,

      loadingFilters: true,
      dataLoading: false,
      //currentFilter: null,
      dateRange: [],
      hasCompareChartData: false,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    LocationFilter,
    BaseChart,
    ComparingChart,
    CDatePicker,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    SearchShowsChannel.on('filters', (payload) => this.receiveFilters(payload));
    SearchShowsChannel.on('chartData', (payload) => this.receiveChartData(payload));
    SearchShowsChannel.on('comparingChartData', (payload) => this.receiveCompragingChartData(payload));

    SearchShowsChannel.on('chartDataEx', (payload) => this.receiveChartDataEx(payload));


    let yAxesConfig = [{
      position: 'left',
      id: 'y-axis-0',
      ticks: {
        display: true,
        fontColor: '#ffffff'
      },
    }, {
      position: 'right',
      id: 'y-axis-1',
      ticks: {
        display: true,
        fontColor: '#ffffff'
      },
    }];

    this.$refs.rankingChart.setYAxes(yAxesConfig);
    this.$refs.rankingChartEx.setYAxes(yAxesConfig);

    this.loadFilters();
  },
  methods: {
    primaryFilterSelected() {
      console.log("primaryFilterSelected");
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.universityGroupOptions = data.groups;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.locationOptions = data.locationTypes;
      this.accountTypeOptions = data.accountTypes;

      this.dateRange = [ moment(data.semesterStart).toDate(), moment().toDate() ];

      this.loadingFilters = false;
    },
    receiveCompragingChartData(data) {
      console.log("receiveCompragingChartData#");

      this.hasCompareChartData = true;

      this.$refs.compareChart.setLabels(data.dates);
      this.$refs.compareChart.setSeries(0, data.shows, "Ano atual");
      this.$refs.compareChart.setSeries(1, data.previous_shows, "Ano anterior");

      this.$nextTick(() => {
        this.$refs.compareChart.updateChart();
      });
    },
    receiveChartDataEx(data) {
      console.log("receiveChartDataEx#");

      this.hasChartData = true;

      this.$refs.rankingChartEx.setYMax(100);
      this.$refs.rankingChartEx.setXAxesStacked();
      this.$refs.rankingChartEx.setYAxesStacked();
      this.$refs.rankingChartEx.setLabels(data.dates);

      this.$refs.rankingChartEx.setSeriesWithOptions(0, data.visits, 'Visitas', {type: 'line', borderWidth: 4, yAxisID: 'y-axis-1'});

      for (var i = 0; i < 10; i++) {
        this.$refs.rankingChartEx.setSeriesWithOptions(i + 1, data.percents[`${i + 1}`], `Posição ${i + 1}`, {});
      }
      this.$refs.rankingChartEx.setSeriesWithOptions(11, data.percents[`11`], `Outras páginas`, {});


      this.$nextTick(() => {
        this.$refs.rankingChartEx.updateChart();
      });

      this.$refs.rankingChartEx.setYAxisTitle("Percentual", 0);
      this.$refs.rankingChartEx.setYAxisTitle("Visitas", 1);

      this.dataLoading = false;
    },
    receiveChartData(data) {
      console.log("receiveChartData#");

      this.hasChartData = true;

      this.$refs.rankingChart.setXAxesStacked();
      this.$refs.rankingChart.setYAxesStacked();
      this.$refs.rankingChart.setLabels(data.dates);

      this.$refs.rankingChart.setSeriesWithOptions(0, data.sums, 'Total', {type: 'line', borderWidth: 4, yAxisID: 'y-axis-1'});

      for (var i = 0; i < 5; i++) {
        this.$refs.rankingChart.setSeriesWithOptions(i + 1, data.percents[`${i + 1}`], `Página ${i + 1}`, {});
      }


      this.$nextTick(() => {
        this.$refs.rankingChart.updateChart();
      });

      this.$refs.rankingChart.setYAxisTitle("Percentual", 0);
      this.$refs.rankingChart.setYAxisTitle("Exibições", 1);

      this.dataLoading = false;
    },
    loadFilters() {
      SearchShowsChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      if (!this.$refs.filter.validateFilter()) {
        return;
      }

      let filter = this.$refs.filter.filterSelected();
      console.log("loadData filter: " + JSON.stringify(filter));

      this.tableData = [];
      this.$refs.rankingChart.clearSeries();
      this.$refs.rankingChartEx.clearSeries();
      this.$refs.compareChart.clearSeries();
      this.dataLoading = true;

      filter.initialDate = this.dateRange[0];
      filter.finalDate = this.dateRange[1];
      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;

      SearchShowsChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
