<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Cursos mais buscados ( janela de 1 ano )
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADE</label>
                  <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" @cityLocationSelected="loadCities" @locationValueSelected="locationSelected" @locationTypeRemoved="locationRemoved"></location-filter>

              <div class="col-md-4 col-sm-6">
                <label>AGRUPAMENTOS
                  <span class="glyphicon glyphicon-info-sign tooltip__icon" style="font-size: 16px;">
                    <div class="tooltip__content">
                      <span>
                          <p>Permitem o agrupamento do resultado por CIDADE / MODALIDADE / IES</p>
                      </span>
                    </div>
                  </span>
                </label>
                <div>
                  <input type="checkbox" v-model="groupCity" style="margin-right: 5px;"><label>CIDADE</label>
                  <input type="checkbox" v-model="groupKind" style="margin-right: 5px; margin-left: 5px;"><label>MODALIDADE</label>
                  <input type="checkbox" v-model="groupIes" style="margin-right: 5px; margin-left: 5px;"><label>IES</label>
                  <div v-show="groupIes" style="display: inline-block;">
                    <input type="checkbox" v-model="showValidIes" style="margin-right: 5px; margin-left: 5px;"><label>APENAS BUSCAS COM IES</label>
                    <span class="glyphicon glyphicon-info-sign tooltip__icon" style="font-size: 16px;">
                      <div class="tooltip__content">
                        <span>
                            <p>Considera apenas buscas em que o usuário selecionou uma IES</p>
                        </span>
                      </div>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div class="transparent-loader" v-if="iesFilterLoading">
                  <div class="loader loader-small loader-grey" style="margin-top: 20px;"></div>
                </div>
                <div>
                  <label for="ies-filter">IES</label>
                  <cs-multiselect v-model="filterIes" :options="universityOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as IES's" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6">
                <div class="transparent-loader" v-if="courseFilterLoading">
                  <div class="loader loader-small loader-grey" style="margin-top: 20px;"></div>
                </div>
                <div>
                  <label for="course-filter">CURSO</label>
                  <cs-multiselect v-model="filterCourse" :options="courseOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os cursos" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-3">
                <div class="default-margin-top" style="">
                  <input type="checkbox" v-model="cleanCanonicals" style="margin-right: 5px;"><label>APENAS CURSO MÃE</label>
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

    <div class="row" v-if="tableData.length > 0">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="report-table" class="data-table sticky-header">
              <thead id="table-header">
                <tr>
                  <th>Curso</th>
                  <th v-if="hasKindField">Modalidade</th>
                  <th v-if="hasIesField">IES</th>
                  <th>Nível</th>
                  <th v-if="hasCityField">Cidade</th>
                  <th v-if="hasCityField">Estado</th>
                  <th>Buscas</th>
                  <!-- th>Visitas</th -->
                </tr>
              </thead>
              <tbody>
                <tr v-for="course in tableData">
                  <td>{{ course.clean_canonical_course_name }}</td>
                  <td v-if="hasKindField">{{ course.course_kind }}</td>
                  <td v-if="hasIesField">{{ course.ies_name }}</td>
                  <td>{{ course.course_level }}</td>
                  <td v-if="hasCityField">{{ course.city }}</td>
                  <td v-if="hasCityField">{{ course.state }}</td>
                  <td>{{ course.buscas }}</td>
                  <!-- td>{{ course.visitas }}</td -->
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import DataTable from "../js/components/datatable";
import Multiselect from 'vue-multiselect'
import LocationFilter from './location-filter';
import CsMultiselect from './custom-search-multiselect'

