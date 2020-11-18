import { Bar } from 'vue-chartjs';

export default {
  extends: Bar,
  props: ['data', 'options'],
  mounted() {
    this.renderChart(this.data, this.options);
  },
  methods: {
    updateChart() {
      this.$data._chart.destroy();
      this.renderChart(this.data, this.options);
    },
  },
  watch: {
    data: {
      handler(value) {
        this.updateChart();
      }
    },
  },
};
