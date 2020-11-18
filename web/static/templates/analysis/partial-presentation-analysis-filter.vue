<template>
  <div>
    <div class="row" >
      <div class="col-md-3 col-sm-6">
        <label for="kind-filter">PERÍODO</label>
        <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
      </div>
    </div>
    <div class="row" >
      <div class="col-md-12 col-sm-6">
        <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
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
import PanelPrimaryFilter from '../panel-primary-filter';

export default {
  data() {
    return {
      dateRange: null,
      shortcuts: [
        {
          text: 'Início do ano',
          onClick: () => {
            let currentYear = new Date().getFullYear();
            let final = new Date(`${currentYear}-6-30`);

            this.dateRange = [ moment().startOf('year').toDate(), moment(final.valueOf()) ]
          }
        },
        {
          text: 'Final do ano',
          onClick: () => {
            let currentYear = new Date().getFullYear();
            let inicial = new Date(`${currentYear}-7-1`);
            let final = new Date(`${currentYear}-12-31 00:00:00`);

            this.dateRange = [ moment(inicial.valueOf()).toDate(), moment(final.valueOf()).toDate() ]
          }
        },
        {
          text: 'Semestre atual',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).toDate(), moment().subtract(1, 'days').toDate() ]
          }
        },
      ],
      filterKinds: [],
      filterLevels: [],
      filterOptions: [
        { name: 'Universidade', type: 'university'},
        { name: 'Grupo', type: 'group'},
      ],
    }
  },
  props: ['universityOptions','kindOptions','levelOptions','locationOptions','regionsOptions','statesOptions','semesterStart','semesterEnd','citiesOptions', 'campusOptions','universityGroupOptions'],
  components: {
    CDatePicker,
    CsMultiselect,
    LocationFilter,
    Multiselect,
    PanelPrimaryFilter,
  },
  mounted() {
    this.$refs.filter.setFilterType(this.filterOptions[0]);
    this.dateRange = [ moment(this.semesterStart).toDate(), moment().subtract(1, 'days').toDate()]
  },
  methods: {
    primaryFilterSelected(data) {
      console.log("primaryFilterSelected: " + JSON.stringify(data))
    },
    validateParameters() {
      if (_.isNil(this.dateRange[0]) || _.isNil(this.dateRange[1])) {
        alert('Selecione um período');
        return false;
      }
      if (!this.$refs.filter.validateFilter()) {
        return false;
      }
      let currentFilter = this.$refs.filter.filterSelected();
      if (_.isNil(currentFilter)) {
        alert("Selecione um tipo de filtro");
        return false;
      } else {
        if (_.isNil(currentFilter.value)) {
          alert("Selecione um valor para o filtro");
          return false;
        }
      }
      if (_.isNil(this.dateRange[0]) || _.isNil(this.dateRange[1])) {
        alert('Selecione um período');
        return false;
      }
      return true;
    },
    filterData() {

      if (!this.validateParameters()) {
        return;
      }
      let baseFilters = [ this.$refs.filter.filterSelected() ];

      let filterMap = {
        baseFilters,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        initialDate: this.dateRange[0],
        finalDate: this.dateRange[1],
      }

      return filterMap;
    },
  }
}
</script>
