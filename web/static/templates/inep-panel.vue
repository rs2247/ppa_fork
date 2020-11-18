<template>
  <div class="container-fluid">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel do INEP ( Somente Graduação )
        </h2>
      </div>
    </div>

    <div class="panel report-panel panel-default">
      <div class="row">
        <ul class="nav navbar-nav justify-content-center">
          <li class="navbar__item" :class="{'active' : showInepStockActive}">
            <a class="nav-link clickable" @click="showInepStock">Estoque</a>
          </li>
          <li class="navbar__item" :class="{'active' : showInepEntrantsActive}">
            <a class="nav-link clickable" @click="showInepEntrants">Ingressantes</a>
          </li>
        </ul>
      </div>
    </div>

    <div v-show="showInepEntrantsActive">
      <div class="panel report-panel panel-default">
        <div class="row" style="position: relative;">
          <div class="transparent-loader" v-if="loadingFilters || loading">
            <div class="loader"></div>
          </div>

          <div class="col-md-12 col-sm-6">
            <div class="row">
              <div class="col-md-6 col-sm-6">
                <label for="kind-filter">UNIVERSIDADE</label>
                <cs-multiselect v-model="filterUniversity" :options="universityOptions" label="name" track-by="id" placeholder="Selecione a universidade" selectLabel="" deselectLabel=""></cs-multiselect>
              </div>
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="kind-filter">ESTADO</label>
                  <cs-multiselect v-model="filterState" :options="statesOptions" label="name" track-by="type" placeholder="Todos os estados" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="kind-filter">AGRUPAMENTO</label>
                  <cs-multiselect v-model="grouping" :options="groupingOptions" label="name" track-by="key" placeholder="Sem agrupamento" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadEntrantsData">
                    Atualizar
                  </button>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>

      <div class="row" v-if="hasEntrantsData">
        <div class="col-md-12">
          <div class="panel report-panel">
            <div class="panel-body no-lat-padding">
              <table id="inep-entrants" class="data-table sticky-header">
                <thead>
                  <tr>
                    <th>Ano</th>
                    <th>Ingressantes</th>
                    <th v-if="tableGroupingFieldName">{{ tableGroupingFieldTitle }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.ano_ingresso }}</td>
                    <td>{{ entry.quantidade }}</td>
                    <td v-if="tableGroupingFieldName">{{ entry[tableGroupingFieldName] }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-show="showInepStockActive">
      <div class="panel report-panel panel-default">
        <div class="row" style="position: relative;">
          <div class="transparent-loader" v-if="loadingFilters || loading">
            <div class="loader"></div>
          </div>

          <div class="col-md-12 col-sm-6">
            <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" :deal-owner-options="dealOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
          </div>


          <div class="col-md-2 col-sm-6">
            <div class="row">
              <div class="col-md-12 col-sm-12 ">
                <label for="kind-filter">MODALIDADE</label>
                <div class="tiny-margin-left">
                  <input type="radio" id="20_top_clean" name="kind" value="1" checked v-model="kindFilter">
                  <label for="20_top_clean">
                    <span style="font-size: 18px;" class="tiny-padding-left">Presencial</span>
                  </label>
                  <input type="radio" id="all" name="kind" value="3" style="margin-left: 10px;" v-model="kindFilter">
                  <label for="all">
                    <span style="font-size: 18px;" class="tiny-padding-left">EaD</span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          <location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" @cityLocationSelected="loadCities" @locationValueSelected="locationSelected" @locationTypeRemoved="locationRemoved"></location-filter>

          <div class="col-md-12 col-sm-6">
            <div class="row">
              <div class="col-md-4 col-sm-12">
                <label for="kind-filter">CURSOS</label>
                <div class="tiny-margin-left">
                  <!-- div class="col-md-12 col-sm-12 tiny-margin-left" -->
                    <input type="radio" id="20_top_clean" name="canonicals_filter" value="20_top_clean" checked v-model="filterCanonicals">
                    <label for="20_top_clean">
                      <span style="font-size: 18px;" class="tiny-padding-left">
                        TOP 20 EM VENDAS
                        <span class="glyphicon glyphicon-info-sign tooltip__icon">
                          <div class="tooltip__content">
                            <span>
                                <p>O curso canônico mãe do SKU está entre os mais vendidos</p>
                            </span>
                          </div>
                        </span>
                      </span>
                    </label>
                    <input type="radio" id="all" name="canonicals_filter" value="all" style="margin-left: 10px;" v-model="filterCanonicals">
                    <label for="all">
                      <span style="font-size: 18px;" class="tiny-padding-left">TODOS</span>
                    </label>
                  <!-- /div -->
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>


      <div class="panel report-panel panel-default" v-show="dataInitialized || hasChartsData">
        <div class="row">
          <ul class="nav navbar-nav justify-content-center">
            <li class="navbar__item" :class="{'active' : showCoveragePanel}">
              <a class="nav-link clickable" @click="showCoverage">Cobertura</a>
            </li>
            <li class="navbar__item" :class="{'active' : showStatesPanel}">
              <div class="transparent-loader" v-if="statesTableLoading">
                <div class="loader loader-small"></div>
              </div>
              <a class="nav-link clickable" @click="showStates">Estados</a>
            </li>
            <li class="navbar__item" :class="{'active' : showIESPanel}">
              <div class="transparent-loader" v-if="iesTableLoading">
                <div class="loader loader-small"></div>
              </div>
              <a class="nav-link clickable" @click="showIES">IESs</a>
            </li>
            <!-- li class="navbar__item" :class="{'active' : showLocationTable}" v-show="hasLocationData">
              <a class="nav-link clickable" @click="showLocation">Praças</a>
            </li -->
            <li class="navbar__item" :class="{'active' : showMissingPanel}" v-show="hasMissingData || missingTableLoading">
              <div class="transparent-loader" v-if="missingTableLoading">
                <div class="loader loader-small"></div>
              </div>
              <a class="nav-link clickable" @click="showMissing">Estoque faltando</a>
            </li>
          </ul>
        </div>

        <div class="row" style="position: relative;">


          <div class="col-md-12" v-show="showMissingPanel">
            <div class="row">
              <div class="col-md-12" v-if="hasMissingData">
                <table id="inep-missing" class="data-table">
                  <thead>
                    <tr>
                      <th>IES</th>
                      <th>Cidade</th>
                      <th>Estado</th>
                      <th>Curso</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="course in missingStock">
                      <td>{{ course.no_ies }}</td>
                      <td>{{ course.cidade }}</td>
                      <td>{{ course.estado }}</td>
                      <td>{{ course.curso }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="col-md-12" v-show="showStatesPanel">
            <div class="row">
              <div class="col-md-12" v-if="hasStatesTable">
                <table id="inep-states-table" class="data-table" >
                  <thead>
                    <tr>
                      <th>Estado</th>
                      <th>Base de Alunos INEP [2018]</th>
                      <th>Share Anual QB {{baseYear}} / INEP [2018]</th>
                      <th>Share Anual QB {{previousYear}} / INEP [2018]</th>
                      <th>SKUs data base {{ previousSemester }} / SKUs INEP 18 <br>(% da base de alunos)</th>
                      <th>SKUs data base {{ previousYearSemester }} / SKUs INEP 18 <br>(% da base de alunos)</th>
                      <th>SKUs Online / SKUs INEP 18 <br>(% da base de alunos)</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="entry in statesTable">
                      <td>{{ entry.state }}</td>
                      <td>{{ entry.inep_students }}</td>
                      <td>{{ entry.share_sem_2 }}</td>
                      <td>{{ entry.share_sem_1 }}</td>
                      <td>{{ entry.coverage_percent_previous_semester }}</td>
                      <td>{{ entry.coverage_percent_previous_year }}</td>
                      <td>{{ entry.coverage_percent }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="col-md-12" v-show="showIESPanel">
            <div class="row">
              <div class="col-md-12" v-if="hasIESTable">
                <table id="inep-ies-table" class="data-table">
                  <thead>
                    <tr>
                      <th>IES ID</th>
                      <th>IES</th>
                      <th>Farmer</th>
                      <th>Base de Alunos INEP [2018]</th>
                      <th>Share Anual QB {{baseYear}} / INEP [2018]</th>
                      <th>Share Anual QB {{previousYear}} / INEP [2018]</th>
                      <th>SKUs data base {{ previousSemester }} / SKUs INEP 18 <br>(% da base de alunos)</th>
                      <th>SKUs data base {{ previousYearSemester }} / SKUs INEP 18 <br>(% da base de alunos)</th>
                      <th>SKUs Online / SKUs INEP 18 <br>(% da base de alunos)</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="entry in iesTable">
                      <td>{{ entry.university_id }}</td>
                      <td>{{ entry.university_name }}</td>
                      <td>{{ entry.owner }}</td>
                      <td>{{ entry.inep_students }}</td>
                      <td>{{ entry.share_sem_2 }}</td>
                      <td>{{ entry.share_sem_1 }}</td>
                      <td>{{ entry.coverage_percent_previous_semester }}</td>
                      <td>{{ entry.coverage_percent_previous_year }}</td>
                      <td>{{ entry.coverage_percent }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="col-md-12" v-show="showMissingPanel">

          </div>

          <div class="col-md-12" v-show="showCoveragePanel">
            <div class="row">
              <div class="col-md-3 default-margin-top">
                <label>PERÍODO BASE</label>
                <c-date-picker :shortcuts="shortcuts" v-model="dateRange" :not-after="lastDate" :not-before="initialDate"></c-date-picker>
              </div>
            </div>
            <div class="row">
              <div class="transparent-loader" v-if="loadingCharts">
                <div class="loader"></div>
              </div>

              <div class="col-md-12" v-show="showCoverageChart">
                <div class="row">
                  <div class="col-md-12">
                    <h2>COBERTURA DA BASE DE ALUNOS DO INEP PELO ESTOQUE DO QB</h2>
                  </div>
                </div>

                <!-- div class="chartClass" -->
                  <div class="panel report-panel panel-default">
                    <div class="panel-heading panel-heading--spaced-bottom">Cobertura do INEP (% da base de alunos cobertos)</div>
                    <comparing-chart ref="coverageChart" export-name="cobertura_inep"></comparing-chart>
                  </div>
                <!-- /div -->
              </div>

              <div class="col-md-12" v-show="showStatesCoverageChart">
                <div class="row">
                  <div class="col-md-12">
                    <h2>COBERTURA POR ESTADO - (% da base de alunos cobertos)</h2>
                  </div>
                </div>

                <div class="transparent-loader" v-if="loadingStatesData">
                  <div class="loader"></div>
                </div>

                <div class="row">
                  <div class="col-md-3">
                    <label>NÚMERO DE ESTADOS</label>
                    <multiselect v-model="nStatesSeries" :options="seriesOptions" label="name" placeholder="Selecione o número de estados" selectLabel="" deselectLabel="" selectedLabel=""></multiselect>
                  </div>

                  <div class="col-md-3">
                    <label>ORDENAÇÃO</label>
                    <multiselect v-model="statesOrdering" :options="statesOrderingOptions" label="name" placeholder="Selecione o método de ordenação" selectLabel="" deselectLabel="" selectedLabel=""></multiselect>
                  </div>
                </div>

                <div class="row">
                  <div class="col-md-6">
                    <div class="panel report-panel panel-default">
                      <div class="panel-heading panel-heading--spaced-bottom">ANO ANTERIOR</div>
                      <comparing-chart ref="previousStatesCoverageChart" export-name="cobertura_estados_inep"></comparing-chart>
                    </div>
                  </div>
                  <div class="col-md-6">
                    <div class="panel report-panel panel-default">
                      <div class="panel-heading panel-heading--spaced-bottom">SEMESTRE ATUAL</div>
                      <comparing-chart ref="statesCoverageChart" export-name="cobertura_estados_inep"></comparing-chart>
                    </div>
                  </div>
                </div>
              </div>


              <div class="col-md-12" v-show="showIesCoverageChart">
                <div class="row">
                  <div class="col-md-12">
                    <h2>COBERTURA POR IES - (% da base de alunos cobertos)</h2>
                  </div>
                </div>

                <div class="transparent-loader" v-if="loadingIesData">
                  <div class="loader"></div>
                </div>

                <div class="row">
                  <div class="col-md-3">
                    <label>NÚMERO DE IES</label>
                    <multiselect v-model="nIesSeries" :options="iesSeriesOptions" label="name" placeholder="Selecione o número de IES" selectLabel="" deselectLabel="" selectedLabel=""></multiselect>
                  </div>

                  <div class="col-md-3">
                    <label>ORDENAÇÃO</label>
                    <multiselect v-model="iesOrdering" :options="statesOrderingOptions" label="name" placeholder="Selecione o método de ordenação" selectLabel="" deselectLabel="" selectedLabel=""></multiselect>
                  </div>
                </div>


                <div class="panel report-panel panel-default">
                  <div class="panel-heading panel-heading--spaced-bottom">SEMESTRE ATUAL</div>
                  <comparing-chart ref="iesCoverageChart" export-name="cobertura_ies_inep"></comparing-chart>
                </div>

              </div>
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
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import CDatePicker from './custom-date-picker'
import ModalDialog from './modal-dialog'
import MessageDialog from "../js/components/message-dialog";
import LocationFilter from './location-filter';
import ComparingChart from './comparing-chart'

export default {
  data() {
    return {
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      locationOptions: [
        { name: 'Região', type: 'region'},
        { name: 'Estado', type: 'state'},
        { name: 'Cidade', type: 'city'},
      ],

      citiesOptions: [],
      statesOptions: [],
      regionsOptions: [],

      dateRange: null,
      filterUniversities: null,
      filterGroups: null,
      kindFilter: 1,
      //hasData: false,
      //hasData: true,
      hasChartsData: false,

      showCoveragePanel: true,
      showMissingPanel: false,
      showStatesPanel: false,
      showIESPanel: false,
      hasMissingData: false,
      hasStatesTable: false,
      hasIESTable: false,
      iesTableLoading: true,
      statesTableLoading: true,
      missingTableLoading: true,

      showCoverageChart: true,
      showStatesCoverageChart: false,
      showIesCoverageChart: false,
      loadingStatesData: false,
      loadingIesData: false,
      loadingCharts: false,

      filterCanonicals: '20_top_clean',
      initialDate: null,
      lastDate: null,

      baseYear: null,
      previousYear: null,

      showInepEntrantsActive: false,
      showInepStockActive: true,

      shortcuts: [
        {
          text: '<< 6 m',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).subtract(6, 'months').toDate(), moment(this.semesterEnd).subtract(6, 'months') ]
          }
        },
        {
          text: 'Semestre',
          onClick: () => {
            this.dateRange = [ this.semesterStart, this.semesterEnd ]
          }
        },
        {
          text: 'Últimos 30',
          onClick: () => {
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            this.dateRange = [ moment().subtract(7, 'days').toDate(), new Date() ]
          }
        },
        {
          text: '<< 7 d',
          onClick: () => {
            this.dateRange = [ moment(this.dateRange[0]).subtract(7, 'days').toDate(), this.dateRange[0] ]
          }
        },
        {
          text: 'Até hoje',
          onClick: () => {
            this.dateRange = [ this.dateRange[0], moment().toDate() ]
          }
        }
      ],

      //tableData: [],
      tableStates: null,
      tableIES: null,
      tableMissing: null,

      loading: false,
      loadingFilters: true,

      semesterEnd: null,
      semesterStart: null,

      currentType: null,
      currentValue: null,
      statesTable: [],
      iesTable: [],
      missingStock: [],
      previousSemester: null,
      previousYearSemester: null,

      coverageChartLoaded: false,
      iesChartLoaded: false,
      statesChartLoaded: false,

      chartsDates: [],

      statesKeys: null,
      statesMap: null,
      statesMapPrevious: null,

      iesKeys: null,
      iesKeysNames: null,
      iesMap: null,

      nStatesSeries: null,
      seriesOptions: [{name: "5", id: 5}, {name: "10", id: 10}, {name: "Todos", id: "all"}],
      statesOrdering: null,
      statesOrderingOptions: [
        {name: "Maior número de alunos", key: "students"},
        {name: "Menor cobertura", key: "coverage"},
      ],
      nIesSeries: null,
      iesSeriesOptions: [{name: "5", id: 5}, {name: "10", id: 10}, {name: "Máximo", id: 20}],
      iesOrdering: null,
      dataInitialized: false,

      showInepStockActive: true,
      showInepEntrantsActive: false,

      filterUniversity: null,
      //universityOptions: [],
      //stateOptions: [],
      filterState: null,
      //loadingFilters: true,
      //loading: false,
      tableData: [],
      tableGroupingFieldTitle: null,
      tableGroupingFieldName: null,
      grouping: null,
      groupingOptions: [
        {name: 'Modalidade', key: 'kind'},
        {name: 'Estado', key: 'state'},
      ]

    }
  },
  watch: {
    kindFilter: function(value) {
      if (!_.isNil(this.currentType)) {
        this.loadData(this.currentType, this.currentValue);
      }
    },
    filterCanonicals: function(value) {
      if (!_.isNil(this.currentType)) {
        this.loadData(this.currentType, this.currentValue);
      }
    },
    dateRange: function(value) {
      if (!_.isNil(this.currentType)) {
        this.loadChartData(this.currentType, this.currentValue);
      }
    },
    nStatesSeries: function(value) {
      console.log("nStatesSeries");
      if (this.hasChartsData) {
        this.$refs.statesCoverageChart.clearSeries();
        this.$refs.previousStatesCoverageChart.clearSeries();
        this.setStatesCharts();
        this.updateCharts();
      }
    },
    statesOrdering: function(value) {
      console.log("statesOrdering");
      if (this.hasChartsData) {
        this.loadStatesChart();
      }
    },
    nIesSeries: function(value) {
      console.log("nIesSeries");
      if (this.hasChartsData) {
        this.$refs.iesCoverageChart.clearSeries();
        this.setIesCharts();
        this.updateCharts();
      }
    },
    iesOrdering: function(value) {
      console.log("iesOrdering");
      if (this.hasChartsData) {
        this.loadIesChart();
      }
    },
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    CDatePicker,
    ModalDialog,
    LocationFilter,
    ComparingChart,
  },
  computed: {
    hasEntrantsData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    InepPanelChannel.on('filters', (payload) => this.receiveFilters(payload));
    InepPanelChannel.on('citiesFilter', (payload) => this.receiveCitiesFilter(payload));

    InepPanelChannel.on('tableData', (payload) => this.receiveTableData(payload));
    InepPanelChannel.on('iesTableData', (payload) => this.receiveIesTableData(payload));
    InepPanelChannel.on('statesTableData', (payload) => this.receiveStatesTableData(payload));
    InepPanelChannel.on('missingStock', (payload) => this.receiveMissingStock(payload));

    InepPanelChannel.on('coverageChartData', (payload) => this.receiveCoverageChartData(payload));
    InepPanelChannel.on('statesChartData', (payload) => this.receiveStatesChartData(payload));
    InepPanelChannel.on('iesChartData', (payload) => this.receiveIesChartData(payload));

    InepPanelChannel.on('inepEntrants', (payload) => this.receiveEntrantsTableData(payload));

    this.nIesSeries = this.iesSeriesOptions[0];
    this.nStatesSeries = this.seriesOptions[0];
    this.statesOrdering = this.statesOrderingOptions[0];
    this.iesOrdering = this.statesOrderingOptions[0];

    this.loadFilters();
  },
  methods: {
    showInepStock() {
      this.showInepStockActive = true;
      this.showInepEntrantsActive = false;
    },
    showInepEntrants() {
      this.showInepStockActive = false;
      this.showInepEntrantsActive = true;
    },
    hideAll() {
      this.showCoveragePanel = false;
      this.showMissingPanel = false;
      this.showStatesPanel = false;
      this.showIESPanel = false;
    },
    showStates() {
      this.hideAll();
      this.showStatesPanel = true;
    },
    showIES() {
      this.hideAll();
      this.showIESPanel = true;
    },
    showCoverage() {
      this.hideAll();
      this.showCoveragePanel = true;

      this.$nextTick(() => {
        this.$refs.coverageChart.updateChart();
        this.$refs.statesCoverageChart.updateChart();
        this.$refs.previousStatesCoverageChart.updateChart();
        this.$refs.iesCoverageChart.updateChart();
      });
    },
    showMissing() {
      this.hideAll();
      this.showMissingPanel = true;
    },
    loadCities(data) {
      console.log('loadCities');
      this.$refs.locationFilter.setCitiesLoader(true);
      this.completeCities(this.currentType, this.currentValue);
    },
    locationSelected(data) {
      console.log('locationSelected');
      if (!_.isNil(this.currentType)) {
        this.loadData(this.currentType, this.currentValue);
      }
    },
    locationRemoved(data) {
      this.$nextTick(() => {
        console.log('locationRemoved' + JSON.stringify(this.$refs.locationFilter.locationValue()));
        this.loadData(this.currentType, this.currentValue);
      });
    },
    primaryFilterSelected(data) {
      let filterData = this.$refs.filter.filterSelected();
      if ((!_.isNil(filterData.value) && filterData.value != '') || (filterData.type == 'all')) {
        this.loadData(filterData.type, filterData.value)
      } else {
        this.data = [];
      }
    },
    receiveMissingStock(data) {
      //console.log('receiveMissingStock data: ' + JSON.stringify(data));
      this.missingStock = data.courses;
      if (this.missingStock.length > 0) {
        this.hasMissingData = true;

        this.$nextTick(() => {
          this.tableMissing = new DataTable('#inep-missing', {
            paging: true,
            deferRender: true,
            searchDelay: 500,
            pageLength: 30,
            order: [ 2, 'desc' ],
          });

          this.missingTableLoading = false;
        });
      } else {
        this.missingTableLoading = false;
      }

      this.verifyLoadingState();
    },
    receiveCitiesFilter(data) {
      this.citiesOptions = data.cities;
      this.$refs.locationFilter.setCitiesLoader(false);
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.universityGroupOptions = data.groups;
      this.filterOptions = data.filters;
      this.semesterStart = data.semester_start;
      this.semesterEnd = data.semester_end;
      this.statesOptions = data.states;
      this.regionsOptions = data.regions;

      this.accountTypeOptions = data.account_types;
      this.dealOwnerOptions = data.deal_owners;

      this.initialDate = moment(this.semesterStart).toDate();
      this.lastDate = moment(this.semesterEnd).toDate();

      this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];

      this.loadingFilters = false;
    },
    receiveIesTableData(data) {
      this.iesTable = data.ies_table;
      this.hasIESTable = true;

      this.$nextTick(() => {
        this.tableIES = new DataTable('#inep-ies-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
          order: [ 3, 'desc' ],
        });

        this.iesTableLoading = false;
      });

      this.verifyLoadingState();
    },
    receiveStatesTableData(data) {
      this.statesTable = data.states_table;
      this.hasStatesTable = true;

      this.$nextTick(() => {
        this.tableStates = new DataTable('#inep-states-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
          order: [ 1, 'desc' ],
        });

        this.statesTableLoading = false;
      });

      this.verifyLoadingState();
    },
    receiveTableData(data) {
      this.baseYear = data.base_year;
      this.previousYear = data.previous_year;

      this.previousSemester = data.previous_semester;
      this.previousYearSemester = data.previous_year_semester;

    },
    receiveCoverageChartData(data) {
      console.log("receiveCoverageChartData");
      this.chartsDates = data.dates;
      this.currentPoint = data.current_point;

      this.$refs.coverageChart.setLabels(data.dates);
      this.$refs.coverageChart.setSeries(0, data.sem2, data.sem2_name);
      this.$refs.coverageChart.setSeries(1, data.sem1, data.sem1_name);
      this.$refs.coverageChart.setSeries(2, data.sem, data.sem_name);

      if (!_.isNil(this.currentPoint)) {
        this.$refs.coverageChart.setCurrentPoint(this.currentPoint);
      }

      this.coverageChartLoaded = true;

      this.verifyChartsReady();

      this.verifyLoadingState();
    },
    receiveStatesChartData(data) {
      console.log("receiveStatesChartData");

      if (data.has_states_data) {
        this.statesKeys = data.states_keys;
        this.statesMap = data.states_map;
        this.statesMapPrevious = data.states_map_previous;

        if (!_.isEmpty(this.chartsDates)) {
          this.setStatesCharts();
        }
      }

      this.statesChartLoaded = true;

      this.verifyChartsReady();

      this.loadingStatesData = false;

      this.verifyLoadingState();
    },
    setStatesCharts() {
      if (_.isNil(this.statesKeys)) {
        return;
      }
      this.showStatesCoverageChart = true;
      this.$refs.statesCoverageChart.setLabels(this.chartsDates);
      let index = 0;
      _.forEach(this.statesKeys, (key) => {
        if (this.nStatesSeries.id != 'all') {
          if (index >= this.nStatesSeries.id) {
            return;
          }
        }
        this.$refs.statesCoverageChart.setSeries(index, this.statesMap[key], key);
        index = index + 1;
      });

      if (!_.isNil(this.currentPoint)) {
        this.$refs.statesCoverageChart.setCurrentPoint(this.currentPoint);
      }

      index = 0;
      this.$refs.previousStatesCoverageChart.setLabels(this.chartsDates);
      _.forEach(this.statesKeys, (key) => {
        if (this.nStatesSeries.id != 'all') {
          if (index >= this.nStatesSeries.id) {
            return;
          }
        }
        this.$refs.previousStatesCoverageChart.setSeries(index, this.statesMapPrevious[key], key);
        index = index + 1;
      });
    },
    receiveIesChartData(data) {
      if (data.has_ies_data) {

        this.iesKeys = data.ies_keys;
        this.iesKeysNames = data.ies_keys_names;
        this.iesMap = data.ies_map;

        if (!_.isEmpty(this.chartsDates)) {
          this.setIesCharts();
        }
      }

      this.iesChartLoaded = true;
      this.verifyChartsReady();
      this.loadingIesData = false;

      this.verifyLoadingState();
    },
    setIesCharts() {
      if (_.isNil(this.iesKeys)) {
        return;
      }
      this.showIesCoverageChart = true;

      this.$refs.iesCoverageChart.setLabels(this.chartsDates);
      let index = 0;
      _.forEach(this.iesKeys, (key) => {
        if (index >= this.nIesSeries.id) {
          return;
        }
        this.$refs.iesCoverageChart.setSeries(index, this.iesMap[key], this.iesKeysNames[index]);
        index = index + 1;
      });

      if (!_.isNil(this.currentPoint)) {
        this.$refs.iesCoverageChart.setCurrentPoint(this.currentPoint);
      }

    },
    completeCities() {
      let params = this.filterParams();
      InepPanelChannel.push('completeCities', params).receive('timeout', (data) => {
        console.log('complete timeout');
      });
    },
    filterParams() {
      let params = { type: this.currentType, value: this.currentValue, kind_id: this.kindFilter, canonicals: this.filterCanonicals }
      if (this.$refs.locationFilter.locationValue()) {
        params.locationType = this.$refs.locationFilter.locationFilter();
        params.locationValue = this.$refs.locationFilter.locationValue();
      }
      return params;
    },
    loadFilters() {
      InepPanelChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadChartData(type, value) {
      this.loadingCharts = true;
      this.executeLoadData(type, value, 'loadChartData');
    },
    loadData(type, value) {
      this.loading = true;
      this.dataInitialized = false;
      this.hideAll();
      this.showCoveragePanel = true;

      this.hasMissingData = false;
      this.hasStatesTable = false;
      this.hasIESTable = false;

      this.iesTableLoading = true;
      this.statesTableLoading = true;
      this.missingTableLoading = true;

      this.executeLoadData(type, value, 'loadData');
    },
    loadIesChart() {
      console.log("loadIesChart");

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      this.loadingIesData = true;

      let params = this.filterParams();
      params.initialDate = initialDate;
      params.finalDate = finalDate;
      params.iesOrdering = this.iesOrdering.key

      InepPanelChannel.push('loadIesChartData', params).receive('timeout', (data) => {
        console.log('loadIesChartData timeout');
      });
    },
    loadStatesChart() {
      console.log("loadStatesChart");

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      this.loadingStatesData = true;

      let params = this.filterParams();
      params.initialDate = initialDate;
      params.finalDate = finalDate;
      params.statesOrdering = this.statesOrdering.key;

      InepPanelChannel.push('loadStatesChartData', params).receive('timeout', (data) => {
        console.log('loadStatesChartData timeout');
      });
    },
    verifyLoadingState() {
      this.loading = ! this.hasIESTable || ! this.coverageChartLoaded || !this.hasStatesTable || ( this.missingTableLoading && !this.hasMissingData );
    },
    verifyChartsReady() {
      this.hasChartsData = this.coverageChartLoaded && this.iesChartLoaded && this.statesChartLoaded;
      if (this.hasChartsData) {
        this.loadingCharts = false;
        this.updateCharts();
        if (!this.dataInitialized) {
          this.dataInitialized = true;
        }
      }
    },
    updateCharts() {
      this.$nextTick(() => {
        this.$refs.coverageChart.updateChart();
        this.$refs.statesCoverageChart.updateChart();
        this.$refs.iesCoverageChart.updateChart();
        this.$refs.previousStatesCoverageChart.updateChart();
      });
    },
    executeLoadData(type, value, action) {
      this.currentType = type;
      this.currentValue = value;

      this.coverageChartLoaded = false;
      this.iesChartLoaded = false;
      this.statesChartLoaded = false;

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      let params = this.filterParams();
      params.initialDate = initialDate;
      params.finalDate = finalDate;
      params.statesOrdering = this.statesOrdering.key
      params.iesOrdering = this.iesOrdering.key

      this.$refs.coverageChart.clearSeries();
      this.$refs.statesCoverageChart.clearSeries();
      this.$refs.iesCoverageChart.clearSeries();
      this.$refs.previousStatesCoverageChart.clearSeries();

      this.showStatesCoverageChart = false;
      this.showIesCoverageChart = false;

      InepPanelChannel.push(action, params).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
    receiveEntrantsTableData(data) {
      this.tableData = data.entrants;
      this.tableGroupingFieldTitle = data.grouping_field_title;
      this.tableGroupingFieldName = data.grouping_field_name;
      this.loading = false;
      this.$nextTick(() => {
        this.table = new DataTable('#inep-entrants', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 0, 'asc' ]
        });
      });
    },
    loadEntrantsData() {
      this.loading = true;
      this.tableData = [];
      let filters = {
        university_id: this.filterUniversity.id,

      };
      if (!_.isNil(this.filterState)) {
          filters.state = this.filterState.type;
      }
      if (!_.isNil(this.grouping)) {
        filters.grouping = this.grouping.key;
      }
      InepPanelChannel.push('loadEntrants', filters).receive('timeout', () => {
        console.log("load timeout");
      });
    },
  },
};

</script>
