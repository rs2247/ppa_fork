<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Planilha da campanha de precificação
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
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" label="name" track-by="id" placeholder="Selecione o nível" selectLabel="" deselectLabel="" @input="levelValueSelected"></multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">

                  <button class="btn-submit" @click="loadData">
                    Visualizar
                  </button>

                  <button class="btn-submit default-margin-left" @click="downloadData">
                    Baixar planilha
                  </button>

                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row" v-if="hasTableNoData">
      <p>Sem dados para o filtro selecionado</p>
    </div>

    <div class="row" v-if="hasTableData">
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <table id="pricing-table" class="data-table data-table-tiny">
              <thead>
                <tr>
                  <th v-for="field in fieldsOrder">
                    {{ fieldsMap[field] }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td v-for="field in fieldsOrder">
                    {{ entry[field] }}
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
      enabledFilter: true,
      visibleFilter: false,
      restrictedFilter: false,


      loadingFilters: true,
      dataLoading: false,
      semesterStart: null,
      semesterEnd: null,
      downloadFrame: 'about:blank',
      hasTableNoData: false,

      fieldsMap: {},
      fieldsOrder: [],

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
    hasTableData() {
      return this.tableData.length > 0;
    }
  },
  mounted() {
    PricingCampaignChannel.on('filters', (payload) => this.receiveFilters(payload));
    PricingCampaignChannel.on('tableData', (payload) => this.receiveTableData(payload));
    PricingCampaignChannel.on('downloadData', (payload) => this.receiveDownloadData(payload));
    PricingCampaignChannel.on('downloadNoData', (payload) => this.receiveDownloadNoData(payload));

    this.filterLevels = this.levelOptions[0];

    this.loadFilters();
  },
  methods: {
    //TODO - type?
    formatBool(value) {
      if (_.isNil(value)) {
        return "";
      }
      if (value) {
        return "Sim";
      }
      return "Não";
    },
    primaryFilterSelected(data) {
      console.log('receiveFilters data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      //console.log('receiveFilters data: ' + JSON.stringify(data));
      this.universityGroupOptions = data.groups;
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.levelOptions = data.levels;

      this.filterLevels = this.levelOptions[0];

      this.loadingFilters = false;
    },
    receiveDownloadNoData(data) {
      alert("Sem dados para o filtro selecionado");
      this.dataLoading = false;
    },
    receiveTableData(data) {
      this.fieldsOrder = data.fields;
      this.fieldsMap = data.fields_map;
      this.tableData = data.offers;

      console.log("fieldsOrder: " + JSON.stringify(this.fieldsOrder));
      console.log("fieldsMap: " + JSON.stringify(this.fieldsMap));

      if (this.tableData.length == 0) {
        this.hasTableNoData = true;
      } else {
        this.$nextTick(() => {
          this.table = new DataTable('#pricing-table', {
            paging: true,
            deferRender: true,
            searchDelay: 500,
            pageLength: 30,
            buttons: [],
          });
        });
      }

      this.dataLoading = false;
    },
    receiveDownloadData(data) {
      const byteCharacters = atob(data.xlsx);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], {type: data.contentType});

      saveAs(blob, data.filename);

      this.dataLoading = false;
    },
    loadFilters() {
      PricingCampaignChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    downloadData() {
      if (!this.validateFilter()) {
        return;
      }
      let filter = this.$refs.filter.filterSelected();

      this.dataLoading = true;
      filter.level = this.filterLevels.id;

      PricingCampaignChannel.push('downloadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
    toQueryString(input, fieldSufix) {
      return Object.keys(input).map((key) => {
        if (typeof(input[key]) == 'object') {
          return this.toQueryString(input[key], key);
        } else {
          if (!_.isNil(fieldSufix)) {
            return fieldSufix + '[' + key + ']' + '=' + input[key];
          } else {
            return key + '=' + input[key];
          }
        }
      }).join('&');
    },
    validateFilter() {
      let filter = this.$refs.filter.filterSelected();
      if (_.isNil(filter)) {
        alert('Selecione um filtro');
        return false;
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
      if (_.isNil(this.filterLevels) || this.filterLevels == '') {
        alert('Selecione o nível');
        return false;
      }
      return true;
    },
    loadData() {
      if (!this.validateFilter()) {
        console.log("NAO VALIDOU O FILTRO");
        return;
      }
      let filter = this.$refs.filter.filterSelected();

      this.dataLoading = true;
      this.tableData = [];
      this.hasTableNoData = false;

      filter.level = this.filterLevels.id;

      PricingCampaignChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
