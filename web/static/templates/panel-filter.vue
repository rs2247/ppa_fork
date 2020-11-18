<template>
  <div class="row">

    <div class="col-md-12">

      <div class="row">
        <div class="col-md-12">
          <panel-primary-filter ref="filter" :filter-options="groupOptions" :university-group-options="universityGroupOptions" :farm-region-options="farmRegionOptions" :university-options="universityOptions" :deal-owner-options="dealOwnerOptions" :quality-owner-options="qualityOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
        </div>
        <!-- div class="col-md-1">
          <i class="fas fa-plus-circle clickable" style="font-size: 30px; float: right; color: #00ff00;" @click="addFilter"></i>
        </div -->
      </div>

      <div class="row" v-for="i in filters" :key="i">
        <div class="col-md-11">
          <panel-primary-filter ref="additionalFilter" :filter-options="groupOptions" :university-group-options="universityGroupOptions" :university-options="universityOptions" :deal-owner-options="dealOwnerOptions" :quality-owner-options="qualityOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>
        </div>
        <div class="col-md-1">
          <i class="fas fa-trash-alt clickable" style="font-size: 30px; float: right; color: #ff0000;" @click="removeFilter(i)"></i>
        </div>
      </div>

      <div class="row">
        <div class="col-md-2 col-sm-6">
          <div class="">
            <label for="date">PERÍODO</label>
            <date-picker :disabled="periodDisabled" v-model="dateRange" :first-day-of-week="1" :lang="lang" range :shortcuts="shortcuts" @input="timeRangeSelected"></date-picker>
          </div>
        </div>

        <template v-if="hasProductLineOptions">
          <div class="col-md-2 col-sm-6" style="margin-top: 10px;">
            <input type="radio" :name="'product_line_selection_type_' + index" value="product_line" checked v-model="productLineSelectionType">
            <label for="">
              <span style="font-size: 18px;" class="tiny-padding-left">Linha de Produto</span>
            </label><br>
            <input type="radio" :name="'product_line_selection_type_' + index" value="kind_and_level" v-model="productLineSelectionType">
            <label for="">
              <span style="font-size: 18px;" class="tiny-padding-left">Customizado</span>
            </label>
          </div>

          <div class="col-md-2 col-sm-6" v-if="showProductLineSelection">
            <div>
              <label for="kind-filter">LINHA DE PRODUTO</label>
              <multiselect v-model="filterProductLine" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" @input="productLineSelected"></multiselect>
            </div>
          </div>
        </template>

        <template v-if="showKindAndLevelSelection">
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
        </template>

        <div class="col-md-2 col-sm-6">
          <div>
            <label for="level-filter">LOCALIZACAO</label>
            <multiselect v-model="locationType" :options="locationOptions" label="name" track-by="type" placeholder="Todas as localizaçoes" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationTypeSelected" @remove="locationTypeSelected"></multiselect>
          </div>
        </div>


        <div class="col-md-2 col-sm-6" v-if="regionFilter">
          <div>
            <label for="level-filter">REGIÃO</label>
            <multiselect v-model="locationRegion" :options="regionsOptions" label="name" placeholder="Selecione a região" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected" @remove="locationValueRemoved"></multiselect>
          </div>
        </div>

        <div class="col-md-2 col-sm-6" v-if="stateFilter">
          <div>
            <label for="level-filter">ESTADO</label>
            <cs-multiselect v-model="locationState" :options="statesOptions" label="name" placeholder="Selecione o estado" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></cs-multiselect>
          </div>
        </div>

        <div class="col-md-2 col-sm-6" v-if="cityFilter">
          <div class="transparent-loader" v-if="cityFilterLoading">
            <div class="loader loader-small loader-grey default-margin-top"></div>
          </div>
          <div>
            <label for="level-filter">CIDADE</label>
            <multiselect v-model="locationCity" :internal-search="false" :options="citiesSugestions" label="name" placeholder="Selecione a cidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected" @search-change="citySearch"></multiselect>
          </div>
        </div>

        <div class="col-md-2 col-sm-6" v-if="campusFilter">
          <div class="transparent-loader" v-if="campusFilterLoading">
            <div class="loader loader-small loader-grey default-margin-top"></div>
          </div>
          <div>
            <label for="level-filter">CAMPUS</label>
            <multiselect v-model="locationCampus" :options="campusOptions" label="name" placeholder="Selecione o campus" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="locationValueSelected"></multiselect>
          </div>
        </div>
      </div>


    </div>
  </div>
</template>

<script>

