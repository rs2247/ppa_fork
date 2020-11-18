<template>
  <div>
    <div class="row" >
      <div class="col-md-4 col-sm-6">
        <label>UNIVERSIDADE</label>
        <cs-multiselect v-model="universityFilter" :options="universityOptions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></cs-multiselect>
      </div>
    </div>

    <div class="row" >
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
      <div class="col-md-2 col-sm-6">
        <div class="default-margin-top">
          <input type="checkbox" v-model="mergeEadAndSemi" style="margin-right: 5px;" checked><label>EAD E SEMI NO MESMO SLIDE</label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import moment from 'moment';
import Multiselect from 'vue-multiselect'
import CDatePicker from '../custom-date-picker'
import CsMultiselect from '../custom-search-multiselect';
import LocationFilter from '../location-filter';

export default {
  data() {
    return {
      dateRange: null,
      filterKinds: [],
      filterLevels: [],
      mergeEadAndSemi: false,
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
          text: 'Ultimos 30',
          onClick: () => {
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
          }
        },
        {
          text: 'Ultimos 7',
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
    }
  },
  props: ['universityOptions','kindOptions','levelOptions','locationOptions','regionsOptions','statesOptions','semesterStart','semesterEnd','citiesOptions', 'campusOptions'],
  mounted() {
    //this.dateRange = [ moment(this.semesterStart).toDate(), moment().toDate() ];

  },
  // watch: {
  //   citiesOptions: function (data) {
  //     this.$refs.locationFilter.setCitiesLoader(false);
  //   },
  //   campusOptions: function (data) {
  //     this.$refs.locationFilter.setCampusLoader(false);
  //   }
  // },
  components: {
    CDatePicker,
    CsMultiselect,
    LocationFilter,
    Multiselect,
  },
  methods: {
    validateParameters() {
      if (_.isNil(this.universityFilter)) {
        alert("Selecione a universidade");
        return false;
      }
      return true;
    },
    filterData() {
      // let initialDate = this.dateRange[0];
      // let finalDate = this.dateRange[1];

      let baseFilters = [{ type: "university", value: this.universityFilter }];

      let filterMap = {
        //initialDate,
        //finalDate,
        baseFilters,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        mergeEadAndSemi: this.mergeEadAndSemi
      }

      // if (this.$refs.locationFilter.locationValue()) {
      //   filterMap.locationType = this.$refs.locationFilter.locationFilter();
      //   filterMap.locationValue = this.$refs.locationFilter.locationValue();
      // }

      return filterMap;
    },
    // filterComplete(field) {
    //   let filter = this.filterData();
    //   if (filter) {
    //     this.cityFilterLoading = true;
    //     this.campusFilterLoading = true;
    //
    //     filter.completeField = field;
    //     AnalysisChannel.push('filterComplete', filter).receive('timeout', () => {
    //       console.log('filterComplete timeout');
    //     })
    //   }
    // },
    // loadCities() {
    //   this.$refs.locationFilter.setCitiesLoader(true);
    //   this.filterComplete('city');
    // },
    // loadCampuses() {
    //   this.$refs.locationFilter.setCampusLoader(true);
    //   this.filterComplete('campus');
    // },
  }
}
</script>
