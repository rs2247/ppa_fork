<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel comparativo
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
            <panel-filter
              :period-disabled="false"
              ref="currentFilter"
              index="0"
              @primaryFilterSelected="currentPrimarySelected"
              @locationTypeSelected="currentLocationTypeSelected"
              @locationSelected="currentLocationSelected"
              @timeRangeSelected="currentRangeSelected"
              @kindSelected="currentKindSelected"
              @levelSelected="currentLevelSelected"></panel-filter>

              <div class="row">
                <div class="col-md-3 col-sm-12">
                  <label>AGRUPAMENTO</label>
                  <multiselect v-model="grouping" :options="currentGroupingOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input="groupValueSelected"></multiselect>
                </div>

                <div class="col-md-3 col-sm-12" v-show="grouping">
                  <label>NÚMERO DE SÉRIES</label>
                  <multiselect v-model="groupingMax" :options="groupingMaxOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input="groupMaxSelected"></multiselect>
                </div>

                <template v-if="canSelectSeries">

                  <div class="col-md-3 col-sm-12" v-show="grouping">
                    <label>SELEÇÃO DE SÉRIES</label>
                    <multiselect v-model="seriesSelection" :options="seriesSelectionOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input=""></multiselect>
                  </div>


                  <div class="col-md-3 col-sm-12" v-show="grouping">
                    <label>CAMPO DE SELEÇÃO</label>
                    <multiselect v-model="seriesSelectionField" :allow-empty="false" :options="seriesSelectionFieldOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input=""></multiselect>
                  </div>
                </template>
              </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadData">
                    Atualizar
                  </button>

                  <div class="default-margin-left" v-if="hasData">
                    <div  class="dropdown" data-ref="export-data">
                      <div class="dropdown-toggle" data-toggle="dropdown">
                        <span class="flex-grow dropdown-label" style="margin-right: 5px;">Exportar</span>
                        <span class="glyphicon glyphicon-chevron-down float-right"></span>
                      </div>
                      <ul class="dropdown-menu">
                        <!-- li v-show="hasSerie"><a class="clickable" @click="exportData('0', 'dashboard')">Série</a></li -->
                        <!-- li v-show="hasComparative"><a class="clickable" @click="exportData(1, 'comparativo')">Comparativo</a></li -->
                      </ul>
                    </div>
                  </div>

                  <div class="small-margin-left" style="display: none;">
                    <input type="checkbox" v-model="movelMean"> Média móvel
                  </div>

                  <div style="justify-content: flex-end; margin-left: 50px;">
                    <div :class="consolidatedButtonClass" style="display: inline; padding: 3px;">
                      <span class=" glyphicon glyphicon-barcode" @click="consolidatedCharts" title="Gráficos lado a lado"></span>
                    </div>
                    <div :class="expandedButtonClass" style="display: inline; padding: 3px;">
                      <span class="glyphicon glyphicon-book" @click="expandedCharts" title="Gráficos em linhas"></span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div :class="chartClass">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">TAXA DE ATRATIVIDADE (%) {{ chartNameSufix }}</div>
          <comparing-chart ref="atractionChart" export-name="taxa_atratividade"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">TAXA DE SUCESSO (%) {{ chartNameSufix }}</div>
          <comparing-chart ref="successChart" export-name="taxa_sucesso"></comparing-chart>
        </div>
      </div>

      <div :class="conversionChartClass">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">CONVERSÃO (%) {{ chartNameSufix }}</div>
          <comparing-chart ref="conversionChart" export-name="taxa_conversao"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="initiatedChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">ORDENS INICIADAS {{ chartNameSufix }}</div>
          <comparing-chart ref="initiatedOrdersChart" export-name="ordens_iniciadas"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="paidsChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">ORDENS PAGAS {{ chartNameSufix }}</div>
          <comparing-chart ref="paidOrdersChart" export-name="ordens_pagas"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="visitsChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VISITAS EM PÁGINAS DE OFERTA {{ chartNameSufix }}</div>
          <comparing-chart ref="offerVisitsChart" export-name="visitas_ofertas"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="universityVisitsChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VISITAS PÁGINA DA UNIVERSIDADE {{ chartNameSufix }}</div>
          <comparing-chart ref="universityVisitsChart" export-name="visitas_universidade"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="incomeChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">RECEITA {{ chartNameSufix }}</div>
          <comparing-chart ref="incomeChart" export-name="receita"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="velocityChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VELOCIMETRO {{ chartNameSufix }}</div>
          <comparing-chart ref="velocityCompareChart" export-name="velocimetro"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="ticketChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">TICKET MEDIO {{ chartNameSufix }}</div>
          <comparing-chart ref="ticketChart" export-name="ticket_medio"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="meanIncomeChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">FAT/ORDEM {{ chartNameSufix }}</div>
          <comparing-chart ref="meanIncomeChart" export-name="fat_ordem"></comparing-chart>
        </div>
      </div>

      <div :class="chartClass" v-show="cumRevenueChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">RECEITA ACUMULADA</div>
          <comparing-chart ref="cumRevenueChart" export-name="receita_acumulada"></comparing-chart>
        </div>
      </div>


      <div :class="chartClass" v-show="rawPaidsChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">PAGOS (sem media móvel)</div>
          <comparing-chart ref="rawPaidsChart" export-name="pagos_base"></comparing-chart>
        </div>
      </div>


      <div :class="chartClass" v-show="cumPaidsChartAvailable">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">ACUMULADO DE PAGOS</div>
          <comparing-chart ref="cumPaidsChart" export-name="acumulado_pagos"></comparing-chart>
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import _ from 'lodash'

