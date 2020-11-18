<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          CPFS
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loadingFilters || dataLoading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">



            <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" :deal-owner-options="dealOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>

            <div class="row">
              <div class="col-md-3 col-sm-6">
                <div class="">
                  <label for="date">PERÍODO</label>
                  <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
                </div>
              </div>
            </div>

            <!-- div class="row">
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
            </div -->

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadData">
                    Atualizar
                  </button>

                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>


    <div class="row">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            CPFS BLOQUEADOS <span v-if="blockCount">- {{ blockCount }}</span>
          </div>

          <div class="row" v-if="hasData">
            <div class="col-md-12">

              <table id="cpfs-table" class="data-table data-table-tiny">
                <thead>
                  <tr>
                    <th>CPF</th>
                    <th>Nome</th>
                    <th>Curso</th>
                    <th>Desconto</th>
                    <th>Campus</th>
                    <th>Turno</th>
                    <th>Modalidade</th>
                    <th>Nível</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td class="no-wrap"><a target="_blank" :href="'https://vendas.querobolsa.com.br/#/user/' + entry.base_user_id">{{ entry.cpf }}</a></td>
                    <td>{{ entry.user_name }}</td>
                    <td>{{ entry.course_name }}</td>
                    <td>{{ entry.discount_percentage }}</td>
                    <td>{{ entry.campus_name }}</td>
                    <td>{{ entry.shift }}</td>
                    <td>{{ entry.kind }}</td>
                    <td>{{ entry.level }}</td>
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
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import CDatePicker from './custom-date-picker'

export default {
  data() {
    return {
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      kindOptions: [],
      levelOptions: [],
      blockCount: null,
      filterKinds: null,
      filterLevels: null,

      dateRange: null,

      tableData: [],
      table: null,

      loadingFilters: true,
      dataLoading: false,
      semesterStart: null,
      semesterEnd: null,

      shortcuts: [
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
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
            this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            this.dateRange = [ moment().subtract(7, 'days').toDate(), new Date() ]
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
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    CDatePicker,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    CpfsChannel.on('filters', (payload) => this.receiveFilters(payload));
    CpfsChannel.on('tableData', (payload) => this.receiveTableData(payload));

    this.loadFilters();
  },
  methods: {
    primaryFilterSelected(data) {
      console.log('receiveFilters data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      //console.log('receiveFilters data: ' + JSON.stringify(data));
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.semesterStart = data.semester_start
      this.semesterEnd = data.semester_end

      this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];



      this.loadingFilters = false;
    },
    receiveTableData(data) {
      console.log("receiveTableData#");
      this.tableData = data.cpf_list;
      this.blockCount = data.n_block;

      this.$nextTick(() => {
        this.table = new DataTable('#cpfs-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
        });
      });

      this.dataLoading = false;
    },
    loadFilters() {
      CpfsChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      this.dataLoading = true;
      this.tableData = [];
      this.blockCount = null;
      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      let filter = this.$refs.filter.filterSelected();
      filter.initialDate = initialDate;
      filter.finalDate = finalDate;

      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;

      CpfsChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
