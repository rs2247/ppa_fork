<template>
  <div>
    <div class="row" >
      <div class="col-md-12 col-sm-6">
        <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
        <!-- label>UNIVERSIDADE</label>
        <cs-multiselect v-model="universityFilter" :options="universityOptions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></cs-multiselect-->
      </div>
    </div>

    <div class="row" >
      <div class="col-md-4 col-sm-6">
        <div>
          <label for="kind-filter">PERÍODO</label>
          <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker >
        </div>
      </div>
      <div class="col-md-2 col-sm-6">
        <div>
          <label for="kind-filter">MODALIDADE</label>
          <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></multiselect>
        </div>
      </div>
      <div class="col-md-2 col-sm-6">
        <div>
          <label for="level-filter">NÍVEL</label>
          <multiselect v-model="filterLevels" :options="levelOptions" :multiple="permitMultipleLevel" label="name" track-by="id" :placeholder="levelsPlaceholder" selectLabel="" deselectLabel=""></multiselect>
        </div>
      </div>


      <!-- location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" :campus-options="campusOptions" @cityLocationSelected="loadCities" @campusLocationSelected="loadCampuses"></location-filter -->

    </div>
    <div class="row" >
      <div class="col-md-2 col-sm-6">
        <div>
          <label for="level-filter">VERSÃO</label>
          <multiselect v-model="presentationVersion" :options="versionOptions" label="name" track-by="type" placeholder="Selecione a versão" selectLabel="" deselectLabel=""></multiselect>
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
            let inicial = new Date(`${currentYear-1}-7-1`);
            let final = new Date(`${currentYear-1}-12-31 00:00:00`);

            this.dateRange = [ moment(inicial.valueOf()).toDate(), moment(final.valueOf()).toDate() ]
          }
        },
        {
          text: 'Semestre atual',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ]
          }
        },
      ],
      filterKinds: [],
      filterLevels: [],
      filterOptions: [
        { name: 'Universidade', type: 'university'},
        { name: 'Grupo', type: 'group'},
      ],
      versionOptions: [
        { name: '2019.1', type: '2019.1' },
        { name: '2019.2', type: '2019.2' },
        { name: '2020.1', type: '2020.1' }
      ],
      presentationVersion: null,
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

  watch: {
    presentationVersion: function(value) {
      console.log("presentationVersion: " + value.type + " filterLevels: " + JSON.stringify(this.filterLevels) + " TYPE: " + Array.isArray(this.filterLevels));
      if (value.type == '2019.1' && !Array.isArray(this.filterLevels)) {
        //precisa ser array
        this.filterLevels = [ this.filterLevels ];
      }

      if (value.type == '2019.2' && Array.isArray(this.filterLevels)) {
        //nao pode ser array
        this.filterLevels = this.filterLevels[0];
      }


    },
  },
  mounted() {
    this.$refs.filter.setFilterType(this.filterOptions[0]);
    this.dateRange = [ this.semesterStart, this.semesterEnd ];
    this.presentationVersion = this.versionOptions[2];
  },
  computed: {
    permitMultipleLevel() {
      return this.presentationVersion == this.versionOptions[0];
    },
    levelsPlaceholder() {
      if (this.presentationVersion == this.versionOptions[0]) {
        return "Todos os níveis";
      }
      return "Selecione o nível"
    },
  },
  methods: {
    primaryFilterSelected(data) {
      console.log("primaryFilterSelected: " + JSON.stringify(data))
    },
    validateParameters() {
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

      console.log("VALIDATE levels: " + JSON.stringify(this.filterLevels) + " EMPTY: " + _.isEmpty(this.filterLevels));

      if (this.presentationVersion != this.versionOptions[0] &&
          (_.isEmpty(this.filterLevels))) {
        alert("Selecione um nível");
        return false;
      }

      // if (this.presentationVersion.type == '2019.2') {
      //   if (this.filterLevels.id != "1") {
      //     alert("Neste momento somente apresentações para Graduação estão sendo geradas");
      //     return false;
      //   }
      // }
      return true;
    },
    filterData() {
      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      let baseFilters = [ this.$refs.filter.filterSelected() ];

      let filterMap = {
        initialDate,
        finalDate,
        baseFilters,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        version: this.presentationVersion.type,
      }

      return filterMap;
    },
  }
}
</script>
