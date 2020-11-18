<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">Universidades - Meta móvel atualizada em: {{ lastDate }}</h2>
      </div>
    </div>
    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <div style="float: right; margin-top: -10px" v-if="hasProductLineOptions">
              <label>LINHA DE PRODUTO</label>
              <multiselect v-model="productLineFilter" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
            </div>
            <div v-if="hasData">
              <table id="report-table" class="data-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Universidade</th>
                    <th>Grupo</th>
                    <th>Carteira</th>
                    <th>Farm</th>
                    <th>Qualidade</th>
                    <th>Meta semestre (R$)</th>
                    <th>Meta móvel (R$)</th>
                    <th>Realizado QAP (R$)</th>

                    <th>QAP Speed (%)</th>
                    <th>Speed (%)</th>
                    <th>Realizado (R$)</th>
                    <th>Tipo</th>
                    <th>Situação</th>
                    <th>Atratividade</th>
                    <th>Sucesso</th>
                    <th>Faturamento por ordem R$</th>
                    <th>Visitas em ofertas</th>
                    <th>Orders iniciadas</th>
                    <th>Orders pagas</th>
                    <th>Conversão</th>
                    <th>Trocas</th>
                    <th>QAP Speed 1d (%)</th>
                    <th>QAP Speed 7d (%)</th>
                  </tr>
                </thead>
                <tbody>
                    <tr v-for="entry in tableData">
                      <td>{{ entry.university_id }}</td>
                      <td>{{ entry.university_name }}</td>
                      <td>{{ entry.education_group_name }}</td>
                      <td>C{{ entry.account_type }}</td>
                      <td>{{ entry.owner }}</td>
                      <td>{{ entry.quality_owner }}</td>
                      <td>{{ entry.semester_goal_formatted }}</span></td>
                      <td>{{ entry.mobile_goal_formatted }}</span></td>
                      <td>{{ entry.realized_formatted }}</span></td>
                      <td>{{ entry.speed }}</td>
                      <td>{{ entry.legacy_speed }}</td>
                      <td>{{ entry.legacy_realized_formatted }}</span></td>
                      <td><template v-if="entry.partner_plus">QB+</template><template v-else>Simples</template><template v-if="entry.billing"> - QAP</template><template v-else></template></td>
                      <td>{{ entry.status }}</td>
                      <td>{{ entry.new_orders_per_visits }}%</td>
                      <td>{{ entry.paid_per_new_orders }}%</td>
                      <td>{{ entry.mean_income }}</td>
                      <td>{{ entry.visits }}</td>
                      <td>{{ entry.initiated_orders }}</td>
                      <td>{{ entry.paid_orders }}</td>
                      <td>{{ entry.paid_orders_per_visits }}%</td>
                      <td>{{ entry.exchangeds }}</td>
                      <td>{{ entry.last_day_velocity }}%</td>
                      <td>{{ entry.last_week_velocity }}%</td>
                    </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'

import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import CDatePicker from './custom-date-picker'
import ModalDialog from './modal-dialog'
import MessageDialog from "../js/components/message-dialog";
import LocationFilter from './location-filter';


import ComparingChart from './comparing-chart'
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import DataTable from "../js/components/datatable";

export default {
  data() {
    return {
      lastDate: null,
      tableData: [],
      loading: true,
      productLineFilter: null,
      productLineOptions: [],
      hasData: false,
      initialized: false,
    }
  },
  components: {
    Multiselect,
  },
  computed: {
    hasProductLineOptions() {
      return this.productLineOptions.length > 1;
    },
  },
  mounted() {
    FarmUniversitiesChannel.on('universitiesData', (payload) => this.receiveTableData(payload));
    FarmUniversitiesChannel.on('filterData', (payload) => this.receiveFilters(payload));
    console.log("mounted");

    this.loadFilters();
  },
  watch: {
    productLineFilter: function(value) {
      if (!this.initialized) {
        return;
      }
      this.loadData();
    }
  },
  methods: {
    receiveTableData(data) {
      this.tableData = data.universities_data;
      this.lastDate = data.last_date;
      this.loading = false;
      this.hasData = true;

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 8, 'desc' ]
        });
      });
    },
    receiveFilters(data) {
      this.productLineOptions = data.product_lines;

      if (!_.isNil(data.current_product_line)) {
        let filteredOptions = _.filter(this.productLineOptions, (entry) => {
          return entry.id === data.current_product_line;
        })
        this.productLineFilter = filteredOptions[0];
      }

      this.$nextTick(() => {
        this.initialized = true;
        this.loadData();
      });
    },
    loadFilters() {
      FarmUniversitiesChannel.push('loadFilters').receive('timeout', () => {
        console.log("loadFilter timeout");
      });
    },
    loadData() {
      let params = {};
      if (!_.isNil(this.productLineFilter)) {
        params.productLine = this.productLineFilter.id;
      }
      this.loading = true;
      this.hasData = false;
      FarmUniversitiesChannel.push('load', params).receive('timeout', () => {
        console.log("load timeout");
      });
    },
  }
}
</script>
