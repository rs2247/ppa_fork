<template>
  <div class="row">
    <div class="col-md-4 col-sm-6">
      <div>
        <label for="">FILTRO</label>
        <multiselect v-model="filterType" :options="filterOptions" label="name" placeholder="Selecione o tipo de filtro" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'university'">
      <div>
        <label for="">UNIVERSIDADE</label>
        <multiselect :internal-search="false" v-model="universityFilter" :options="universitySugestions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" @search-change="universitySearch"></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'universities'">
      <div>
        <label for="">UNIVERSIDADES</label>
        <multiselect :internal-search="false" :multiple="true" v-model="universitiesFilter" :options="universitySugestions" track-by="id" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" @search-change="universitySearch"></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'group'">
      <div>
        <label for="">GRUPO</label>
        <multiselect v-model="universityGroupFilter" :options="universityGroupOptions" label="name" placeholder="Selecione o grupo" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'farm_region'">
      <div>
        <label for="">REGIÃO DO FARM</label>
        <multiselect v-model="farmRegionFilter" :options="farmRegionOptions" label="name" placeholder="Selecione a região" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && (filterType.type == 'deal_owner' || filterType.type == 'deal_owner_ies')">
      <div>
        <label for="">FARMER</label>
        <multiselect v-model="dealOwnerFilter" :options="dealOwnerOptions" label="name" placeholder="Selecione o farmer" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'account_type'">
      <div>
        <label for="">CARTEIRA</label>
        <multiselect v-model="accountTypeFilter" :options="accountTypeOptions" label="name" placeholder="Selecione a carteira" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>

    <div class="col-md-4 col-sm-6" v-if="filterType && (filterType.type == 'quality_owner' || filterType.type == 'quality_owner_ies')">
      <div>
        <label for="">QUALI</label>
        <multiselect v-model="qualityOwnerFilter" :options="qualityOwnerOptions" label="name" placeholder="Selecione o quali" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" ></multiselect>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash';
import Multiselect from 'vue-multiselect';

export default {
  data() {
    return {
      filterType: null,
      universityFilter: '',
      universitiesFilter: [],
      universityGroupFilter: '',
      accountTypeFilter: '',
      dealOwnerFilter: '',
      qualityOwnerFilter: '',
      farmRegionFilter: '',
      universitySugestions: [],
    }
  },
  props: ['filterOptions', 'universityOptions', 'universityGroupOptions', 'dealOwnerOptions', 'accountTypeOptions', 'qualityOwnerOptions', 'permitEmpty', 'farmRegionOptions'],
  components: {
    Multiselect
  },
  mounted() {
    this.universitySugestions = this.universityOptions;
  },
  watch: {
    universityOptions: function (value) {
      this.universitySugestions = this.universityOptions;
    }
  },
  methods: {
    setFilterType(value) {
      this.filterType = value;
    },
    setUniversityFilter(value) {
      this.universityFilter = value;
    },
    setUniversitiesFilter(value) {
      this.universitiesFilter = value;
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
    setQualityOwnerFilter(value) {
      this.qualityOwnerFilter = value;
    },
    setFarmRegionFilter(value) {
      this.farmRegionFilter = value;
    },
    universitySearch(data, id) {
      if (data == '') {
        this.universitySugestions = this.universityOptions;
        return;
      }
      let filteredData = data.normalize('NFD').replace(/[\u0300-\u036f]/g, "");
      this.universitySugestions = this.universityOptions.filter(function(item_data) {
        return item_data.name.normalize('NFD').replace(/[\u0300-\u036f]/g, "").toUpperCase().includes(filteredData.toUpperCase());
      });
    },
    filterValueSelected() {
      this.$nextTick(() => {
        this.$emit("valueSelected");
      });
    },
    filterSelected() {
      //console.log("filterSelected");
      if (_.isNil(this.filterType)) {
        return;
      }
      let currentFilter = _.cloneDeep(this.filterType);
      if (this.filterType.type === 'university') {
        currentFilter.value = this.universityFilter;
      }
      if (this.filterType.type === 'group') {
        currentFilter.value = this.universityGroupFilter;
      }
      if (this.filterType.type === 'deal_owner' || this.filterType.type === 'deal_owner_ies') {
        currentFilter.value = this.dealOwnerFilter;
      }
      if (this.filterType.type === 'account_type') {
        currentFilter.value = this.accountTypeFilter;
      }
      if (this.filterType.type === 'quality_owner' || this.filterType.type === 'quality_owner_ies') {
        currentFilter.value = this.qualityOwnerFilter;
      }
      if (this.filterType.type === 'universities') {
        currentFilter.value = this.universitiesFilter;
      }
      if (this.filterType.type === 'farm_region') {
        currentFilter.value = this.farmRegionFilter;
      }
      //console.log("filterSelected to RETURN: " + JSON.stringify(currentFilter));
      return currentFilter;
    },
    validateFilter() {
      let filter = this.filterSelected();
      if (_.isNil(filter)) {
        if (this.permitEmpty) {
          return true;
        }
        alert('Selecione um filtro');
        return false;
      }

      if (filter.type == 'all') {
        return true;
      }

      var temDimensao = false;
      if (!_.isNil(filter.value)) {
        if (!_.isNil(filter.value.length)) {
          temDimensao = true;
        }
      }

      if (filter.type != '') {
        if (!temDimensao) {
          if (!filter.value) {
            alert(`Selecione o valor para o filtro ${filter.name}`)
            return false;
          } else {
            if (!filter.value.id) {
              alert(`Selecione o valor para o filtro ${filter.name}`)
              return false;
            }
          }
        } else {
          if (filter.value.length == 0) {
            alert(`Selecione o valor para o filtro ${filter.name}`)
            return false;
          }
        }
      }
      return true;
    },
  },
}
</script>
