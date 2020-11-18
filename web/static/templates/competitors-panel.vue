<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Fluxo de Concorrência
        </h2>
      </div>
    </div>

    <div class="row" style="position: relative; ">
      <div class="transparent-loader" v-if="loadingFilters || loadingCompetitorsData">
        <div class="loader"></div>
      </div>
      <div class="col-md-12">

        <div class="row" >

          <div class="col-md-3 col-sm-6">
            <div class="">
              <label for="date">PERÍODO</label>
              <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
            </div>
          </div>

          <div class="col-md-4 col-sm-6">
            <label>UNIVERSIDADE</label>
            <cs-multiselect v-model="universityFilter" :options="universityOptions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="universitySelected" @remove="universityRemoved"></cs-multiselect>
          </div>

          <div class="col-md-3 col-sm-3">
            <div class="default-margin-top">
              <input type="checkbox" v-model="onlyQp" style="margin-right: 5px;" checked><label>APENAS CONCORRENTES QUERO PAGO</label>
            </div>
          </div>
        </div>

        <div class="row" >
          <div class="col-md-2 col-sm-6">
            <div>
              <label for="kind-filter">MODALIDADE</label>
              <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel="" @select="kindSelected" @remove="kindRemoved"></multiselect>
            </div>
          </div>
          <div class="col-md-2 col-sm-6">
            <div>
              <label for="level-filter">NÍVEL</label>
              <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @select="levelSelected" @remove="levelRemoved"></multiselect>
            </div>
          </div>
          <div class="col-md-2 col-sm-6">
            <div class="transparent-loader" v-if="stateFilterLoading">
              <div class="loader"></div>
            </div>
            <div>
              <label for="level-filter">ESTADO</label>
              <cs-multiselect v-model="filterState" :options="stateOptions" :multiple="true" label="name" track-by="type" placeholder="Todos os estados" selectLabel="" deselectLabel="" @select="stateSelected" @remove="stateRemoved"></cs-multiselect>
            </div>
          </div>
          <div class="col-md-2 col-sm-6">
            <div class="transparent-loader" v-if="cityFilterLoading">
              <div class="loader"></div>
            </div>
            <div>
              <label for="level-filter">CIDADE</label>
              <multiselect v-model="filterCity" :options="cityOptions" :multiple="true" label="name" track-by="name" placeholder="Todas as cidades" selectLabel="" deselectLabel=""></multiselect>
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

    <div class="row" style="position: relative;" v-if="showTables">
      <div class="col-md-4 col-sm-12 default-margin-top">
        <label>VISUALIZAÇÃO</label>
        <div style="margin-left: 10px;">
          <input type="radio" name="kind" value="percent" v-model="visualizationType">
          <span style="font-size: 16px;" class="tiny-padding-left">Percentual</span>
          <input type="radio" name="kind" value="number" style="margin-left: 10px;" checked v-model="visualizationType">
          <span style="font-size: 16px;" class="tiny-padding-left">Número de alunos</span>
        </div>
      </div>
    </div>

    <div class="row" v-show="showTables">
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            ALUNOS PERDIDOS
            <template v-if="visualizationType == 'percent'">
              ( % de
            </template>
            <template v-else>
              ( número de
            </template>
              alunos que se interessou por {{ universityName }} mas comprou outra IES )
          </div>

          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-12">

                <base-chart :base-height="600" ref="loseChart" :export-name="'alunos_perdidos_' + universityName"></base-chart>
              </div>
            </div>
          </div>
        </div>
      </div>


      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            CONCORRÊNCIA
          </div>

          <div class="row">
            <div class="transparent-loader" v-if="loadingCompetitorsData">
              <div class="loader"></div>
            </div>

            <div class="col-md-12" v-if="showTables">
              <div class="panel-body no-lat-padding">
                <table id="competitors-report-table" class="data-table">
                  <thead>
                    <tr>
                      <th>ID (Universidade)</th>
                      <th>Universidade</th>
                      <th>
                        <span v-if="visualizationType == 'percent'">%</span> Perdidos
                        <span class="glyphicon glyphicon-info-sign tooltip__icon">
                          <div class="tooltip__content">
                            <span>
                              <template v-if="visualizationType == 'percent'">Percentual dos </template>
                              <template v-else>Número de </template>
                              alunos que <br>teve interesse em {{ currentUniversityName }} <br>e comprou outra IES
                            </span>
                          </div>
                        </span>
                      </th>
                      <th>
                        <span v-if="visualizationType == 'percent'">%</span> Ganhos
                        <span class="glyphicon glyphicon-info-sign tooltip__icon">
                          <div class="tooltip__content">
                            <span>
                              <template v-if="visualizationType == 'percent'">Percentual dos </template>
                              <template v-else>Número de </template>
                              alunos que <br>comprou {{ currentUniversityName }} <br>e teve interesse em outras IES
                            </span>
                          </div>
                        </span>
                      </th>
                      <th v-show="numberView">
                        Diferença
                      </th>
                    </tr>
                  </thead>
                  <tbody id="table-body">
                    <tr v-for="entry in competitorsTable">
                      <td>{{ entry.id_ies_compra }}</td>
                      <td>{{ entry.ies_compra }}</td>
                      <td>{{ entry.n_users }}</td>
                      <td>{{ entry.win }}</td>
                      <td v-show="numberView">{{ entry.win - entry.n_users }}</td>
                    </tr>
                  </tbody>
                </table>
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
import Multiselect from 'vue-multiselect'
import moment from 'moment';
import CDatePicker from './custom-date-picker'
import CsMultiselect from './custom-search-multiselect';
import DataTable from "../js/components/datatable";
import BaseChart from './base-chart'

export default {
  data() {
    return {
      loading: true,
      loadingFilters: true,
      loadingCompetitorsData: false,
      table: null,
      semesterStart: null,
      semesterEnd: null,
      showTables: false,
      stateFilterLoading: false,
      cityFilterLoading: false,
      visualizationType: 'percent',

      loseCount: 0,
      winCount: 0,
      currentUniversityName: null,
      onlyQp: false,

      shortcuts: [
        {
          text: '<< 6 m',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).subtract(6, 'months').toDate(), moment(this.semesterEnd).subtract(6, 'months') ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Semestre',
          onClick: () => {
            this.dateRange = [ this.semesterStart, this.semesterEnd ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 30',
          onClick: () => {
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            this.dateRange = [ moment().subtract(7, 'days').toDate(), new Date() ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: '<< 7 d',
          onClick: () => {
            this.dateRange = [ moment(this.dateRange[0]).subtract(7, 'days').toDate(), this.dateRange[0] ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Até hoje',
          onClick: () => {
            this.dateRange = [ this.dateRange[0], moment().toDate() ]
            this.timeRangeSelected(this.dateRange);
          }
        }
      ],
      dateRange: null,
      universityFilter: null,
      filterKinds: [],
      filterLevels: [],
      filterState: [],
      filterCity: [],

      universityOptions: [],
      kindOptions: [],
      levelOptions: [],
      stateOptions: [],
      cityOptions: [],
      universityName: '',

      competitorsTable: [],
      competitorsTablePercents: [],
      baseCompetitorsTable: [],

      chartNumbersLabels: [],
      chartNumbers: [],
      chartPercents: [],
      chartPercentsLabels: []
    }
  },
  components: {
    CDatePicker,
    CsMultiselect,
    Multiselect,
    BaseChart,
  },
  watch: {
    visualizationType: function(value) {
      this.visualizationTypeInput(value);
    }
  },
  computed: {
    numberView() {
      return this.visualizationType == 'number';
    },
    percentView() {
      return this.visualizationType == 'percent';
    }
  },
  mounted() {
    CompetitorsChannel.on('filters', (payload) => this.receiveFilters(payload));
    CompetitorsChannel.on('locationFilters', (payload) => this.receiveLocationFilters(payload));
    CompetitorsChannel.on('competitorsData', (payload) => this.receiveCompetitorsData(payload));
    CompetitorsChannel.on('citiesFilters', (payload) => this.receiveCitiesFilters(payload));

    this.loadFilters();
  },
  methods: {
    visualizationTypeInput(data) {
      this.$nextTick(() => {
        if (!_.isNil(this.$refs.loseChart)) {
          this.$refs.loseChart.clearSeries();
          this.setChartData();
        }
      });
    },
    timeRangeSelected(dateRange) {
      console.log("timeRangeSelected# dateRange: " + dateRange);
    },
    universityRemoved() {
      console.log("universityRemoved");
      this.nextTickloadLocationFilters();
    },
    kindRemoved() {
      console.log("kindRemoved");
      this.nextTickloadLocationFilters();
    },
    levelRemoved() {
      console.log("levelRemoved");
      this.nextTickloadLocationFilters();
    },
    kindSelected(data) {
      console.log("kindSelected# data: " + JSON.stringify(data));
      this.nextTickloadLocationFilters();
    },
    levelSelected(data) {
      console.log("levelSelected# data: " + JSON.stringify(data));
      this.nextTickloadLocationFilters();
    },
    stateRemoved() {
      console.log("stateRemoved");
      this.nextTickloadCityFilters();
    },
    stateSelected(data) {
      console.log("stateSelected# data: " + JSON.stringify(data));
      this.nextTickloadCityFilters();
    },
    universitySelected(data) {
      console.log("universitySelected# data: " + JSON.stringify(data));
      this.nextTickloadLocationFilters();
    },
    nextTickloadLocationFilters() {
      this.$nextTick(() => {
        this.loadLocationFilters();
      });
    },
    nextTickloadCityFilters() {
      this.$nextTick(() => {
        this.loadCityFilters();
      });
    },
    loadCityFilters() {
      if (_.isNil(this.universityFilter)) {
        this.cityOptions = [];
      } else {
        this.cityFilterLoading = true;
        let params = this.filterParams();
        CompetitorsChannel.push('completeCities', params).receive('timeout', (data) => {
          console.log('completeCities timeout');
        });
      }
    },
    loadLocationFilters() {
      if (_.isNil(this.universityFilter)) {
        this.stateOptions = [];
        this.cityOptions = [];
      } else {
        this.stateFilterLoading = true;
        this.cityFilterLoading = true;
        let params = this.filterParams();
        CompetitorsChannel.push('completeLocation', params).receive('timeout', (data) => {
          console.log('complete timeout');
        });
      }
    },
    receiveCitiesFilters(data) {
      this.cityOptions = data.cities;
      this.cityFilterLoading = false;
    },
    receiveLocationFilters(data) {
      this.cityOptions = data.cities;
      this.stateFilterLoading = false;
      this.cityFilterLoading = false;
    },
    receiveFilters(data) {
      console.log('receiveFilters');
      this.semesterStart = data.semester_start;
      this.semesterEnd = data.semester_end;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.universityOptions = data.universities;
      this.stateOptions = data.states;

      this.dateRange = [ moment().subtract(6, 'months').toDate(), moment().toDate() ];

      this.loadingFilters = false;
    },
    setChartData() {

      if (this.visualizationType == 'number') {
        let options = { labelsData: this.chartNumbersLabels }
        this.$refs.loseChart.setSeriesWithOptions(0, this.chartNumbers, '', options);

        this.competitorsTable = this.baseCompetitorsTable;
      } else {
        let options = { labelsData: this.chartPercentsLabels }
        this.$refs.loseChart.setSeriesWithOptions(0, this.chartPercents, '', options);

        this.competitorsTable = this.competitorsTablePercents;
      }
      this.$refs.loseChart.setPadding({ left: 0, right: 0, top: 50, bottom: 0 });
      this.$refs.loseChart.updateChart();
    },
    receiveCompetitorsData(data)  {
      console.log('receiveCompetitorsData');
      this.showTables = true;

      this.baseCompetitorsTable = data.competitors_table;
      this.competitorsTablePercents = data.competitors_table_percents;

      this.currentUniversityName = data.university_name;

      this.$refs.loseChart.setDrawValues(true);
      this.$refs.loseChart.setToolTips(false);
      this.$refs.loseChart.setAlternativeDataSet(true);
      this.$refs.loseChart.setYBeginAtZero(true);
      this.$refs.loseChart.setDisplayLegend(false);
      this.$refs.loseChart.setLabels(data.lose_ies);

      this.chartNumbers = data.lose_counts;
      this.chartNumbersLabels = data.lose_counts_labels;
      this.chartPercents = data.lose_percents;
      this.chartPercentsLabels = data.lose_percents_labels;

      this.setChartData();

      this.loadingCompetitorsData = false;


      this.$nextTick(() => {
        this.$refs.loseChart.updateChart();

        this.table = new DataTable('#competitors-report-table', {
          deferRender: true,
          searchDelay: 500,
          order: [ 2, 'desc' ],
        });
      });
    },
    loadFilters() {
      CompetitorsChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    filterParams() {
      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      let params = {
        initialDate, finalDate,
        levels: this.filterLevels,
        kinds: this.filterKinds,
        cities: this.filterCity,
        states: this.filterState,
        only_qp: this.onlyQp
      }
      if (!_.isNil(this.universityFilter)) {
        params.university_id = this.universityFilter.id;
      }
      return params;
    },
    loadData() {
      if (_.isNil(this.universityFilter)) {
        alert('Selecione uma universidade');
        return;
      }

      this.showTables = false;
      this.competitorsTable = [];

      this.chartNumbersLabels = [];
      this.chartPercentsLabels = [];
      this.chartNumbers = [];
      this.chartPercents = [];

      this.$refs.loseChart.clearSeries();

      let params = this.filterParams();
      CompetitorsChannel.push('loadData', params).receive('ok', (data) => {
        this.universityName = data.university_name;
        this.loadingCompetitorsData = true;

      }).receive('timeout', (data) => {
        console.log('data timeout');
      });
    },
  },
};

</script>
