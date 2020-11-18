<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Ranking de busca ( Graduação )
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

            <div class="row">
              <div class="col-md-6 col-sm-6">
                <div>
                  <label for="kind-filter">UNIVERSIDADE</label>
                  <cs-multiselect v-model="filterUniversity" :options="universityOptions" label="name" track-by="id" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" @input="universitySelected"></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">

              <!-- div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @input="levelValueSelected"></multiselect>
                </div>
              </div -->

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">CIDADE</label>
                  <cs-multiselect v-model="filterCity" :alow-empty="false" :options="citiesOptions" label="name" track-by="name" placeholder="Selecione a cidade" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADE</label>
                  <multiselect v-model="filterKinds" :alow-empty="false" :options="kindOptions" label="name" track-by="id" placeholder="Selecione uma modalidade" selectLabel="" deselectLabel="" @input="kindValueSelected"></multiselect>
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
    </div>

    <div class="row" v-show="hasChartData">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            QUANTIDADE DE SKU's x Página rankeada

            <span class="clickable" style="float: right;" @click="exportSkus">
              Exportar SKU's
            </span>

            <p v-if="meanRank">
              Score médio: {{ meanRank }}
            </p>
          </div>
          <base-chart :base-height="600" ref="rankingChart" :export-name="'rankeamento_na_busca'"></base-chart>
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
import LocationFilter from './location-filter';
import BaseChart from './base-chart'

import exportToCsv from "../js/utils/export";

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
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      meanRank: null,

      filterKinds: null,
      filterLevels: null,
      filterCity: null,

      tableData: [],
      table: null,
      hasChartData: false,

      loadingFilters: true,
      dataLoading: false,
      currentFilter: null,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    LocationFilter,
    BaseChart,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    SearchRankingChannel.on('filters', (payload) => this.receiveFilters(payload));
    //SearchRankingChannel.on('tableData', (payload) => this.receiveTableData(payload));
    SearchRankingChannel.on('chartData', (payload) => this.receiveChartData(payload));
    SearchRankingChannel.on('exportData', (payload) => this.receiveExportData(payload));

    SearchRankingChannel.on('citiesFilters', (payload) => this.receiveCitiesFilters(payload));

    this.loadFilters();
  },
  methods: {
    universitySelected() {
      this.completeCities();
      //this.$refs.locationFilter.setCitiesLoader();
    },
    loadCities() {
      //this.$refs.locationFilter.setCitiesLoader();
    },
    loadCampuses() {
      console.log('loadCampuses');
    },
    primaryFilterSelected() {
      //faz o complete de cidade!
      //this.completeCities();
    },
    receiveCitiesFilters(data) {
      this.citiesOptions = data.cities;
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.locationOptions = data.locationTypes;

      this.loadingFilters = false;
    },
    emptyNull(value) {
      if (_.isNil(value)) {
        return "";
      }
      return value;
    },
    receiveExportData(data) {
      this.dataLoading = false;
      console.log("receiveExportData");

      var content = 'rank;pagina;id_curso;curso;cidade;pagos\n';
      _.each(data.skus, (entry, entryIndex) => {
        content = content + entry['rank'] + ';' +
          entry['pagina'] + ';' +
          entry['id_curso'] + ';' +
          entry['curso'] + ';' +
          entry['cidade'] + ';' +
          this.emptyNull(entry['pagos']) + '\n';
      });
      exportToCsv("skus.csv", content);
    },
    receiveChartData(data) {
      console.log("receiveChartData#");

      this.hasChartData = true;
      this.meanRank = data.mean_rank;

      this.$refs.rankingChart.setYBeginAtZero(true);

      this.$refs.rankingChart.setLabels(data.pages);
      this.$refs.rankingChart.setSeries(0, data.counts, "Página");

      this.$nextTick(() => {
        this.$refs.rankingChart.updateChart();
      });

      this.dataLoading = false;
    },
    // receiveTableData(data) {
    //   console.log("receiveTableData#");
    //   this.tableData = data.pricing;
    //
    //   this.$nextTick(() => {
    //     this.table = new DataTable('#pricing-table', {
    //       paging: true,
    //       deferRender: true,
    //       searchDelay: 500,
    //       pageLength: 30,
    //       order: [ 0, 'desc' ]
    //     });
    //   });
    //
    //   this.dataLoading = false;
    // },
    completeCities() {
      //let filter = this.$refs.filter.filterSelected();
      let filter = this.getFilters();
      console.log("filter: " + JSON.stringify(filter));
      if (_.isNil(filter.value) || filter.value == '') {
        this.citiesOptions = [];
        return;
      }

      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;
      SearchRankingChannel.push('completeCities', filter).receive('timeout', (data) => {
        console.log('cities complete timeout');
      });
    },
    loadFilters() {
      SearchRankingChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    exportSkus() {
      this.dataLoading = true;
      SearchRankingChannel.push('exportSkus', this.currentFilter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
    getFilters() {
      if (_.isNil(this.filterUniversity)) {
        return;
      }
      let filters = {
        value: this.filterUniversity
      }
      return filters;
    },
    loadData() {
      //let filter = this.$refs.filter.filterSelected();
      let filter = this.getFilters();
      if (_.isNil(filter) || filter.value == '') {
        alert('Selecione uma IES');
        return;
      }

      if (_.isNil(this.filterCity)) {
        alert('Selecione a cidade');
        return;
      }

      if (_.isNil(this.filterKinds)) {
        alert('Selecione a modalidade');
        return;
      }

      this.meanRank = null;
      this.dataLoading = true;
      this.tableData = [];
      this.$refs.rankingChart.clearSeries();
      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;
      filter.state = this.filterCity.state;
      filter.city = this.filterCity.city;

      this.currentFilter = filter;

      SearchRankingChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
