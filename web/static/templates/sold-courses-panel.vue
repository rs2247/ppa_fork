<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Cursos mais vendidos ( janela de 1 ano )
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
                  <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel="" @input="kindValueSelected"></multiselect>
                </div>
              </div>
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @input="levelValueSelected"></multiselect>
                </div>
              </div>

              <location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" @cityLocationSelected="loadCities" @locationValueSelected="locationSelected" @locationTypeRemoved="locationRemoved"></location-filter>
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div class="transparent-loader" v-if="iesFilterLoading">
                  <div class="loader"></div>
                </div>
                <div>
                  <label for="kind-filter">IES</label>
                  <cs-multiselect v-model="filterIes" :options="universityOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as IES's" selectLabel="" deselectLabel="" @input="iesValueSelected"></cs-multiselect>
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
                  <th v-if="showIes">IES</th>
                  <th>Curso</th>
                  <th>Modalidade</th>
                  <th>Nível</th>
                  <th>Cidade</th>
                  <th>Estado</th>
                  <th>Pagos</th>
                  <th>Desconto médio</th>
                  <th>Offered médio</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="course in tableData">
                  <td v-if="showIes">{{ course.university_name }}</td>
                  <td>{{ course.clean_canonical_course_name }}</td>
                  <td>{{ course.parent_kind_name }}</td>
                  <td>{{ course.parent_level_name }}</td>
                  <td>{{ course.city }}</td>
                  <td>{{ course.state }}</td>
                  <td>{{ course.paids }}</td>
                  <td>{{ course.average_discount }} %</td>
                  <td>R$ {{ course.average_offered_price }}</td>
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
      filterIes: [],
      iesFilterLoading: false,
    }
  },
  mounted() {
    SoldCoursesChannel.on('tableData', (payload) => this.receiveTableData(payload));
    SoldCoursesChannel.on('filters', (payload) => this.receiveFilters(payload));
    SoldCoursesChannel.on('citiesComplete', (payload) => this.receiveCitiesComplete(payload));
    SoldCoursesChannel.on('universitiesComplete', (payload) => this.receiveUniversitiesComplete(payload));

    this.loadFilters();
    this.loadUniversities();
  },
  components: {
    Multiselect,
    LocationFilter,
    CsMultiselect,
  },
  methods: {
    kindValueSelected() {
      this.loadData();
      this.loadUniversities();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    levelValueSelected() {
      this.loadData();
      this.loadUniversities();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    iesValueSelected() {
      this.loadData();
      if (this.$refs.locationFilter.locationFilter() == 'city') {
        this.loadCities();
      }
    },
    locationRemoved() {
      this.loadData();
      this.loadUniversities();
    },
    loadCities() {
      this.$refs.locationFilter.setCitiesLoader(true);
      let params = this.filterParams();
      SoldCoursesChannel.push('completeCities', params).receive('timeout', (data) => {
        console.log('complete timeout');
      });
    },
    locationSelected() {
      this.loadData();
      this.loadUniversities();
    },
    receiveCitiesComplete(data) {
      this.citiesOptions = data.cities;
      this.$refs.locationFilter.setCitiesLoader(false);
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
      this.showIes = data.show_ies_column;
      this.loading = false;

      this.$nextTick(() => {
        let ordering = 5;
        if (this.showIes) {
          ordering = 6;
        }
        this.table = new DataTable('#report-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ ordering, 'desc' ]
        });
      });
    },
    loadUniversities() {
      this.iesFilterLoading = true;
      let params = this.filterParams();
      SoldCoursesChannel.push('completeUniversities', params).receive('timeout', (data) => {
        console.log('completeUniversities timeout');
      });
    },
    loadFilters() {
      SoldCoursesChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    filterParams() {
      let params = {
        kinds: this.filterKinds,
        levels: this.filterLevels,
        universities: this.filterIes
      }
      if (this.$refs.locationFilter.locationValue()) {
        params.locationType = this.$refs.locationFilter.locationFilter();
        params.locationValue = this.$refs.locationFilter.locationValue();
      }
      return params;
    },
    loadData() {
      this.tableData = [];
      let params = this.filterParams();
      SoldCoursesChannel.push('loadData', params).receive('timeout', (data) => {
        console.log('load timeout');
      });
    },
  },
};

</script>
