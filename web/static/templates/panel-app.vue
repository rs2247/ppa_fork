<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Dashboard comparativo
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="col-md-12">

        <div class="transparent-loader" v-if="filtersLoading">
          <div class="loader"></div>
        </div>

        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <panel-filter :period-disabled="false" ref="currentFilter" index="0" @primaryFilterSelected="currentPrimarySelected" @locationTypeSelected="currentLocationTypeSelected" @locationSelected="currentLocationSelected" @timeRangeSelected="currentRangeSelected" @kindSelected="currentKindSelected" @levelSelected="currentLevelSelected" @productLineSelected="currentProductLineSelected" @productLineSelectionTypeSelected="currentProductLineSelectionTypeSelected"></panel-filter>

            <div class="row">
              <div class="col-md-12 col-sm-12">
                <div class="row">
                  <div class="col-md-3 col-sm-12">
                    <div>
                      <label>COMPARATIVO</label>
                      <multiselect v-model="comparingMode" :options="comparingOptions" :allowEmpty="false" label="name" track-by="type" placeholder="Selecione o comparativo" selectLabel="Enter para selecionar" deselectLabel="" @input="compareSelected"></multiselect>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <panel-filter :period-disabled="true" ref="comparingFilter" index="1" v-show="showComparingFilter" @locationTypeSelected="currentLocationTypeSelected"></panel-filter>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="update" :enabled="updateEnabled">
                    Atualizar
                  </button>

                  <div class="default-margin-left" v-if="hasData">
                    <div  class="dropdown" data-ref="export-data">
                      <div class="dropdown-toggle" data-toggle="dropdown">
                        <span class="flex-grow dropdown-label" style="margin-right: 5px;">Exportar</span>
                        <span class="glyphicon glyphicon-chevron-down float-right"></span>
                      </div>
                      <ul class="dropdown-menu">
                        <li v-show="hasSerie"><a class="clickable" @click="exportData('0', 'dashboard')">Série</a></li>
                        <li v-show="hasComparative"><a class="clickable" @click="exportData(1, 'comparativo')">Comparativo</a></li>
                      </ul>
                    </div>
                  </div>



                  <div style="justify-content: flex-end; margin-left: 50px;">
                    <div :class="consolidatedButtonClass" style="display: inline; padding: 3px;">
                      <span class=" glyphicon glyphicon-barcode" @click="consolidatedCharts" title="Gráficos lado a lado"></span>
                    </div>
                    <div :class="expandedButtonClass" style="display: inline; padding: 3px;">
                      <span class="glyphicon glyphicon-book" @click="expandedCharts" title="Gráficos em linhas"></span>
                    </div>
                  </div>


                  <div class="small-margin-left">

                    <div  class="dropdown" data-ref="export-data" style="border: none !important;">
                      <div class="dropdown-toggle" data-toggle="dropdown">
                        <span class="flex-grow dropdown-label" style="margin-right: 5px;">Opções</span>
                        <span class="glyphicon glyphicon-chevron-down float-right"></span>
                      </div>
                      <ul class="dropdown-menu">
                        <li><a class="clickable" @click="toggleMovelMean()"> <span class="glyphicon glyphicon-check float-right" v-if="movelMean"></span> Média móvel</a></li>
                      </ul>
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
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">CONSOLIDADO</div>
          <div class="row">
            <div class="col-md-12 col-sm-12">
              <div class="transparent-loader" v-if="tableLoading">
                <div class="loader"></div>
              </div>

              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny">
                    <thead>
                      <tr v-if="seriesNames[0] && seriesMetrics[0]">
                        <th></th>
                        <th :colspan="seriesMetrics[0].length">{{ seriesNames[0] }}</th>
                        <template v-if="seriesMetrics[1]">
                          <th style="width: 200px; background-color: #3B4347;"></th>
                          <th :colspan="seriesMetrics[1].length">{{ seriesNames[1] }}</th>
                        </template>
                      </tr>
                      <tr>
                        <th></th>
                        <th v-for="serie in seriesMetrics[0]">
                          {{ serie.name }}
                        </th>
                        <template v-if="seriesNames[1]">
                          <th style="background-color: #3B4347;"></th>
                          <th v-for="serie in seriesMetrics[1]">
                            {{ serie.name }}
                          </th>
                        </template>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(metric, index) in metrics">
                        <td>{{ metric }}</td>
                        <td v-for="serie in seriesMetrics[0]">
                          {{ serie.serie[index] }}
                        </td>
                        <template v-if="seriesNames[1]">
                          <td></td>
                          <td v-for="serie in seriesMetrics[1]">
                            {{ serie.serie[index] }}
                          </td>
                        </template>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="row">
          <div :class="chartClass">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">TAXA DE ATRATIVIDADE (%) {{ chartNameSufix }}</div>
              <comparing-chart ref="atractionCompareChart" export-name="taxa_atratividade"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">TAXA DE SUCESSO (%) {{ chartNameSufix }}</div>
              <comparing-chart ref="successCompareChart" export-name="taxa_sucesso"></comparing-chart>
            </div>
          </div>

          <div :class="conversionChartClass">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">CONVERSÃO (%) {{ chartNameSufix }}</div>
              <comparing-chart ref="conversionCompareChart" export-name="taxa_conversao"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="initiatedChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">ORDENS INICIADAS {{ chartNameSufix }}</div>
              <comparing-chart ref="initiatedCompareChart" export-name="ordens_iniciadas"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="paidsChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">ORDENS PAGAS {{ chartNameSufix }}</div>
              <comparing-chart ref="paidCompareChart" export-name="ordens_pagas"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="visitsChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">VISITAS EM PÁGINAS DE OFERTA {{ chartNameSufix }}</div>
              <comparing-chart ref="visitsCompareChart" export-name="visitas_ofertas"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="universityVisitsChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">VISITAS PÁGINA DA UNIVERSIDADE {{ chartNameSufix }}</div>
              <comparing-chart ref="visitsUniversityCompareChart" export-name="visitas_universidade"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="incomeChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">RECEITA (R$) {{ chartNameSufix }}</div>
              <comparing-chart ref="incomeCompareChart" export-name="receita"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="velocityChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">VELOCIMETRO (%) {{ chartNameSufix }}</div>
              <comparing-chart ref="velocityCompareChart" export-name="velocimetro"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="velocityChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">RECEITA-QAP (R$) {{ chartNameSufix }}</div>
              <comparing-chart ref="incomeQapCompareChart" export-name="receita_qap"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="ticketChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">TICKET MEDIO (R$) {{ chartNameSufix }}</div>
              <comparing-chart ref="ticketCompareChart" export-name="ticket_medio"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="meanIncomeChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">FAT/ORDEM (R$) {{ chartNameSufix }}</div>
              <comparing-chart ref="meanIncomeCompareChart" export-name="fat_ordem"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="cumRevenueChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">RECEITA ACUMULADA (%)</div>
              <comparing-chart ref="cumRevenueCompareChart" export-name="receita_acumulada"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="refundCompareChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">REEMBOLSOS</div>
              <comparing-chart ref="refundCompareChart" export-name="reembolsos"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="refundPerPaidsCompareChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">REEMBOLSO / PAGOS ( acumulado no período )</div>
              <comparing-chart ref="refundPerPaidsCompareChart" export-name="reembolsos_por_pagos"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="bosCompareChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">BOS</div>
              <comparing-chart ref="bosCompareChart" export-name="bos"></comparing-chart>
            </div>
          </div>

          <div :class="chartClass" v-show="bosPerPaidsCompareChartAvailable">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">BOS / PAGOS ( acumulado no período )</div>
              <comparing-chart ref="bosPerPaidsCompareChart" export-name="bos_por_pagos"></comparing-chart>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
