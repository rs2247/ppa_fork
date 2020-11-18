<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel de Velocímetro
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loadingFilters || loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">

            <div class="row" >
              <div class="col-md-12 col-sm-6">
                <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" :account-type-options="accountTypeOptions" :deal-owner-options="dealOwnerOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
              </div>
            </div>

            <div class="row" >
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="">LINHA DE PRODUTO</label>
                  <cs-multiselect v-model="productLineFilter" :options="productLineOptions" label="name" placeholder="Selecione a linha de produto" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></cs-multiselect>
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

    <div class="row">
      <div class="col-md-12 col-sm-12">
        <div class="panel report-panel panel-default">
          <table class="data-table data-table-tiny no-wrap">
            <thead>
              <tr>
                <th>Velocidade mínima para bater a meta</th>
                <th style="width: 200px; background-color: #3B4347;"></th>
                <th>Velocímetro final projetado na velocidade atual</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{{ minimumSpeed }}</td>
                <td></td>
                <td>{{ projectedSpeed }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-md-8 col-sm-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">RECEITA e VELOCIMETRO ( meta movel )</div>
          <comparing-chart ref="goalChart" export-name="receita_e_velocimetro"></comparing-chart>
        </div>
      </div>

      <div class="col-md-4 col-sm-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">RECEITA e VELOCIMETRO ( acumulado )</div>
          <comparing-chart ref="cumGoalChart" export-name="receita_e_velocimetro_acumulados"></comparing-chart>
        </div>
      </div>
    </div>

    <div class="row">

    </div>
  </div>
</template>


<script>
import _ from 'lodash'

import QueryString from '../js/query-string'
import ComparingChart from './comparing-chart'
import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import CDatePicker from './custom-date-picker'

export default {
  data() {
    return {
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      accountTypeOptions: [],
      productLineOptions: [],
      dealOwnerOptions: [],
      productLineFilter: null,
      loadingFilters: true,
      loading: false,
      minimumSpeed: null,
      projectedSpeed: null,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    CDatePicker,
    ComparingChart,
  },
  mounted() {
    IesChannel.on('filters', (payload) => this.receiveFilters(payload));
    IesChannel.on('goalChartData', (payload) => this.receiveGoalChartData(payload));

    let yAxesConfig = [{
      position: 'right',
      id: 'y-axis-0',
      ticks: {
        display: true,
        fontColor: '#ffffff'
      },
    }, {
      position: 'left',
      id: 'y-axis-1',
      ticks: {
        display: true,
        fontColor: '#ffffff'
      },
    }];

    this.$refs.goalChart.setYAxes(yAxesConfig);
    this.$refs.cumGoalChart.setYAxes(yAxesConfig);

    this.loadFilters();
  },
  methods: {
    dumpQueryString() {
      let queryString = '';

      if (!this.$refs.filter.validateFilter()) {
        return;
      }

      if (_.isNil(this.productLineFilter)) {
        return;
      }

      let filter = this.filtersMap();
      queryString = '?type=' + filter['type'];
      if (!_.isNil(filter['value'])) {
        queryString = queryString + '&value=' + JSON.stringify(filter['value']);
      }
      queryString = queryString + '&product_line_id=' + filter['product_line_id'];

      window.history.pushState('', '', window.location.pathname + queryString);
    },
    parseQueryString() {
      const urlParams = new URLSearchParams(window.location.search);

      let filterType = urlParams.get('type');
      let filterValue = urlParams.get('value');
      let productLineFilter = urlParams.get('product_line_id');

      if (!_.isNil(filterValue)) {
        filterValue = JSON.parse(filterValue);
      }
      let hasFilter = false;
      if (!_.isNil(filterType)) {
        hasFilter = true;
      }

      console.log('productLineFilter: ' + productLineFilter + ' filterType: ' + filterType + ' filterValue: ' + JSON.stringify(filterValue));

      this.productLineFilter = QueryString.solveEntry(this.productLineOptions, productLineFilter, 'id');
      this.$refs.filter.setFilterType(QueryString.solveEntry(this.filterOptions, filterType, 'type'));
      if (filterType == 'university') {
        this.$refs.filter.setUniversityFilter(QueryString.solveEntry(this.universityOptions, filterValue.id, 'id'));
      }
      if (filterType == 'group') {
        this.$refs.filter.setUniversityGroupFilter(QueryString.solveEntry(this.universityGroupOptions, filterValue.id, 'id'));
      }
      if (filterType == 'account_type') {
        this.$refs.filter.setAccountTypeFilter(QueryString.solveEntry(this.accountTypeOptions, filterValue.id, 'id'));
      }
      if (filterType == 'deal_owner' || filterType == 'deal_owner_ies') {
        this.$refs.filter.setDealOwnerFilter(QueryString.solveEntry(this.dealOwnerOptions, filterValue.id, 'id'));
      }

      if (hasFilter) {
        this.$nextTick(() => {
          this.loadData();
        });
      }
    },
    primaryFilterSelected(data) {
      console.log('primaryFilterSelected: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.universityGroupOptions = data.groups;
      this.accountTypeOptions = data.account_types;
      this.filterOptions = data.filters;
      this.productLineOptions = data.product_lines;
      this.dealOwnerOptions = data.deal_owners;

      this.loadingFilters = false;

      this.parseQueryString();
    },
    receiveGoalChartData(data) {
      this.$refs.goalChart.setLabels(data.dates);
      this.$refs.goalChart.setSeries(0, data.goal_projection, "META");
      this.$refs.goalChart.setSeries(1, data.revenue, "RECEITA");
      this.$refs.goalChart.setSeriesWithOptions(2, data.velocimeter, "VELOCIMETRO", { yAxisID: 'y-axis-1', fill: false});


      this.$refs.cumGoalChart.setLabels(data.dates);
      this.$refs.cumGoalChart.setSeries(0, data.goal_projection_sum, "META");
      this.$refs.cumGoalChart.setSeries(1, data.revenue_sum, "RECEITA");
      this.$refs.cumGoalChart.setSeriesWithOptions(2, data.velocimeter_sum, "VELOCIMETRO", { yAxisID: 'y-axis-1', fill: false});

      //this.$refs.cumGoalChart.setXAxisTitle(0, "Data");
      this.$refs.goalChart.setYAxisTitle("Receita (R$)", 0);
      this.$refs.goalChart.setYAxisTitle("Velocímetro (%)", 1);

      //this.$refs.cumGoalChart.setXAxisTitle(0, "Data");
      this.$refs.cumGoalChart.setYAxisTitle("Receita (R$)", 0);
      this.$refs.cumGoalChart.setYAxisTitle("Velocímetro (%)", 1);

      let maxVelocity = _.max(data.velocimeter);
      if (data.minimum_speed > maxVelocity) {
        let maxValue = Math.ceil((data.minimum_speed * 1.1) / 10) * 10;
        this.$refs.goalChart.setYMax(maxValue, 1);
      } else {
        this.$refs.goalChart.removeYMax(1);
      }

      this.minimumSpeed = data.minimum_speed_formatted;
      this.projectedSpeed = data.projected_velocity_formatted;

      this.$refs.goalChart.setHorizontalPoint(2, data.minimum_speed);

      this.$nextTick(() => {
        this.$refs.goalChart.updateChart();
        this.$refs.cumGoalChart.updateChart();
      });

      this.loading = false;
    },
    loadFilters() {
      IesChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    filtersMap() {
      let filter = this.$refs.filter.filterSelected();
      filter.product_line_id = this.productLineFilter.id;
      return filter;
    },
    loadData() {
      if (!this.$refs.filter.validateFilter()) {
        return;
      }

      if (_.isNil(this.productLineFilter)) {
        alert("Selecione a linha de produto");
        return;
      }
      let filter = this.filtersMap();

      this.dumpQueryString();

      this.loading = true;
      this.$refs.cumGoalChart.clearSeries();
      this.$refs.goalChart.clearSeries();
      this.minimumSpeed = null;
      this.projectedSpeed = null;

      IesChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
