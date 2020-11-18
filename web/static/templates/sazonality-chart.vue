<template>
  <div>
    <div class="transparent-loader" v-if="loadingSazonality">
      <div class="loader"></div>
    </div>
    <div class="panel">
      <div class="panel-body">
        <span style="color: #c2c9cb; display: flex; justify-content: center;">
          <b>Sazonalidade: </b>
          <span style="padding-left: 5px;">{{ currentPercent }}</span>
          <span class="glyphicon glyphicon-download-alt clickable" style="padding-left: 5px;" @click="exportSazonalityData"></span>
          <template v-if="hasSazonalityOptions">
            <select v-model="sazonalityOption" style="color: #000000; background-color: #ffffff; border-radius: 5px; margin-left: 10px;">
              <template v-for="option in sazonalityOptions">
                 <option :value="option.id">
                   {{ option.name }}
                 </option>
              </template>
            </select>
          </template>
        </span>
        <comparing-chart ref="cumSazonality" :export-link="false" :base-height="150" export-name="sazonalidade_acumulada"></comparing-chart>
        <comparing-chart ref="sazonality" :export-link="false" :base-height="150" export-name="sazonalidade"></comparing-chart>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash';
import moment from 'moment';
import ComparingChart from './comparing-chart';

export default {
  data() {
    return {
      loadingSazonality: true,
      currentPercent: null,
      sazonalityOptions: [],
      sazonalityDates: [],
      rawSazonality: [],
      sazonalityOption: null,
    }
  },
  components: {
    ComparingChart,
  },
  computed: {
    hasSazonalityOptions() {
      return this.sazonalityOptions.length > 0;
    }
  },
  props: ['value'],
  watch: {
    sazonalityOption: function(value) {
      this.$emit('input', value);
    },
  },
  methods: {
    setLoader() {
      this.loadingSazonality = true;
    },
    setCurrentSazonality(data) {
      this.sazonalityDates = data.dates;
      this.rawSazonality = data.raw_daily_contribution;
      this.sazonalityOptions = data.sazonality_options;
      this.sazonalityOption = data.current_sazonality;

      this.currentPercent = data.current_value_cum_contribution;

      this.$refs.cumSazonality.setXTick(false);
      this.$refs.cumSazonality.setYMax(100);
      this.$refs.cumSazonality.setLabels(data.dates);
      this.$refs.cumSazonality.setSeries(0, data.cum_contribution, "Sazonalidade Acumuldada");
      this.$refs.cumSazonality.setSeriesWithOptions(1, data.current_cum_contribution, "Atual", { seriesColor: '#fdc029', fill: true });
      this.$refs.cumSazonality.resetLoader();


      this.$refs.sazonality.setXTick(false);
      this.$refs.sazonality.setYTick(false);
      this.$refs.sazonality.setLabels(data.dates);
      this.$refs.sazonality.setSeries(0, data.daily_contribution, "Sazonalidade");
      this.$refs.sazonality.setSeriesWithOptions(1, data.current_daily_contribution, "Atual", { seriesColor: '#fdc029', fill: true });
      this.$refs.sazonality.resetLoader();

      this.$refs.cumSazonality.updateChart();
      this.$refs.sazonality.updateChart();

      this.$nextTick(() => {
        this.loadingSazonality = false;
      })
    },
    exportSazonalityData() {
      var filename = "sazonalidade" + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
      var content = "Data;Sazonalidade\n"
      _.each(this.sazonalityDates, (item, itemIndex) => {
        content = content + item + ";"
          + this.rawSazonality[itemIndex] + "\n";
      });

      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
  }
}
</script>
