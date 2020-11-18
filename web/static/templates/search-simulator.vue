<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Simulador de busca
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
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="level-filter">CURSO</label>
                  <cs-multiselect v-model="filterCourse" :alow-empty="false" :options="coursesOptions" label="name" track-by="name" placeholder="Selecione o curso" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="level-filter">CIDADE</label>
                  <cs-multiselect v-model="filterCity" :alow-empty="false" :options="citiesOptions" label="name" track-by="name" placeholder="Selecione a cidade" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-6">
                <div>
                  <label for="kind-filter">UNIVERSIDADE</label>
                  <cs-multiselect v-model="filterUniversity" :options="universityOptions" label="name" track-by="id" placeholder="Todas as universidades" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEIS</label>
                  <multiselect v-model="filterLevels" :multiple="true" :options="levelOptions" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADES</label>
                  <multiselect v-model="filterKinds" :multiple="true" :options="kindOptions" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></multiselect>
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

    <div class="row" v-if="hasData">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <table id="search-table" class="data-table data-table-tiny">
            <thead>
              <tr>
                <th>IES</th>
                <th>Curso</th>
                <th>Desconto</th>
                <th>Modalidade</th>
                <th>Nível</th>
                <th>Turno</th>
                <th>Preço Oferecido</th>
                <th>Relevance Score</th>
                <th>Cidade</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in tableData">
                <td>{{ entry.university_name }}</td>
                <td>{{ entry.course_name }}</td>
                <td>{{ entry.discount_percentage }}</td>
                <td>{{ entry.course_kind }}</td>
                <td>{{ entry.course_level }}</td>
                <td>{{ entry.course_shift }}</td>
                <td>{{ entry.offered_price }}</td>
                <td>{{ entry.relevance_score }}</td>
                <td>{{ entry.city }}</td>
                <td>{{ entry.state }}</td>
              </tr>
            </tbody>
          </table>
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

import exportToCsv from "../js/utils/export";

export default {
  data() {
    return {
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      kindOptions: [],
      levelOptions: [],
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      coursesOptions: [],
      meanRank: null,

      filterKinds: null,
      filterLevels: null,
      filterCity: null,

      tableData: [],
      table: null,
      hasChartData: false,

      loadingFilters: true,
      dataLoading: false,
      currentFilter: null,
      filterCourse: null,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    LocationFilter,
    BaseChart,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    SearchSimulatorChannel.on('filters', (payload) => this.receiveFilters(payload));
    SearchSimulatorChannel.on('tableData', (payload) => this.receiveTableData(payload));

    //SearchSimulatorChannel.on('citiesFilters', (payload) => this.receiveCitiesFilters(payload));

    this.loadFilters();
  },
  methods: {
    loadCities() {
      //this.$refs.locationFilter.setCitiesLoader();
    },
    loadCampuses() {
      console.log('loadCampuses');
    },
    primaryFilterSelected() {
      //faz o complete de cidade!
      //this.completeCities();
    },
    receiveTableData(data) {
      this.tableData = data.entries;

      this.$nextTick(() => {
        this.table = new DataTable('#search-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
          order: [ 7, 'desc' ],
        });
      });

      this.dataLoading = false;
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.locationOptions = data.locationTypes;
      this.citiesOptions = data.cities;
      this.coursesOptions = data.courses;

      this.filterLevels = [ this.levelOptions[0] ];

      this.loadingFilters = false;
    },
    // completeCities() {
    //   //let filter = this.$refs.filter.filterSelected();
    //   let filter = this.getFilters();
    //   console.log("filter: " + JSON.stringify(filter));
    //   if (_.isNil(filter.value) || filter.value == '') {
    //     this.citiesOptions = [];
    //     return;
    //   }
    //
    //   filter.kinds = this.filterKinds;
    //   filter.levels = this.filterLevels;
    //   SearchSimulatorChannel.push('completeCities', filter).receive('timeout', (data) => {
    //     console.log('cities complete timeout');
    //   });
    // },
    loadFilters() {
      SearchSimulatorChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    // getFilters() {
    //   if (_.isNil(this.filterUniversity)) {
    //     return;
    //   }
    //   let filters = {
    //     value: this.filterUniversity
    //   }
    //   return filters;
    // },
    loadData() {
      //let filter = this.$refs.filter.filterSelected();
      //let filter = this.getFilters();
      // if (_.isNil(filter) || filter.value == '') {
      //   alert('Selecione uma IES');
      //   return;
      // }
      //
      // if (_.isNil(this.filterCity)) {
      //   alert('Selecione a cidade');
      //   return;
      // }
      //
      // if (_.isNil(this.filterKinds)) {
      //   alert('Selecione a modalidade');
      //   return;
      // }

      //this.meanRank = null;
      this.dataLoading = true;
      this.tableData = [];


      //this.$refs.rankingChart.clearSeries();
      let filter = {};


      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;
      if (!_.isNil(this.filterCity)) {
        filter.city_id = this.filterCity.city_id;
      }
      filter.course = this.filterCourse;

      this.currentFilter = filter;

      SearchSimulatorChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
