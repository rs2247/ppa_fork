<template>
  <multiselect
    v-model="selectedValue"
    :internal-search="false"
    :options="sugestions"
    :label="label"
    @select="valueSelected"
    @remove="valueRemoved"
    @search-change="customSearch"
    :placeholder="placeholder"
    :selectLabel="selectLabel"
    :deselectLabel="deselectLabel"
    :selectedLabel="selectedLabel"
    :multiple="multiple"
    :track-by="trackBy"></multiselect>
</template>

<script>
import Multiselect from 'vue-multiselect'

export default {
  data() {
    return {
      selectedValue: null,
      sugestions: [],
    }
  },
  components: {
    Multiselect,
  },
  props: ['value','options','label','placeholder','selectLabel','deselectLabel','selectedLabel','multiple','trackBy'],
  watch: {
    options: function (value) {
      this.sugestions = this.options;
    },
    value: function (value) {
      this.selectedValue = value;
    }
  },
  mounted() {
    this.sugestions = this.options;
  },
  methods: {
    valueSelected(data) {
      this.$nextTick(() => {
        this.$emit('select', this.selectedValue);
        this.$emit('input', this.selectedValue);
      });
    },
    valueRemoved() {
      this.$nextTick(() => {
        this.$emit('remove');
        this.$emit('input', this.selectedValue);
      });
    },
    customSearch(data, id) {
      if (data == '') {
        this.sugestions = this.options;
        return;
      }
      let filteredData = data.normalize('NFD').replace(/[\u0300-\u036f]/g, "");
      this.sugestions = this.options.filter(function(item_data) {
        return item_data.name.normalize('NFD').replace(/[\u0300-\u036f]/g, "").toUpperCase().includes(filteredData.toUpperCase());
      });
    },
  },
}
</script>