export default {
  data() {
    return {
      loading: true,
      tableData: [],
      table: null,
      filterKinds: null,
      filterLevels: null,
      kindOptions: [],
      levelOptions: [],
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      universityOptions: [],
      courseOptions: [],
      filterIes: [],
      filterCourse: [],
      iesFilterLoading: false,
      courseFilterLoading: false,
      groupKind: false,
      groupIes: false,
      groupCity: false,
      hasKindField: false,
      hasIesField: false,
      cleanCanonicals: true,
      showValidIes: false,
    }
  },
  mounted() {
    CoursesChannel.on('tableData', (payload) => this.receiveTableData(payload));
    CoursesChannel.on('filters', (payload) => this.receiveFilters(payload));
    CoursesChannel.on('citiesComplete', (payload) => this.receiveCitiesComplete(payload));
    CoursesChannel.on('universitiesComplete', (payload) => this.receiveUniversitiesComplete(payload));
    CoursesChannel.on('coursesComplete', (payload) => this.receiveCoursesComplete(payload));

    this.loadFilters();
    this.loadUniversities();
    this.loadCourses();
  },
  components: {
    Multiselect,
    LocationFilter,
    CsMultiselect,
  },
  watch: {
    cleanCanonicals: function (value) {
      this.loadCourses();
    },
    groupKind: function (value) {
      //this.loadData();
    },
    groupIes: function (value) {
      //this.loadData();
    },
    filterLevels: function (value) {
      //this.loadData();
      this.loadUniversities();
      this.loadCourses();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    filterKinds: function (value) {
      //this.loadData();
      this.loadUniversities();
      this.loadCourses();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    filterIes: function (value) {
      //this.loadData();
      this.loadCourses();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    filterCourse: function (value) {
      //this.loadData();
      this.loadUniversities();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    }
  },
  methods: {
    locationRemoved() {
      //this.loadData();
      this.loadUniversities();
    },
    loadCities() {
      this.$refs.locationFilter.setCitiesLoader(true);
      let params = this.filterParams();
      CoursesChannel.push('completeCities', params).receive('timeout', (data) => {
        console.log('complete timeout');
      });
    },
    locationSelected() {
      //this.loadData();
      this.loadUniversities();
      this.loadCourses();
    },
    receiveCitiesComplete(data) {
      this.citiesOptions = data.cities;
      this.$refs.locationFilter.setCitiesLoader(false);
    },
    receiveCoursesComplete(data) {
      this.courseOptions = data.courses;
      this.courseFilterLoading = false;
    },
    receiveUniversitiesComplete(data) {
      this.universityOptions = data.universities;
      this.iesFilterLoading = false;
    },
    receiveFilters(data) {
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.locationOptions = data.locations;
      this.regionsOptions = data.regions;
      this.statesOptions = data.states;
      this.loadData();
    },
    receiveTableData(data) {
      console.log("receiveTableData");

      this.tableData = data.courses;
      this.hasKindField = data.has_kind_field;
      this.hasIesField = data.has_ies_field;
      this.hasCityField = data.has_city_field;
      this.loading = false;

      let orderColumn = 2;
      if (this.hasCityField) orderColumn += 2;
      if (this.hasKindField) orderColumn++;
      if (this.hasIesField) orderColumn++;

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ orderColumn, 'desc' ]
        });
      });
    },
    loadCourses() {
      this.courseFilterLoading = true;
      let params = this.filterParams();
      CoursesChannel.push('completeCourses', params).receive('timeout', (data) => {
        console.log('completeCourses timeout');
      });
    },
    loadUniversities() {
      this.iesFilterLoading = true;
      let params = this.filterParams();
      CoursesChannel.push('completeUniversities', params).receive('timeout', (data) => {
        console.log('completeUniversities timeout');
      });
    },
    loadFilters() {
      CoursesChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    filterParams() {
      let params = {
        kinds: this.filterKinds,
        levels: this.filterLevels,
        universities: this.filterIes,
        groupKind: this.groupKind,
        courses: this.filterCourse,
        groupIes: this.groupIes,
        groupCity: this.groupCity,
        cleanCanonicals: this.cleanCanonicals,
        validIes: this.showValidIes
      }
      if (this.$refs.locationFilter.locationValue()) {
        params.locationType = this.$refs.locationFilter.locationFilter();
        params.locationValue = this.$refs.locationFilter.locationValue();
      }
      return params;
    },
    loadData() {
      if (!this.$refs.locationFilter.validateFilter()) {
        return false;
      }
      this.loading = true;
      this.tableData = [];
      let params = this.filterParams();
      CoursesChannel.push('loadData', params).receive('timeout', (data) => {
        console.log('load timeout');
      });
    },
  },
};

</script>