import PanelFilter from './panel-filter';
import moment from 'moment';
import Multiselect from 'vue-multiselect'
import ComparingChart from './comparing-chart'

export default {
  data() {
    return {
      colConfig: 6,
      loading: false,
      loadingFilters: true,
      movelMean: true,
      grouping: null,
      groupingMax: null,
      seriesSelection: null,
      currentGroupingOptions: [],
      groupingMaxOptions: [
        { name: 'Top 5', id: 5 },
        { name: 'Top 10', id: 10 },
        { name: 'Top 15', id: 15 },
        { name: 'Top 20', id: 20 },
        { name: 'Máximo', id: 0 },
      ],
      groupingOptions: [
        { name: "Estado", id: "state" },
        { name: "Carteira", id: "account_type" },
        { name: "IES", id: "university" },
        { name: "Grupo Educacional", id: "group" },
        { name: "Nível", id: "level" },
        { name: "Modalidade", id: "kind" },
        { name: "Cidade", id: "city" },
      ],
      seriesSelectionOptions: [
        { name: 'Maiores altas' , id: 'higher_up' },
        { name: 'Maiores baixas' , id: 'higher_down' },
        { name: 'Maiores valores' , id: 'higher' },
        { name: 'Menores valores' , id: 'lower' },
      ],
      seriesSelectionFieldOptions: [
        { name: 'Ordens', id: 'orders' },
        { name: 'Visitas', id: 'visits' },
        { name: 'Pagos', id: 'paids' },
        { name: 'Receita', id: 'income' },
        { name: 'Taxa de Sucesso', id: 'success_rate' },
        { name: 'Taxa de Atratividade', id: 'atraction_rate' },
        { name: 'Taxa de Conversão', id: 'conversion_rate' },
      ],
      fullData: [],
      initiatedChartAvailable: true,
      paidsChartAvailable: true,
      visitsChartAvailable: true,
      cumRevenueChartAvailable: true,
      meanIncomeChartAvailable: true,
      ticketChartAvailable: true,
      velocityChartAvailable: false,
      incomeChartAvailable: true,
      universityVisitsChartAvailable: true,
      rawPaidsChartAvailable: true,
      cumPaidsChartAvailable: true,
      charts: [],
      seriesSelectionField: null,
      currentPrimaryType: null,
    }
  },
  components: {
    PanelFilter,
    Multiselect,
    ComparingChart,
  },
  computed: {
    canSelectSeries() {
      if (this.currentPrimaryType != 'universities') {
        return true;
      }
      return _.isNil(this.grouping) || this.grouping['id'] != 'university';
    },
    consolidatedButtonClass() {
      if (this.colConfig == 12) {
        return "clickable";
      }
      return "active-border clickable";
    },
    expandedButtonClass() {
      if (this.colConfig == 6) {
        return "clickable";
      }
      return "active-border clickable";
    },
    conversionChartClass() {
      //if (this.initiatedChartAvailable) {
        return `col-md-${this.colConfig} col-sm-12`;
      //}
      //return `col-md-12 col-sm-12`;
    },
    chartClass() {
      return `col-md-${this.colConfig} col-sm-12`;
    },
  },
  mounted() {
    ComparingChannel.on('filters', (payload) => this.receiveFilters(payload));
    ComparingChannel.on('ordersData', (payload) => this.receiveOrdersData(payload));

    ComparingChannel.on('citiesFilterData', (payload) => this.receiveCitiesFilter(payload));
    ComparingChannel.on('campusFilterData', (payload) => this.receiveCampusFilter(payload));

    this.currentGroupingOptions = this.groupingOptions;
    this.groupingMax = this.groupingMaxOptions[0];
    this.seriesSelection = this.seriesSelectionOptions[0];
    this.seriesSelectionField = this.seriesSelectionFieldOptions[0];

    this.charts.push(this.$refs.initiatedOrdersChart);
    this.charts.push(this.$refs.paidOrdersChart);
    this.charts.push(this.$refs.offerVisitsChart);
    this.charts.push(this.$refs.successChart);
    this.charts.push(this.$refs.conversionChart);
    this.charts.push(this.$refs.atractionChart);
    this.charts.push(this.$refs.universityVisitsChart);
    this.charts.push(this.$refs.incomeChart);
    this.charts.push(this.$refs.cumRevenueChart);
    this.charts.push(this.$refs.ticketChart);
    this.charts.push(this.$refs.meanIncomeChart);
    this.charts.push(this.$refs.rawPaidsChart);
    this.charts.push(this.$refs.cumPaidsChart);
    this.charts.push(this.$refs.velocityCompareChart);

    this.loadFilters();
  },
  methods: {
    consolidatedCharts() {
      this.colConfig = 6;
    },
    expandedCharts() {
      this.colConfig = 12;
    },
    receiveOrdersData(data) {
      this.fullData = data;
      console.log('receiveOrdersData');
      this.populateCharts();
    },
    clearCharts() {
      _.each(this.charts, (chart) => {
        chart.clearSeries();
      });
    },
    populateCharts() {
      if (this.fullData.length == 0) {
        return;
      }
      this.clearCharts();
      if (Object.keys(this.fullData.university_visits).length > 0) {
        this.universityVisitsChartAvailable = true;
      } else {
        this.universityVisitsChartAvailable = false;
      }

      if (Object.keys(this.fullData.velocimeter_mean).length > 0) {
        this.velocityChartAvailable = true;
      } else {
        this.velocityChartAvailable = false;
      }

      _.each(this.charts, (chart) => {
        chart.setLabels(this.fullData.dates);
      });

      let keys = this.fullData.keys;
      let keysNames = this.fullData.keys_names;
      var currentMax = this.groupingMax.id;
      if (currentMax == 0)
        currentMax = 30;

      let maximo = keys.length > currentMax ? currentMax : keys.length;
      for (var i = 0; i < maximo; i++) {
        this.$refs.initiatedOrdersChart.setSeries(i, this.fullData.initiateds[keys[i]], `${keysNames[i]}`);
        this.$refs.paidOrdersChart.setSeries(i, this.fullData.paids[keys[i]], `${keysNames[i]}`);
        this.$refs.offerVisitsChart.setSeries(i, this.fullData.visits[keys[i]], `${keysNames[i]}`);
        this.$refs.successChart.setSeries(i, this.fullData.success[keys[i]], `${keysNames[i]}`);
        this.$refs.conversionChart.setSeries(i, this.fullData.conversion[keys[i]], `${keysNames[i]}`);
        this.$refs.atractionChart.setSeries(i, this.fullData.atraction[keys[i]], `${keysNames[i]}`);
        this.$refs.universityVisitsChart.setSeries(i, this.fullData.university_visits[keys[i]], `${keysNames[i]}`);
        this.$refs.cumRevenueChart.setSeries(i, this.fullData.cum_revenue[keys[i]], `${keysNames[i]}`);
        this.$refs.incomeChart.setSeries(i, this.fullData.income[keys[i]], `${keysNames[i]}`);
        this.$refs.ticketChart.setSeries(i, this.fullData.ticket[keys[i]], `${keysNames[i]}`);
        this.$refs.meanIncomeChart.setSeries(i, this.fullData.mean_income[keys[i]], `${keysNames[i]}`);
        this.$refs.rawPaidsChart.setSeries(i, this.fullData.raw.paids[keys[i]], `${keysNames[i]}`);
        this.$refs.cumPaidsChart.setSeries(i, this.fullData.cum_paids[keys[i]], `${keysNames[i]}`);
        this.$refs.velocityCompareChart.setSeries(i, this.fullData.velocimeter_mean[keys[i]], `${keysNames[i]}`);
      }

      this.$nextTick(() => {
        _.each(this.charts, (chart) => {
          chart.updateChart();
        });
      });

      this.loading = false;
    },
    groupMaxSelected() {
      console.log('groupMaxSelected');
      if (this.fullData.length == 0) {
        return;
      }
      this.loading = true;
      this.$nextTick(() => {
        this.populateCharts();
      });
    },
    groupValueSelected() {
      console.log('groupValueSelected');
    },
    filterGroupingOptions(fields) {
      if (!_.isNil(this.grouping)) {
        if (_.includes(fields, this.grouping.id)) {
          this.grouping = null;
        }
      }
      return _.filter(this.groupingOptions, (entry) => {
        return !_.includes(fields, entry["id"]);
      });
    },
    currentPrimarySelected(data) {
      this.currentPrimaryType = data[0].type;
      console.log('currentPrimarySelected: ' + JSON.stringify(data) + ' currentPrimaryType: ' + this.currentPrimaryType);
      if (data[0].type == 'university') {
        this.currentGroupingOptions = this.filterGroupingOptions(['university','group']);
      } else if (data[0].type == 'account_type') {
        this.currentGroupingOptions = this.filterGroupingOptions(['account_type']);
      } else if (data[0].type == 'group') {
        this.currentGroupingOptions = this.filterGroupingOptions(['group']);
      } else {
        this.currentGroupingOptions = this.groupingOptions;
      }
    },
    baseGroupingOptions() {

    },
    currentLocationTypeSelected(data) {
      console.log('currentLocationTypeSelected: ' + JSON.stringify(data));
      var pushComplete = false;
      if (data.type == 'city') {
        pushComplete = true;
        this.$refs.currentFilter.setCitiesLoading();
      }
      if (data.type == 'campus') {
        pushComplete = true;
        this.$refs.currentFilter.setCampusLoading();
      }
      if (pushComplete) {
        //se faz o push, entao nao pode agrupar por cidade!

        let currentFilter = this.$refs.currentFilter.filterData(true);
        currentFilter.completeField = data.type;

        // let filters = { currentFilter };
        ComparingChannel.push('completeLocation', currentFilter).receive('timeout', (data) => {
          console.log('complete timeout');
        });
      } else {
        //pode completar pode cidade!
      }
    },
    currentLocationSelected(data) {
      console.log('currentLocationSelected: ' + JSON.stringify(data));
    },
    currentRangeSelected() {
      console.log('currentRangeSelected');
    },
    currentKindSelected() {
      console.log('currentKindSelected');
    },
    currentLevelSelected() {
      console.log('currentLevelSelected');
    },
    receiveCitiesFilter(data) {
      this.$refs.currentFilter.setCities(data.cities);
    },
    receiveCampusFilter(data) {
      this.$refs.currentFilter.setCampus(data.campus);
    },
    receiveFilters(data) {
      console.log('receiveFilters');
      this.$refs.currentFilter.setLevels(data.levels)
      this.$refs.currentFilter.setKinds(data.kinds);
      this.$refs.currentFilter.setLocations(data.locationTypes);
      this.$refs.currentFilter.setGroups(data.groupTypes);
      this.$refs.currentFilter.setAccountTypes(data.accountTypes);
      this.$refs.currentFilter.setUniversities(data.universities);
      this.$refs.currentFilter.setUniversityGroups(data.groups);


      if (moment(data.semester_end) > moment()) {
        this.$refs.currentFilter.setSemesterRange(moment(data.semester_start).toDate(), moment().toDate());
      } else {
        this.$refs.currentFilter.setSemesterRange(moment(data.semester_start).toDate(), moment(data.semester_end).toDate());
      }

      this.$refs.currentFilter.setDealOwners(data.dealOwners);
      this.$refs.currentFilter.setQualityOwners(data.qualityOwners);
      this.$refs.currentFilter.setRegions(data.regions);
      this.$refs.currentFilter.setStates(data.states);
      this.$refs.currentFilter.setCities([]);
      this.$refs.currentFilter.setCampus([]);
      this.$refs.currentFilter.setProductLines(data.product_lines);

      this.loadingFilters = false;
    },
    loadFilters() {
      ComparingChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      let currentFilter = this.$refs.currentFilter.filterData();
      if (!currentFilter) {
        console.log("currentFilter vazio");
        return;
      }

      this.loading = true;
      let filter = { currentFilter };
      currentFilter.grouping = this.grouping;
      currentFilter.seriesSelection = this.seriesSelection["id"];
      currentFilter.seriesSelectionField = this.seriesSelectionField["id"];

      this.clearCharts();

      ComparingChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      }).receive('error', (data) => {
        console.log('loadData error');
      });
    }
  },
};

</script>
