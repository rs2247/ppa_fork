<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Farm Ranking
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>
    </div>

    <div class="row" v-if="tableData.length > 0">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="report-table" class="data-table sticky-header">
              <thead id="table-header">
                <tr>
                  <th>Farmer</th>
                  <th>Carteira</th>
                  <th>Velocimetro</th>
                  <th>Velocimetro - 100%</th>
                  <th>Media do time [Velocimentro - 100%]</th>
                  <th>(Velocimetro - 100%) - (Media do time)</th>
                  <th>Nível Serviço</th>
                  <th>Nível Serviço - 80%</th>
                  <th>Media do time [Nível Serviço - 80%]</th>
                  <th>(Nível Serviço - 80%) - (Media do time)</th>
                  <th>Métrica velocimetro</th>
                  <th class="exclude">&nbsp;</th>
                  <th class="exclude">&nbsp;</th>
                  <th>Métrica nivel serviço</th>
                  <th class="exclude">&nbsp;</th>
                  <th class="exclude">&nbsp;</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.farmer }}</td>
                  <td>C{{ entry.account_type }}</td>
                  <td>{{ entry.speed }}</td>
                  <td>{{ entry.speed_to_ref }}</td>
                  <td>{{ entry.team_speed_to_ref_mean }}</td>
                  <td>{{ entry.speed_to_team }}</td>
                  <td>{{ entry.service_level }}</td>
                  <td>{{ entry.service_level_to_ref }}</td>
                  <td>{{ entry.team_service_level_to_ref_mean }}</td>
                  <td>{{ entry.service_level_to_team }}</td>
                  <td>{{ entry.speed_metric }}</td>
                  <td style="padding: 0px !important;">
                    <template v-if="entry.speed_metric_float < 0">
                      <div :style="gradientStyle(entry.speed_metric_float)" class="red-gradient"></div>
                    </template>
                  </td>
                  <td style="padding: 0px !important;">
                    <template v-if="entry.speed_metric_float >= 0">
                      <div :style="gradientStyle(entry.speed_metric_float)" class="blue-gradient"></div>
                    </template>
                  </td>
                  <td>{{ entry.service_level_metric }}</td>
                  <td style="padding: 0px !important;">
                    <template v-if="entry.service_level_metric_float < 0">
                      <div :style="gradientStyle(entry.service_level_metric_float)" class="red-gradient"></div>
                    </template>
                  </td>
                  <td style="padding: 0px !important;">
                    <template v-if="entry.service_level_metric_float >= 0">
                      <div :style="gradientStyle(entry.service_level_metric_float)" class="blue-gradient"></div>
                    </template>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import DataTable from "../js/components/datatable";
import Multiselect from 'vue-multiselect'
import LocationFilter from './location-filter';
import CsMultiselect from './custom-search-multiselect'

export default {
  data() {
    return {
      loading: true,
      tableData: [],
      table: null,
    }
  },
  mounted() {
    FarmRankingChannel.on('tableData', (payload) => this.receiveTableData(payload));

    this.loadData();
  },
  components: {
    Multiselect,
    LocationFilter,
    CsMultiselect,
  },
  methods: {
    gradientStyle(value) {
      let formattedValue = Math.abs(Math.round(value));
      let styleValue = `height: 40px; width: ${formattedValue}px;`
      if (value < 0) {
         styleValue = styleValue + 'float: right;'
      }
      console.log("styleValue: " + styleValue);
      return styleValue;
    },
    receiveTableData(data) {
      console.log("receiveTableData");

      this.tableData = data.farmers;
      this.loading = false;

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          paging: false,
          deferRender: true,
          searchDelay: 500,
          order: [ 10, 'desc' ],
          columnDefs: [ {
            targets: [11, 12, 14, 15],
            orderable: false
          } ],
        });
      });
    },
    loadData() {
      this.tableData = [];
      FarmRankingChannel.push('loadData').receive('timeout', (data) => {
        console.log('load timeout');
      });
    },
  },
};

</script>
