<template>
  <div>
    <div :class="defaultClass">
      <div>
        <label for="location-filter">LOCALIZACAO</label>
        <multiselect v-model="locationType" :options="locationOptions" label="name" track-by="type" placeholder="Todas as localizaçoes" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationTypeSelected" @remove="locationTypeRemoved"></multiselect>
      </div>
    </div>


    <div :class="defaultClass" v-show="regionFilter">
      <div>
        <label for="region-filter">REGIÃO</label>
        <multiselect v-model="locationRegion" :options="regionsOptions" label="name" placeholder="Selecione a região" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></multiselect>
      </div>
    </div>

    <div :class="defaultClass" v-show="regionsFilter">
      <div>
        <label for="region-filter">REGIÕES</label>
        <multiselect v-model="locationRegions" :options="regionsOptions" :multiple="true" track-by="type" label="name" placeholder="Selecione as regiões" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></multiselect>
      </div>
    </div>


    <div :class="defaultClass" v-show="stateFilter">
      <div>
        <label for="state-filter">ESTADO</label>
        <cs-multiselect id="state-filter" v-model="locationState" :options="statesOptions" label="name" placeholder="Selecione o estado" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></cs-multiselect>
      </div>
    </div>

    <div :class="defaultClass" v-show="statesFilter">
      <div>
        <label for="state-filter">ESTADOS</label>
        <cs-multiselect id="state-filter" v-model="locationStates" :options="statesOptions" track-by="type" :multiple="true" label="name" placeholder="Selecione os estados" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></cs-multiselect>
      </div>
    </div>

    <div :class="defaultClass" v-show="cityFilter">
      <div class="transparent-loader" v-if="cityFilterLoading">
        <div class="loader"></div>
      </div>
      <div>
        <label for="city-filter">CIDADE</label>
        <cs-multiselect v-model="locationCity" :options="citiesOptions" label="name" placeholder="Selecione a cidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected" ></cs-multiselect>
      </div>
    </div>

    <div :class="defaultClass" v-show="citiesFilter">
      <div class="transparent-loader" v-if="cityFilterLoading">
        <div class="loader"></div>
      </div>
      <div>
        <label for="city-filter">CIDADES</label>
        <cs-multiselect v-model="locationCities" :options="citiesOptions" :multiple="true" label="name" track-by="name" placeholder="Selecione as cidades" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected" ></cs-multiselect>
      </div>
    </div>

    <div :class="defaultClass" v-show="campusFilter">
      <div class="transparent-loader" v-if="campusFilterLoading">
        <div class="loader"></div>
      </div>
      <div>
        <label for="campus-filter">CAMPUS</label>
        <multiselect v-model="locationCampus" :options="campusOptions" label="name" placeholder="Selecione o campus" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></multiselect>
      </div>
    </div>
  </div>

</template>

<script>
import _ from 'lodash'
import Multiselect from 'vue-multiselect'
import CsMultiselect from './custom-search-multiselect';

export default {
  data() {
    return {
      locationType: null,
      locationRegion: null,
      locationState: null,
      locationCity: null,
      locationCampus: null,
      campusFilterLoading: false,
      cityFilterLoading: false,
      locationCities: [],
      locationStates: [],
      locationRegions: []
    }
  },
  props: {
    classMultiplier: {
      type: Number,
      default: 2,
    },
    locationOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    regionsOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    statesOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    citiesOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    campusOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
  },
  components: {
    Multiselect,
    CsMultiselect,
  },
  computed: {
    defaultClass() {
      return `col-md-${this.classMultiplier} col-sm-${this.classMultiplier * 3}`;
    },
    regionsFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'regions') {
        return true;
      }
      return false;
    },
    regionFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'region') {
        return true;
      }
      return false;
    },
    stateFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'state') {
        return true;
      }
      return false;
    },
    statesFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'states') {
        return true;
      }
      return false;
    },
    cityFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'city') {
        return true;
      }
      return false;
    },
    citiesFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'cities') {
        return true;
      }
      return false;
    },
    campusFilter() {
      if (!_.isNil(this.locationType) && this.locationType != '' && this.locationType.type == 'campus') {
        return true;
      }
      return false;
    },
  },
  methods: {
    locationValue() {
      if (this.locationType) {
        const locationType = this.locationType.type;
        if (locationType == "region") {
          return this.locationRegion;
        } else if (locationType == "state") {
          return this.locationState;
        } else if (locationType == "city") {
          return this.locationCity;
        } else if (locationType == "campus") {
          return this.locationCampus;
        } else if (locationType == "regions") {
          return this.locationRegions;
        } else if (locationType == "states") {
          return this.locationStates;
        } else if (locationType == "cities") {
          return this.locationCities;
        }
      }
      return;
    },
    locationFilter() {
      if (this.locationType) {
        return this.locationType.type;
      }
      return;
    },
    setCitiesLoader(value) {
      this.cityFilterLoading = value;
    },
    setCampusLoader(value) {
      this.campusFilterLoading = value;
    },
    locationTypeSelected(data) {
      console.log("locationTypeSelected# data: " + JSON.stringify(data));
      this.locationCity = '';
      this.locationRegion = '';
      this.locationState = '';
      this.locationCampus = '';
      this.locationCities = [];
      this.locationStates = [];
      this.locationRegions = [];

      let eventType = `${data.type}LocationSelected`;

      console.log("locationTypeSelected# eventType: " + eventType);
      this.$emit(eventType);
    },
    locationTypeRemoved(data) {
      this.$nextTick(() => {
        console.log("locationTypeRemoved data: " + JSON.stringify(data) + " locationType: " + JSON.stringify(this.locationType));
        this.$emit('locationTypeRemoved');
        this.locationTypeSelected(data);
      });

    },
    locationValueSelected(data) {
      console.log('locationValueSelected data: ' + JSON.stringify(data));
      this.$nextTick(() => {
        this.$emit('locationValueSelected');
      });
    },
    validateFilter() {
      if (!_.isNil(this.locationType)) {
        if (this.locationType.type == 'regions') {
          if (_.isEmpty(this.locationRegions)) {
            alert('Selecione pelo menos uma região');
            return false;
          }
        } else if (this.locationType.type == 'region') {
          if (this.locationRegion == '') {
            alert('Selecione a região');
            return false;
          }
        } else if (this.locationType.type == 'state') {
          if (this.locationState == '') {
            alert('Selecione o estado');
            return false;
          }
        } else if (this.locationType.type == 'states') {
          if (_.isEmpty(this.locationStates)) {
            alert('Selecione pelo menos um estado');
            return false;
          }
        } else if (this.locationType.type == 'city') {
          if (this.locationCity == '') {
            alert('Selecione a cidade');
            return false;
          }
        } else if (this.locationType.type == 'cities') {
          if (_.isEmpty(this.locationCities)) {
            alert('Selecione pelo menos uma cidade');
            return false;
          }
        } else if (this.locationType.type == "campus") {
          if (this.locationCampus == '') {
            alert('Selecione o campus');
            return false;
          }
        }
      }
      return true;
    }
  },
}
</script>