//import DatePicker from 'vue2-datepicker'
import Multiselect from 'vue-multiselect'
import moment from 'moment';

import PanelFilter from './panel-filter';
import ComparingChart from './comparing-chart'

export default {
  data() {
    return {
      colConfig: 6,
      currentData: [],
      hideSensitiveData: false,
      chartNameSufix: '',
      updateEnabled: true,

      universityVisitsChartAvailable: false,
      visitsChartAvailable: false,
      initiatedChartAvailable: false,
      paidsChartAvailable: false,
      incomeChartAvailable: false,
      velocityChartAvailable: false,
      ticketChartAvailable: false,
      meanIncomeChartAvailable: false,
      cumRevenueChartAvailable: false,
      refundCompareChartAvailable: false,
      refundPerPaidsCompareChartAvailable: false,
      bosCompareChartAvailable: false,
      bosPerPaidsCompareChartAvailable: false,

      movelMean: true,
      baseMetrics: ['ATRATIVIDADE', 'SUCESSO', 'CONVERSÃO', 'ORDENS INICIADAS', 'ORDENS PAGAS', 'ORDENS TROCADAS', 'VISITAS', 'RECEITA', 'RECEITA-QAP', 'VELOCIDADE', 'TICKET MÉDIO', 'FAT/ORDEM', 'BOS', 'REEMBOLSOS'],
      simplifiedMetrics: ['ATRATIVIDADE', 'SUCESSO', 'CONVERSÃO'],
      metrics: [],
      seriesMetrics: [],
      seriesNames: [],
      seriesChartData: [],
      filtersLoading: true,
      tableLoading: false,
      comparingMode: '',
      comparingOptions: [
        {
          name: 'Ano a Ano',
          type: 'year_to_year'
        },
        {
          name: 'Site Todo',
          type: 'all_data'
        },
        {
          name: 'Customizado',
          type: 'custom_compare'
        },
        {
          name: 'Sem comparativo',
          type: 'no_compare'
        },
      ],
      allCharts: [],
    }
  },
  computed: {
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
      if (this.initiatedChartAvailable) {
        return `col-md-${this.colConfig} col-sm-12`;
      }
      return `col-md-12 col-sm-12`;
    },
    chartClass() {
      return `col-md-${this.colConfig} col-sm-12`;
    },
    hasData() {
      return this.currentData.length > 0;
    },
    hasSerie() {
      if (this.currentData.length < 1 || (this.currentData.length > 0 && this.currentData[0].length == 0)) {
        return false;
      }
      return true;
    },
    hasComparative() {
      if (this.currentData.length < 2 || (this.currentData.length > 1 && this.currentData[1].length == 0)) {
        return false;
      }
      return true;
    },
    showComparingFilter() {
      if (this.comparingMode == '')
        return false;
      return this.comparingMode.type == 'custom_compare';
    },
  },
  mounted() {
    this.metrics = this.simplifiedMetrics;
    this.comparingMode = this.comparingOptions[0];
    //prepare to receive broadcasts
    PanelChannel.on('chartData', (payload) => this.receiveChardata(payload));
    PanelChannel.on('filterData', (payload) => this.receiveFilterdata(payload));
    PanelChannel.on('tableData', (payload) => this.receiveTableData(payload));
    PanelChannel.on('citiesFilterData', (payload) => this.receiveCitiesFilterData(payload));
    PanelChannel.on('campusFilterData', (payload) => this.receiveCampusFilterData(payload));

    this.loadFilters();

    this.allCharts.push(this.$refs.atractionCompareChart);
    this.allCharts.push(this.$refs.successCompareChart);
    this.allCharts.push(this.$refs.incomeCompareChart);
    this.allCharts.push(this.$refs.ticketCompareChart);
    this.allCharts.push(this.$refs.meanIncomeCompareChart);
    this.allCharts.push(this.$refs.conversionCompareChart);
    this.allCharts.push(this.$refs.paidCompareChart);
    this.allCharts.push(this.$refs.initiatedCompareChart);
    this.allCharts.push(this.$refs.velocityCompareChart);
    this.allCharts.push(this.$refs.visitsCompareChart);
    this.allCharts.push(this.$refs.visitsUniversityCompareChart);
    this.allCharts.push(this.$refs.cumRevenueCompareChart);
    this.allCharts.push(this.$refs.refundCompareChart);
    this.allCharts.push(this.$refs.refundPerPaidsCompareChart);
    this.allCharts.push(this.$refs.bosCompareChart);
    this.allCharts.push(this.$refs.bosPerPaidsCompareChart);
    this.allCharts.push(this.$refs.incomeQapCompareChart);
  },
  components: {
    Multiselect,
    ComparingChart,
    PanelFilter,
  },
  props: ['managingUser'],
  methods: {
    toggleMovelMean() {
      this.movelMean = !this.movelMean;
    },
    consolidatedCharts() {
      this.colConfig = 6;
    },
    expandedCharts() {
      this.colConfig = 12;
    },
    emptyNull(value) {
      if (_.isNil(value)) {
        return "";
      }
      return value;
    },
    exportData(index, name) {
      var filename = name + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
      var content = "Data;Atratividade;Sucesso;Conversao;Ordens Inciadas;Ordens Pagas;Visitas Ofertas;Receita;Velocidade;Ticket Medio;Fat Ordem;Visitas IES\n"
      _.each(this.currentData[index].orders_dates, (item, itemIndex) => {
        let velocity = null;
        if (!_.isNil(this.currentData[index].velocity)) {
          velocity = this.currentData[index].velocity[itemIndex];
        }
        content = content + item + ";"
          + this.emptyNull(this.currentData[index].atraction_rate[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].success_rate[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].conversion_rate[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].initiateds[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].paids[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].visits[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].income[itemIndex]) + ";"
          + this.emptyNull(velocity) + ";"
          + this.emptyNull(this.currentData[index].ticket[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].mean_income[itemIndex]) + ";"
          + this.emptyNull(this.currentData[index].university_visits[itemIndex])
          + "\n";
      });

      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
    hideCharts() {
      this.universityVisitsChartAvailable = false;
      this.visitsChartAvailable = false;
      this.initiatedChartAvailable = false;
      this.paidsChartAvailable = false;
      this.incomeChartAvailable = false;
      this.velocityChartAvailable = false;
      this.ticketChartAvailable = false;
      this.meanIncomeChartAvailable = false;
      this.cumRevenueChartAvailable = false;
      this.refundCompareChartAvailable = false;
      this.refundPerPaidsCompareChartAvailable = false;
      this.bosCompareChartAvailable = false;
      this.bosPerPaidsCompareChartAvailable = false;
    },
    compareSelected(data) {
      console.log("compareSelected: data: " + JSON.stringify(data));
      if (data.type == 'year_to_year') {
        this.syncComparingFilters();
      } else {
        if (data.type == 'all_data') {
          console.log("compare all data");
          this.syncBaseComparingFilters();
          this.$refs.comparingFilter.clearPrimaryFilters();
        }
        this.$refs.comparingFilter.setDateRange(this.$refs.currentFilter.dateRange);
      }
    },
    syncComparingFilters() {
      this.syncBaseComparingFilters();
      this.$refs.comparingFilter.setPrimaryFilters(this.$refs.currentFilter.baseFiltersList());
      this.$refs.comparingFilter.setDateRange([moment(this.$refs.currentFilter.dateRange[0]).subtract(12, 'months').toDate(),moment(this.$refs.currentFilter.dateRange[1]).subtract(12, 'months').toDate()]);
    },
    syncBaseComparingFilters() {
      this.$refs.comparingFilter.setFilterKinds(this.$refs.currentFilter.filterKinds);
      this.$refs.comparingFilter.setFilterLevels(this.$refs.currentFilter.filterLevels);
      this.$refs.comparingFilter.setLocationValue(this.$refs.currentFilter.locationType, this.$refs.currentFilter.locationValue());
    },
    currentKindSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setFilterKinds(data);
    },
    currentProductLineSelectionTypeSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setProductLineSelectionType(data);
    },
    currentProductLineSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setProductLineFilter(data);
    },
    currentLevelSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setFilterLevels(data);
    },
    currentRangeSelected(data) {
      if (this.comparingMode.type == 'custom_compare' || this.comparingMode.type == 'all_data') {
        this.$refs.comparingFilter.setDateRange(data);
      } else {
        this.$refs.comparingFilter.setDateRange([moment(data[0]).subtract(12, 'months').toDate(),moment(data[1]).subtract(12, 'months').toDate()]);
      }
    },
    currentPrimarySelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      if (this.comparingMode.type == 'all_data') {
        return;
      }
      this.$refs.comparingFilter.setPrimaryFilters(data);
    },
    currentLocationTypeSelected(data, index) {
      console.log("currentLocationTypeSelected type: " + data.type + " index: " + index);
      //must auto complete city and states!
      if (data.type == 'city' || data.type == 'campus') {
        //qual eh o filtro que chegou aqui?
        let filterObject = index == 0 ? this.$refs.currentFilter : this.$refs.comparingFilter;
        let filter = filterObject.filterData(true);
        //let filter = this.$refs.currentFilter.filterData(true);
        //console.log("locationTypeSelected# filter: " + JSON.stringify(filter));
        if (filter) {
          filterObject.setCitiesLoading();
          filterObject.setCampusLoading();

          filter.completeField = data.type;
          filter.index = index;

          PanelChannel.push('filterComplete', filter).receive('ok', () => {
            console.log('filterComplete OK');
          })
        }
      }
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setLocationType(data);
    },
    currentLocationSelected(type, value) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setLocationValue(type, value);
    },
    addFilter() {
      this.filters.push(this.filterIndex);
      this.filterIndex = this.filterIndex + 1;
    },
    removeFilter(index) {
      this.filters.splice(this.filters.indexOf(index), 1);
    },
    loadFilters() {
      this.filtersLoading = true;
      PanelChannel.push('loadFilters').receive('ok', (data) => {
        console.log("loadFilters OK");
      }).receive("error", (data) => {
        this.filtersLoading = false;
        console.log("loadFilters ERROR");
      }).receive("timeout", (data) => {
        this.filtersLoading = false;
        console.log("loadFilters TIMEOUT");
      });
    },
    update() {
      let currentFilter = this.$refs.currentFilter.filterData();
      if (!currentFilter) {
        console.log("currentFilter vazio");
        return;
      }

      // como verificar a permissao?
        //preciso carregar no vue!
        console.log("this.managingUser")
      if (this.managingUser) {
        this.hideSensitiveData = false;
        this.metrics = _.cloneDeep(this.baseMetrics);
      } else {
        if (this.comparingMode.type == 'custom_compare' || this.comparingMode.type == 'all_data') {
          this.hideSensitiveData = true;
          this.metrics = _.cloneDeep(this.simplifiedMetrics);
        } else {
          this.hideSensitiveData = false;
          this.metrics = _.cloneDeep(this.baseMetrics);
        }
      }

      if (this.comparingMode.type == 'all_data') {
        this.metrics.splice(3, 0, 'SHARE VISITAS');
        this.metrics.splice(3, 0, 'SHARE PAGOS');
        this.metrics.splice(3, 0, 'SHARE ORDENS');
      }

      let filter = { currentFilter };
      if (this.comparingMode.type != 'no_compare') {
        let comparingFilter = this.$refs.comparingFilter.filterData();
        if (!comparingFilter) {
          console.log("comparingFilter vazio");
        } else {
          filter.comparingFilter = comparingFilter;
        }
      }

      this.currentData = [];
      filter.comparingMode = this.comparingMode.type;

      console.log("FULL_FILTER: " + JSON.stringify(filter));

      this.seriesMetrics = [];
      this.seriesNames = [];

      this.hideCharts();

      _.forEach(this.allCharts, (chart) => {
        chart.setLoader();
        chart.clearSeries();
      });

      this.tableLoading = true;
      this.updateEnabled = false;

      PanelChannel.push('filter', filter).receive('ok', (data) => {
        console.log("response OK");
      }).receive('timeout', (data) => {
          console.log("update timeout");
      }).receive('error', (data) => {
          console.log("update error");
      });
    },
    receiveCitiesFilterData(data){
      if (data.index == 0) {
        this.$refs.currentFilter.setCities(data.cities);
      } else {
        this.$refs.comparingFilter.setCities(data.cities);
      }
    },
    receiveCampusFilterData(data){
      if (data.index == 0) {
        this.$refs.currentFilter.setCampus(data.campus);
      } else {
        this.$refs.comparingFilter.setCampus(data.campus);
      }
    },
    receiveFilterdata(data) {
      this.$refs.currentFilter.setLevels(data.levels)
      this.$refs.currentFilter.setKinds(data.kinds);
      this.$refs.currentFilter.setLocations(data.locationTypes);
      this.$refs.currentFilter.setGroups(data.groupTypes);
      this.$refs.currentFilter.setAccountTypes(data.accountTypes);
      this.$refs.currentFilter.setUniversities(data.universities);
      this.$refs.currentFilter.setUniversityGroups(data.groups);
      this.$refs.currentFilter.setSemesterRange(data.semesterStart, data.semesterEnd);
      this.$refs.currentFilter.setDealOwners(data.dealOwners);
      this.$refs.currentFilter.setQualityOwners(data.qualityOwners);
      this.$refs.currentFilter.setRegions(data.regions);
      this.$refs.currentFilter.setStates(data.states);
      this.$refs.currentFilter.setProductLines(data.product_lines);
      this.$refs.currentFilter.setCities([]);
      this.$refs.currentFilter.setCampus([]);

      this.$refs.comparingFilter.setLevels(data.levels)
      this.$refs.comparingFilter.setKinds(data.kinds);
      this.$refs.comparingFilter.setLocations(data.locationTypes);
      this.$refs.comparingFilter.setGroups(data.groupTypes);
      this.$refs.comparingFilter.setAccountTypes(data.accountTypes);
      this.$refs.comparingFilter.setUniversities(data.universities);
      this.$refs.comparingFilter.setUniversityGroups(data.groups);
      this.$refs.comparingFilter.setSemesterRange(data.semesterStart, data.semesterEnd);
      this.$refs.comparingFilter.setDealOwners(data.dealOwners);
      this.$refs.comparingFilter.setQualityOwners(data.qualityOwners);
      this.$refs.comparingFilter.setRegions(data.regions);
      this.$refs.comparingFilter.setStates(data.states);
      this.$refs.comparingFilter.setProductLines(data.product_lines);
      this.$refs.comparingFilter.setCities([]);
      this.$refs.comparingFilter.setCampus([]);

      this.$refs.comparingFilter.setDateRange([ moment(data.semesterStart).subtract(12, 'months').toDate(), moment(data.semesterEnd).subtract(12, 'months').toDate() ]);

      this.filtersLoading = false;
    },
    receiveChardata(data) {
      console.log("receiveChardata# hideSensitiveData: " + this.hideSensitiveData + " index: " + data.index);

      if (!this.hideSensitiveData) {
        if (data.initiateds.length > 0) {
          this.initiatedChartAvailable = true;
        }
        if (data.paids.length > 0) {
          this.paidsChartAvailable = true;
        }
        if (data.income.length > 0) {
          this.incomeChartAvailable = true;
        }
        if (data.velocity.length > 0) {
          this.velocityChartAvailable = true;
        }
        if (data.visits.length > 0) {
          this.visitsChartAvailable = true;
        }
        if (data.university_visits.length > 0) {
          this.universityVisitsChartAvailable = true;
        }
        if (data.mean_income.length > 0) {
          this.meanIncomeChartAvailable = true;
        }
        if (data.ticket.length > 0) {
          this.ticketChartAvailable = true;
        }
        if (data.cum_revenue.length > 0) {
          this.cumRevenueChartAvailable = true;
        }

        if (data.refundeds.length > 0) {
          this.refundCompareChartAvailable = true;
        }
        if (data.refundeds_per_paids.length > 0) {
          this.refundPerPaidsCompareChartAvailable = true;
        }
        if (data.bos.length > 0) {
          this.bosCompareChartAvailable = true;
        }
        if (data.bos_per_paids.length > 0) {
          this.bosPerPaidsCompareChartAvailable = true;
        }
      }

      let nameSufix = '';
      if (data.index == 0) {
          this.$refs.velocityCompareChart.setLabels(data.dates);
          this.$refs.visitsUniversityCompareChart.setLabels(data.dates);
          this.$refs.cumRevenueCompareChart.setLabels(data.dates);
          this.$refs.initiatedCompareChart.setLabels(data.orders_dates);
          this.$refs.paidCompareChart.setLabels(data.orders_dates);
          this.$refs.conversionCompareChart.setLabels(data.orders_dates);
          this.$refs.meanIncomeCompareChart.setLabels(data.orders_dates);
          this.$refs.ticketCompareChart.setLabels(data.orders_dates);
          this.$refs.incomeCompareChart.setLabels(data.orders_dates);
          this.$refs.successCompareChart.setLabels(data.orders_dates);
          this.$refs.atractionCompareChart.setLabels(data.orders_dates);
          this.$refs.visitsCompareChart.setLabels(data.orders_dates);
          this.$refs.refundCompareChart.setLabels(data.orders_dates);
          this.$refs.refundPerPaidsCompareChart.setLabels(data.orders_dates);
          this.$refs.bosCompareChart.setLabels(data.orders_dates);
          this.$refs.bosPerPaidsCompareChart.setLabels(data.orders_dates);
          this.$refs.incomeQapCompareChart.setLabels(data.orders_dates);

          nameSufix = this.$refs.currentFilter.baseFiltersCaption();
          if (this.seriesNames.length == 0) {
            this.seriesNames.push(nameSufix);
          } else {
            this.seriesNames[0] = nameSufix;
          }
      } else if (data.index == 1) {
        if (this.comparingMode.type == 'year_to_year') {
          nameSufix = 'Ano Anterior';
        } else {
          nameSufix = this.$refs.comparingFilter.baseFiltersCaption();
        }
        if (this.seriesNames.length == 1) {
          this.seriesNames.push(nameSufix);
        } else {
          this.seriesNames[1] = nameSufix;
        }
      }

      if (this.movelMean) {
        this.chartNameSufix = '- ( janela móvel de 7 dias )';
        this.setSeriesData(data, data.index, nameSufix);
      } else {
        this.chartNameSufix = '';
        this.setSeriesData(data.raw_data, data.index, nameSufix);
      }

      if (data.index === 0) {
        this.setCumRevenueSeries(data, nameSufix);
        if (this.comparingMode.type == 'no_compare') {
          this.updateEnabled = true;
        }
      }

      if (data.index == 1) {
        this.updateEnabled = true;
      }

      this.$nextTick(() => {
        this.updateCharts();
      });
      console.log("receiveChardata# SAIDA");
    },
    updateCharts() {
      _.forEach(this.allCharts, (chart) => {
        chart.updateChart();
      });
    },
    setCumRevenueSeries(data, nameSufix) {
      this.$refs.cumRevenueCompareChart.setSeries(0, data.cum_revenue, "RECEITA ACUMULADA " + nameSufix);
      this.$refs.cumRevenueCompareChart.resetLoader();

      this.$refs.cumRevenueCompareChart.setSeries(1, data.cum_goal, "META ACUMULADA " + nameSufix);
      this.$refs.cumRevenueCompareChart.resetLoader();
    },
    saveCurrentData(data, index) {
      while (this.currentData.length <= index) {
        this.currentData.push([]);
      }
      this.currentData.splice(index, 1, data);
    },
    setSeriesData(data, index, nameSufix) {
      this.saveCurrentData(data, index);

      this.$refs.velocityCompareChart.setSeries(index, data.velocity, "VELOCIMETRO " + nameSufix);
      this.$refs.velocityCompareChart.resetLoader();

      this.$refs.incomeQapCompareChart.setSeries(index, data.income_qap, "RECEITA-QAP " + nameSufix);
      this.$refs.incomeQapCompareChart.resetLoader();

      this.$refs.initiatedCompareChart.setSeries(index, data.initiateds, "ORDENS INICIADAS " + nameSufix);
      this.$refs.initiatedCompareChart.resetLoader();

      this.$refs.paidCompareChart.setSeries(index, data.paids, "ORDENS PAGAS " + nameSufix);
      this.$refs.paidCompareChart.resetLoader();

      this.$refs.conversionCompareChart.setSeries(index, data.conversion_rate, "CONVERSÃO " + nameSufix);
      this.$refs.conversionCompareChart.resetLoader();

      this.$refs.meanIncomeCompareChart.setSeries(index, data.mean_income, "FATURAMENTO/ORDEM " + nameSufix);
      this.$refs.meanIncomeCompareChart.resetLoader();

      this.$refs.ticketCompareChart.setSeries(index, data.ticket, "TICKET MÉDIO " + nameSufix);
      this.$refs.ticketCompareChart.resetLoader();

      this.$refs.incomeCompareChart.setSeries(index, data.income, "RECEITA " + nameSufix);
      this.$refs.incomeCompareChart.resetLoader();

      this.$refs.successCompareChart.setSeries(index, data.success_rate, "TAXA DE SUCESSO " + nameSufix);
      this.$refs.successCompareChart.resetLoader();

      this.$refs.atractionCompareChart.setSeries(index, data.atraction_rate, "TAXA DE ATRATIVIDADE " + nameSufix);
      this.$refs.atractionCompareChart.resetLoader();

      this.$refs.visitsCompareChart.setSeries(index, data.visits, "VISITAS " + nameSufix);
      this.$refs.visitsCompareChart.resetLoader();

      this.$refs.visitsUniversityCompareChart.setSeries(index, data.university_visits, "VISITAS UNIVERSIDADE " + nameSufix);
      this.$refs.visitsUniversityCompareChart.resetLoader();

      this.$refs.refundCompareChart.setSeries(index, data.refundeds, "REEMBOLSOS " + nameSufix);
      this.$refs.refundCompareChart.resetLoader();

      this.$refs.refundPerPaidsCompareChart.setSeries(index, data.refundeds_per_paids, "REEMBOLSOS POR PAGOS " + nameSufix);
      this.$refs.refundPerPaidsCompareChart.resetLoader();


      this.$refs.bosCompareChart.setSeries(index, data.bos, "BO's " + nameSufix);
      this.$refs.bosCompareChart.resetLoader();

      this.$refs.bosPerPaidsCompareChart.setSeries(index, data.bos_per_paids, "BO's POR PAGOS " + nameSufix);
      this.$refs.bosPerPaidsCompareChart.resetLoader();

    },
    receiveTableData(data) {
      this.tableLoading = false;
      console.log("receiveTableData# index: " + data.index + " position: " + data.position);
      while (this.seriesMetrics.length <= data.index) {
        this.seriesMetrics.push([]);
      }
      let currentSeries = this.seriesMetrics[data.index];
      while (currentSeries.length <= data.position) {
        currentSeries.push({name: '-', serie: [], base_serie: []});
      }

      if (this.comparingMode.type == 'all_data') {
        data.serie.splice(3, 0, '-');
        data.serie.splice(3, 0, '-');
        data.serie.splice(3, 0, '-');
      }

      currentSeries.splice(data.position, 1, data);

      if (this.comparingMode.type == 'all_data') {
        let otherIndex = 1 - data.index;
        if (this.seriesMetrics.length > otherIndex) {
          //pode dividir o 0 pelo 1
          let ordersShare = this.seriesMetrics[0][data.position].base_serie[3] / this.seriesMetrics[1][data.position].base_serie[3];
          let paidsShare = this.seriesMetrics[0][data.position].base_serie[4] / this.seriesMetrics[1][data.position].base_serie[4];
          let visitsShare = this.seriesMetrics[0][data.position].base_serie[6] / this.seriesMetrics[1][data.position].base_serie[6];

          this.seriesMetrics[0][data.position].serie[3] = `${(ordersShare * 100).toFixed(2)} %`;
          this.seriesMetrics[0][data.position].serie[4] = `${(paidsShare * 100).toFixed(2)} %`;
          this.seriesMetrics[0][data.position].serie[5] = `${(visitsShare * 100).toFixed(2)} %`;
        }
      }
    }
  },
}
</script>