import _ from 'lodash'
import moment from 'moment';
import DatePicker from 'vue2-datepicker'
import Multiselect from 'vue-multiselect'
import CsMultiselect from './custom-search-multiselect';
import PanelPrimaryFilter from './panel-primary-filter';
import QueryString from '../js/query-string'

export default {
  data() {
    return {
      shortcuts: [
        //esse capture period, capture period anterior, semestre anterior ( vai voltando com base na data atual)
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
            this.dateRange = [ moment().subtract(31, 'days').toDate(), moment().subtract(1, 'days').toDate() ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            console.log("START: " + moment().subtract(8, 'days').startOf('day').toDate());
            this.dateRange = [ moment().subtract(8, 'days').startOf('day').toDate(), moment().subtract(1, 'days').startOf('day').toDate() ]
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
      lang: {
        days: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'],
        months: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
        placeholder: {
          date: 'Data',
          dateRange: 'Período'
        }
      },

      kindOptions: [],
      levelOptions: [],
      locationOptions: [],
      groupOptions: [],
      universityOptions: [],
      farmRegionOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      qualityOwnerOptions: [],
      accountTypeOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      productLineOptions: [],


      citiesSugestions: [],

      filterIndex: 1,
      filters: [],

      dateRange: '',
      filterKinds: [],
      filterLevels: [],
      locationType: '',
      locationRegion: '',
      locationState: '',
      locationCity: '',
      locationCampus: '',
      groupType: '',
      universityFilter: '',
      universityGroupFilter: '',
      accountTypeFilter: '',
      dealOwnerFilter: '',
      filterProductLine: null,

      cityFilterLoading: false,
      campusFilterLoading: false,
      productLineSelectionType: 'product_line',
    }
  },
  props: ['index', 'periodDisabled', 'filterDisabled'],
  components: {
    DatePicker,
    Multiselect,
    PanelPrimaryFilter,
    CsMultiselect,
  },
  watch: {
    citiesOptions: function (value) {
      this.citiesSugestions = this.citiesOptions;
    },
    productLineSelectionType: function (value) {
      this.$nextTick(() => {
        this.$emit('productLineSelectionTypeSelected', this.productLineSelectionType);
      });
    },
  },
  computed: {
    showProductLineSelection() {
      return this.productLineSelectionType == "product_line";
    },
    showKindAndLevelSelection() {
      return this.productLineSelectionType == "kind_and_level" || this.productLineOptions.length == 0;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 0;
    },
    regionFilter() {
      if (!this.locationType) {
        return false;
      }
      return this.locationType.type == 'region';
    },
    stateFilter() {
      if (!this.locationType) {
        return false;
      }
      return this.locationType.type == 'state';
    },
    cityFilter() {
      if (!this.locationType) {
        return false;
      }
      return this.locationType.type == 'city';
    },
    campusFilter() {
      if (!this.locationType) {
        return false;
      }
      return this.locationType.type == 'campus';
    },
  },
  methods: {
    citySearch(data, id) {
      if (data == '') {
        this.citiesSugestions = this.citiesOptions;
        return;
      }
      let filteredData = data.normalize('NFD').replace(/[\u0300-\u036f]/g, "");
      this.citiesSugestions = this.citiesOptions.filter(function(item_data) {
        return item_data.name.normalize('NFD').replace(/[\u0300-\u036f]/g, "").toUpperCase().includes(filteredData.toUpperCase());
      });
    },
    kindValueSelected(data) {
      this.$nextTick(() => {
        this.$emit('kindSelected', this.filterKinds);
      });
    },
    levelValueSelected(data) {
      this.$nextTick(() => {
        this.$emit('levelSelected', this.filterLevels);
      });
    },
    productLineSelected(data) {
      this.$nextTick(() => {
        this.$emit('productLineSelected', this.filterProductLine);
      });
    },
    timeRangeSelected(data) {
      this.$emit('timeRangeSelected', data);
    },
    primaryFilterSelected(data) {
      console.log("primaryFilterSelected")
      this.$nextTick(() => {
        this.$emit("primaryFilterSelected", this.baseFiltersList());
      });
    },
    addFilter() {
      this.filters.push(this.filterIndex);
      this.filterIndex = this.filterIndex + 1;
    },
    removeFilter(index) {
      this.filters.splice(this.filters.indexOf(index), 1);
    },
    locationValueRemoved() {
      //this.locationValue() ainda nao foi atualizado neste momento!
      this.$nextTick(() => {
        console.log("locationValueRemoved# TYPE: " + JSON.stringify(this.locationType) + " VAL: " + JSON.stringify(this.locationValue()));
        this.$emit("locationRemoved", this.locationType, this.locationValue());
      })
    },
    locationValueSelected() {
      this.$nextTick(() => {
        this.$emit("locationSelected", this.locationType, this.locationValue());
      });
    },
    locationTypeSelected(data) {
      console.log("locationTypeSelected# " + JSON.stringify(data));
      this.$nextTick(() => {
        this.$emit("locationTypeSelected", this.locationType, this.index);
      });
    },
    getLocationType() {
      return this.locationType;
    },
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
        }
      }
      return;
    },
    verifyBaseFilters(baseFilters, omitValidation) {
      if (baseFilters.length == 0) {
        if (!omitValidation) {
          alert('Selecione pelo menos um filtro');
        }
        return false;
      }
      for (var i = 0; i < baseFilters.length; i++) {
        var temDimensao = false;
        if (!_.isNil(baseFilters[i].value)) {
          if (!_.isNil(baseFilters[i].value.length)) {
            temDimensao = true;
          }
        }
        //console.log("baseFilters[i].value: " + baseFilters[i].value + " TESTE: " + typeof(baseFilters[i].value) + " L: " + baseFilters[i].value.length);
        if (baseFilters[i].type == '') continue;
        if (!temDimensao) {
          if (!baseFilters[i].value) {
            if (!omitValidation) {
              alert(`Selecione o valor para o filtro ${baseFilters[i].name}`)
            }
            return false;
          } else {
            if (!baseFilters[i].value.id) {
              if (!omitValidation) {
                alert(`Selecione o valor para o filtro ${baseFilters[i].name}`)
              }
              return false;
            }
          }
        } else {
          if (baseFilters[i].value.length == 0) {
            if (!omitValidation) {
              alert(`Selecione o valor para o filtro ${baseFilters[i].name}`)
            }
            return false;
          }
        }
      }
      return true;
    },
    verifyFilters(omitValidation) {
      if (omitValidation) {
        return true;
      }
      if (this.dateRange === '' || _.isNil(this.dateRange)) {
        if (!omitValidation) {
          alert('Preencha o período');
        }
        return false;
      }
      if (this.dateRange[0] == 'Invalid Date' || _.isNil(this.dateRange[0])) {
        if (!omitValidation) {
          alert('Insira um período válido');
        }
        return false;
      }
      if (this.locationType) {
        if (this.locationType.type == 'region') {
          if (this.locationRegion == '') {
            if (!omitValidation) {
              alert('Selecione a região');
            } else { console.log("SEM REGIAO"); }
            return false;
          }
        } else if (this.locationType.type == 'state') {
          if (this.locationState == '') {
            if (!omitValidation) {
              alert('Selecione o estado');
            }
            return false;
          }
        } else if (this.locationType.type == 'city') {
          if (this.locationCity == '') {
            if (!omitValidation) {
              alert('Selecione a cidade');
            } else { console.log("SEM CIDADE"); }
            return false;
          }
        } else if (this.locationType.type == "campus") {
          if (this.locationCampus == '') {
            if (!omitValidation) {
              alert('Selecione o campus');
            }
            return false;
          }
        }
      }
      return true;
    },
    //SETTERS FOR OPTIONS
    setCitiesLoading() {
      this.cityFilterLoading = true;
    },
    setCampusLoading() {
      this.campusFilterLoading = true;
    },
    setLevels(data) {
      this.levelOptions = data;
    },
    setKinds(data) {
      this.kindOptions = data;
    },
    setLocations(data) {
      this.locationOptions = data;
    },
    setGroups(data) {
      this.groupOptions = data;
    },
    setAccountTypes(data) {
      this.accountTypeOptions = data;
    },
    setUniversities(data) {
      this.universityOptions = data;
    },
    setFarmRegions(data) {
      this.farmRegionOptions = data;
    },
    setUniversityGroups(data) {
      this.universityGroupOptions = data;
    },
    setSemesterRange(startDate, endDate) {
      this.semesterStart = startDate
      this.semesterEnd = endDate;
      this.dateRange = [ this.semesterStart, this.semesterEnd ];
    },
    setDealOwners(data) {
      this.dealOwnerOptions = data;
    },
    setQualityOwners(data) {
      this.qualityOwnerOptions = data;
    },
    setRegions(data) {
      this.regionsOptions = data;
    },
    setStates(data) {
      this.statesOptions = data;
    },
    setCities(data) {
      this.citiesOptions = data;
      this.cityFilterLoading = false;
    },
    setCampus(data) {
      this.campusOptions = data;
      this.campusFilterLoading = false;
    },
    setProductLines(data) {
      this.productLineOptions = data;
    },
    clearPrimaryFilters() {
      while (this.filters.length > 0) {
        this.filters.splice(0, 1);
      }
      this.$refs.filter.setFilterType({type: ''});
    },
    //SETTERS FOR VALUES
    setPrimaryFilters(data) {
      console.log("setPrimaryFilters: " + JSON.stringify(data));
      for (var i = 0; i < data.length; i++) {
        console.log("primaryFilter: " + data[i].type);
        if (i > this.filters.length) {
          this.addFilter();
        }
        let component = this.$refs.filter;
        if (i != 0) {
          component = this.$refs.additionalFilter[i - 1];
        }
        component.setFilterType(data[i]);
        if (data[i].value) {
          if (data[i].type == 'university') {
            component.setUniversityFilter(data[i].value);
          }
          if (data[i].type == 'universities') {
            component.setUniversitiesFilter(data[i].value);
          }
          if (data[i].type == 'deal_owner') {
            component.setDealOwnerFilter(data[i].value);
          }
          if (data[i].type == 'group') {
            component.setUniversityGroupFilter(data[i].value);
          }
          if (data[i].type == 'account_type') {
            component.setAccountTypeFilter(data[i].value);
          }
          if (data[i].type == 'quality_owner') {
            component.setQualityOwnerFilter(data[i].value);
          }
          if (data[i].type == 'quality_owner_ies') {
            component.setQualityOwnerFilter(data[i].value);
          }
          if (data[i].type == 'deal_owner_ies') {
            component.setDealOwnerFilter(data[i].value);
          }
          if (data[i].type == 'farm_region') {
            component.setFarmRegionFilter(data[i].value);
          }
        }
      }
    },
    getDateRange() {
      return this.dateRange;
    },
    setDateRange(value) {
      this.dateRange = value;
    },
    setFilterKinds(value) {
      this.filterKinds = value;
    },
    setFilterLevels(value) {
      this.filterLevels = value;
    },
    setLocationValue(type, value) {
      this.locationType = type;
      if (type.type == 'region') {
        this.locationRegion = value;
      }
      if (type.type == 'state') {
        this.locationState = value;
      }
      if (type.type == 'city') {
        this.locationCity = value;
      }
      if (type.type == 'campus') {
        this.locationCampus = value;
      }
    },
    setLocationType(value) {
      this.locationType = value;
    },
    //--------
    setLocationRegion(value) {
      this.locationRegion = value;
    },
    setLocationState(value) {
      this.locationState = value;
    },
    setLocationCity(value) {
      this.locationCity = value;
    },
    setLocationCampus(value) {
      this.locationCampus = value;
    },
    //---------
    setUniversityFilter(value) {
      this.universityFilter = value;
    },
    setUniversityGroupFilter(value) {
      this.universityGroupFilter = value;
    },
    setAccountTypeFilter(value) {
      this.accountTypeFilter = value;
    },
    setDealOwnerFilter(value) {
      this.dealOwnerFilter = value;
    },
    setProductLineFilter(value) {
      this.filterProductLine = value;
    },
    setProductLineSelectionType(value) {
      this.productLineSelectionType = value;
    },
    //FILTER RETURN FUNCTION
    baseFiltersCaption() {
      let filters = [];

      if (this.$refs.filter.filterType != '' && !_.isNil(this.$refs.filter.filterType)) {
        if (this.$refs.filter.filterType.type == '') {
          filters.push('Site Todo');
        } else {
          let selection = this.$refs.filter.filterSelected();

          if ((typeof selection.value) === 'object' && selection.value instanceof Array) {
            let values = _.map(selection.value, (entry) => {
              //console.log("entry: " + JSON.stringify(entry));
              return entry.simple_name;
            });
            filters.push(`${selection.name} - ${values.join(' - ')}`);
          } else {
            filters.push(`${selection.name} - ${selection.value.simple_name}`);
          }
        }
      }
      return filters.join(' - ');
    },
    baseFiltersList() {
      let baseFilters = [];
      if (this.$refs.filter.filterType != '' && !_.isNil(this.$refs.filter.filterType)) {
        baseFilters.push(this.$refs.filter.filterSelected());
      }

      console.log("filters.length: " + this.filters.length);
      console.log("ADITIONAL: " + JSON.stringify(this.$refs.additionalFilter));

      if (this.filters.length > 0) {
        console.log("C:" + this.$refs.additionalFilter.length);
        for (var i = 0; i < this.$refs.additionalFilter.length; i++) {
          var component = this.$refs.additionalFilter[i];
          console.log("FITLRO: " + i + ": TIPO: " + JSON.stringify(component.filterSelected()) + " INDEX: " + baseFilters[i] + " C: " + component);
          if (component.filterType != '') {
            baseFilters.push(component.filterSelected());
          }
        }
      }
      return baseFilters;
    },
    setFiltersData(data) {
      let parsedFilters = _.map(data['baseFilters'], (entry) => {
        let filteredType = _.filter(this.groupOptions, (filterEntry) => {
          return filterEntry.type == entry.type;
        })
        let cloneType = _.cloneDeep(filteredType[0]);
        if (entry.type == 'university') {
          cloneType.value = QueryString.solveEntry(this.universityOptions, entry.value.id, 'id')
        } else if (entry.type == 'universities') {
          cloneType.value = QueryString.solveEntries(this.universityOptions, entry.value, 'id')
        } else if (entry.type == 'group') {;
          cloneType.value = QueryString.solveEntry(this.universityGroupOptions, entry.value.id, 'id')
        } else if (entry.type == 'deal_owner' || entry.type == 'deal_owner_ies') {
          cloneType.value = QueryString.solveEntry(this.dealOwnerOptions, entry.value.id, 'id')
        } else if (entry.type == 'account_type') {
          cloneType.value = QueryString.solveEntry(this.accountTypeOptions, entry.value.id, 'id')
        } else if (entry.type == 'quality_owner' || entry.type == 'quality_owner_ies') {
          cloneType.value = QueryString.solveEntry(this.qualityOwnerOptions, entry.value.id, 'id')
        } else if (entry.type == 'farm_region') {
          cloneType.value = QueryString.solveEntry(this.farmRegionOptions, entry.value.id, 'id')
        }
        return cloneType;
      });
      this.setPrimaryFilters(parsedFilters);
      if (!_.isNil(data['initialDate']) && !_.isNil(data['finalDate'])) {
        this.setDateRange([moment(data['initialDate']).toDate(), moment(data['finalDate']).toDate()]);
      }
      if (!_.isNil(data['kinds'])) {
        this.setFilterKinds(QueryString.solveEntries(this.kindOptions, data['kinds'], 'id'));
      }
      if (!_.isNil(data['levels'])) {
        this.setFilterLevels(QueryString.solveEntries(this.levelOptions, data['levels'], 'id'));
      }
      if (!_.isNil(data['productLine'])) {
        this.setProductLineFilter(QueryString.solveEntry(this.productLineOptions, data.productLine.id, 'id'))
      }
      if (!_.isNil(data['productLineSelectionType'])) {
        this.setProductLineSelectionType(data['productLineSelectionType']);
      }
      if (!_.isNil(data['locationValue']) && !_.isNil(data['locationType'])) {
        let locationData = data['locationValue'];
        if (data['locationType'] == 'city') {
          locationData = {
            "name": `${locationData['name']} - ${locationData['state']}`,
            "id": locationData['name'],
            "state": locationData['state'],
            "city_id": locationData['city_id']
          }
        }
        this.setLocationValue(QueryString.solveEntry(this.locationOptions, data['locationType'], 'type'), locationData);
      }
    },
    filterData(omitValidation) {
      let baseFilters = this.baseFiltersList();

      console.log("baseFilters: " + JSON.stringify(baseFilters) + " omitValidation: " + omitValidation + " !o: " + (!omitValidation));

      if (!this.verifyBaseFilters(baseFilters, omitValidation)) {
        return;
      }

      if (!this.verifyFilters(omitValidation)) {
        return;
      }

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      var locationType = null;
      var locationValue = null;
      if (this.locationType) {
        locationType = this.locationType.type;
        if (locationType == "region") {
          locationValue = this.locationRegion.type;
        } else if (locationType == "state") {
          locationValue = this.locationState.type;
        } else if (locationType == "city") {
          //TODO - problema com a convencao do dashboard!
           // os paineis que usam o id da cidade devem usar o campo city_id para evitar ptoblemas
          locationValue = { name: this.locationCity.id, state: this.locationCity.state };
          if (!_.isNil(this.locationCity.city_id)) {
            locationValue.city_id = this.locationCity.city_id;
          }
        } else if (locationType == "campus") {
          locationValue = this.locationCampus.id;
        }
      }

      let returnMap = {
        initialDate,
        finalDate,
        baseFilters,
        locationType,
        locationValue,
        productLineSelectionType: this.productLineSelectionType
      };

      if (this.productLineSelectionType == 'kind_and_level' || this.productLineOptions.length == 0) {
        returnMap.kinds = this.filterKinds;
        returnMap.levels = this.filterLevels;
      } else {
        returnMap.kinds = [];
        returnMap.levels = [];
      }
      if (this.productLineSelectionType == 'product_line') {
        returnMap.productLine =  this.filterProductLine;
      }
      return returnMap;
    },
  },
}
</script>
