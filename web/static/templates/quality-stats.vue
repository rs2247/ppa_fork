<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Estatísticas de tasks do Qualidade
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            Tasks Secretary Pitch por dia
          </div>

          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-12">

                <base-chart :base-height="600" ref="spTasksChart" :export-name="'alunos_perdidos_' + universityName"></base-chart>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            Tasks tratamento por dia
          </div>

          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-12">

                <base-chart :base-height="600" ref="handlingTasksChart" :export-name="'alunos_perdidos_' + universityName"></base-chart>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import _ from 'lodash'
import Multiselect from 'vue-multiselect'
import moment from 'moment';
import CDatePicker from './custom-date-picker'
import CsMultiselect from './custom-search-multiselect';
import DataTable from "../js/components/datatable";
import BaseChart from './base-chart'

export default {
  data() {
    return {
      loading: true,
    }
  },
  components: {
    CDatePicker,
    CsMultiselect,
    Multiselect,
    BaseChart,
  },
  mounted() {
    QualityStatsChannel.on('chartData', (payload) => this.receiveChartData(payload));

    this.loadData();
  },
  methods: {
    loadData() {
      QualityStatsChannel.push('loadData').receive('timeout', () => {
        console.log('load timeout');
      });
    },
    receiveChartData(data) {
      console.log('receiveChartData');
      this.$refs.spTasksChart.setLabels(data.dates);
      this.$refs.spTasksChart.setSeries(0, data.tasks_sp_relacionamento, "Relacionamento");
      this.$refs.spTasksChart.setSeries(1, data.tasks_sp_siteops, "SiteOps");
      this.$refs.spTasksChart.setSeries(2, data.tasks_sp_integracao, "Integracao");
      this.$refs.spTasksChart.setSeries(3, data.tasks_sp_farmer, "Manual");
      this.$refs.spTasksChart.updateChart();

      this.$refs.handlingTasksChart.setLabels(data.dates);
      this.$refs.handlingTasksChart.setSeries(0, data.tasks_tratamento_relacionamento, "Relacionamento");
      this.$refs.handlingTasksChart.setSeries(1, data.tasks_tratamento_siteops, "SiteOps");
      this.$refs.handlingTasksChart.setSeries(2, data.tasks_tratamento_integracao, "Integracao");
      this.$refs.handlingTasksChart.setSeries(3, data.tasks_tratamento_farmer, "Manual");
      this.$refs.handlingTasksChart.updateChart();
    },
  },
};

</script>
