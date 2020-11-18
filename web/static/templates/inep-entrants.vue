<template>
  <div class="container-fluid">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Ingressantes INEP
        </h2>
      </div>
    </div>

    <div class="panel report-panel panel-default">
      <div class="row" style="position: relative;">
        <div class="transparent-loader" v-if="loadingFilters || loading">
          <div class="loader"></div>
        </div>

        <div class="col-md-12 col-sm-6">
          <div class="row">
            <div class="col-md-6 col-sm-6">
              <label for="kind-filter">UNIVERSIDADE</label>
              <cs-multiselect v-model="filterUniversity" :options="universityOptions" label="name" track-by="id" placeholder="Selecione a universidade" selectLabel="" deselectLabel=""></cs-multiselect>
            </div>
          </div>

          <div class="row">
            <div class="col-md-4 col-sm-6">
              <div>
                <label for="kind-filter">ESTADO</label>
                <cs-multiselect v-model="filterState" :options="stateOptions" label="name" track-by="type" placeholder="Todos os estados" selectLabel="" deselectLabel=""></cs-multiselect>
              </div>
            </div>
          </div>

          <div class="row">
            <div class="col-md-4 col-sm-6">
              <div>
                <label for="kind-filter">AGRUPAMENTO</label>
                <cs-multiselect v-model="grouping" :options="groupingOptions" label="name" track-by="key" placeholder="Sem agrupamento" selectLabel="" deselectLabel=""></cs-multiselect>
              </div>
            </div>
          </div>

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

    <div class="row" v-if="hasData">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="inep-entrants" class="data-table sticky-header">
              <thead>
                <tr>
                  <th>Ano</th>
                  <th>Ingressantes</th>
                  <th v-if="tableGroupingFieldName">{{ tableGroupingFieldTitle }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.ano_ingresso }}</td>
                  <td>{{ entry.quantidade }}</td>
                  <td v-if="tableGroupingFieldName">{{ entry[tableGroupingFieldName] }}</td>
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
import MessageDialog from "../js/components/message-dialog";
import DataTable from "../js/components/datatable";
import Multiselect from 'vue-multiselect'
import CsMultiselect from './custom-search-multiselect'
import PanelPrimaryFilter from './panel-primary-filter';
import LocationFilter from './location-filter';

export default {
  data() {
    return {
      filterUniversity: null,
      universityOptions: [],
      stateOptions: [],
      filterState: null,
      loadingFilters: true,
      loading: false,
      tableData: [],
      tableGroupingFieldTitle: null,
      tableGroupingFieldName: null,
      grouping: null,
      groupingOptions: [
        {name: 'Modalidade', key: 'kind'},
        {name: 'Estado', key: 'state'},
      ]
    }
  },
  mounted() {
    InepChannel.on('filters', (payload) => this.receiveFilters(payload));
    InepChannel.on('inepEntrants', (payload) => this.receiveTableData(payload));

    this.loadFilters();
  },
  components: {
    Multiselect,
    PanelPrimaryFilter,
    CsMultiselect,
    LocationFilter,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  methods: {
    loadFilters() {
      InepChannel.push('loadFilters').receive('timeout', () => {
        console.log("return timeout");
      });
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.stateOptions = data.states;
      this.loadingFilters = false;
    },
    receiveTableData(data) {
      this.tableData = data.entrants;
      this.tableGroupingFieldTitle = data.grouping_field_title;
      this.tableGroupingFieldName = data.grouping_field_name;
      this.loading = false;
      this.$nextTick(() => {
        this.table = new DataTable('#inep-entrants', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 0, 'asc' ]
        });
      });
    },
    loadData() {
      this.loading = true;
      this.tableData = [];
      let filters = {
        university_id: this.filterUniversity.id,

      };
      if (!_.isNil(this.filterState)) {
          filters.state = this.filterState.type;
      }
      if (!_.isNil(this.grouping)) {
        filters.grouping = this.grouping.key;
      }
      InepChannel.push('loadEntrants', filters).receive('timeout', () => {
        console.log("load timeout");
      });
    },
  }
}
</script>
