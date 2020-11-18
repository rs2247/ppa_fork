<template>
  <div>
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
          <cs-multiselect v-model="filterProductLine" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel=""></cs-multiselect>
        </div>
      </div>
    </template>

    <template v-if="showKindAndLevelSelection">
      <div class="col-md-2 col-sm-6">
        <div>
          <label for="kind-filter">MODALIDADE</label>
          <cs-multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></cs-multiselect>
        </div>
      </div>
      <div class="col-md-2 col-sm-6">
        <div>
          <label for="level-filter">NÍVEL</label>
          <cs-multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></cs-multiselect>
        </div>
      </div>
    </template>
  </div>
</template>

<script>

import CsMultiselect from './custom-search-multiselect';

export default {
  data() {
    return {
      filterKinds: null,
      filterLevels: null,
      filterProductLine: null,
      productLineSelectionType: 'product_line',
    }
  },
  computed: {
    hasProductLineOptions() {
      return this.productLineOptions.length > 0;
    },
    showProductLineSelection() {
      return this.productLineSelectionType == "product_line";
    },
    showKindAndLevelSelection() {
      return this.productLineSelectionType == "kind_and_level" || this.productLineOptions.length == 0;
    },
  },
  components: {
    CsMultiselect,
  },
  props: {
    index: {
      type: Number,
      default: 0
    },
    kindOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    levelOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
    productLineOptions: {
      type: Array,
      default: function () {
        return [];
      }
    },
  },
  methods: {
    setProductLineFilter(value) {
      this.filterProductLine = value;
    },
    filters() {
      let returnMap = {};
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
