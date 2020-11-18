<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Campanha do Qualidade
        </h2>
      </div>
    </div>

    <div class="row">
      <!-- div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div -->
    </div>

    <div class="row" >
      <div class="col-md-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VARIAÇÃO PERCENTUAL DO FATURAMENTO POR ORDEM</div>

          <div class="panel-body no-lat-padding" style="min-height: 300px;">
            <table id="fat-ordem-delta-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>QUALI</th>
                  <th>Variação (%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.name }}</td>
                  <td>{{ entry.delta }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VELOCÍMETRO FATURAMENTO POR ORDEM</div>

          <div class="row">
          </div>
          <div class="panel-body no-lat-padding" style="min-height: 300px;">
            <table id="fat-ordem-velocimeter-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>QUALI</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableDataFatOrderVelocimeter">
                  <td>{{ entry.name }}</td>
                  <td>{{ entry.velocimetro_fat_ordem }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VARIAÇAO DO VELOCÍMETRO DE RECEITA</div>

          <div class="row">
          </div>
          <div class="panel-body no-lat-padding" style="min-height: 300px;">
            <table id="delta-velocimeter-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>QUALI</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in velocimeterDeltaTableData">
                  <td>{{ entry.name }}</td>
                  <td>{{ entry.velocimeter_delta }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VELOCÍMETRO RECEITA</div>

          <div class="row">
          </div>
          <div class="panel-body no-lat-padding" style="min-height: 300px;">
            <table id="current-velocimeter-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>QUALI</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in velocimeterTableData">
                  <td>{{ entry.name }}</td>
                  <td>{{ entry.velocimeter }}</td>
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

export default {
  data() {
    return {
      loading: true,
      loadingVelocimeter: true,
      loadingVelocimeterDelta: true,
      loadingFatOrderVelocimeter: true,
      loadingVelocimeterFatOrdem: true,
      tableData: [],
      tableDataFatOrderVelocimeter: [],
      velocimeterTableData: [],
      velocimeterDeltaTableData: [],
      accountTypeFilter: null,
      accountTypeOptions: [
        { name: "Carteira 1" , id: 1 },
        { name: "Carteira 2" , id: 2 },
        { name: "Carteira 3" , id: 3 },
        { name: "Carteira 4" , id: 4 },
      ],
    }
  },
  components: {
    Multiselect,
  },
  mounted() {
    QualiCampaignChannel.on('filters', (payload) => this.receiveFilters(payload));
    QualiCampaignChannel.on('tableData', (payload) => this.receiveTableData(payload));
    QualiCampaignChannel.on('velocimeterTableData', (payload) => this.receiveVelocimeterTableData(payload));

    QualiCampaignChannel.on('velocimeterDeltaTableData', (payload) => this.receiveVelocimeterDeltaTableData(payload));

    QualiCampaignChannel.on('fatOrdemDeltaTableData', (payload) => this.receiveFatOrdemDeltaTableData(payload));


    this.loadData();
  },
  methods: {
    filterValueSelected() {
      //console.log("filterValueSelected");
      this.$nextTick(() => {
        this.loadData();
      });
    },
    filterValueRemoved() {
      //console.log("filterValueRemoved");
      this.$nextTick(() => {
        this.loadData();
      });
    },
    visualizationTypeInput(data) {
      this.visualizationType = this.visualization.type;
      this.$nextTick(() => {
        this.loadData();
      });
    },
    receiveFilters(data) {
      console.log("receiveFilters");
    },
    receiveTableData(data) {
      console.log("receiveTableData");

      this.tableData = data.ranking;
      this.loadingStockData = false;
      //this.loading = this.loadingVelocimeter;
      this.checkLoading();

      this.$nextTick(() => {
        this.table = new DataTable('#fat-ordem-delta-table', {
          //paging: true,
          deferRender: true,
          //pageLength: 20,
          searching: false,
          order: [ 1, 'desc' ],
          buttons: [],
        });
      });
    },
    receiveFatOrdemDeltaTableData(data) {
      this.tableDataFatOrderVelocimeter = data.ranking;
      this.loadingVelocimeterFatOrdem = false;
      //this.loading = this.loadingStockData;
      this.checkLoading();

      this.$nextTick(() => {
        this.table = new DataTable('#fat-ordem-velocimeter-table', {
          //paging: true,
          deferRender: true,
          //pageLength: 20,
          searching: false,
          order: [ 1, 'desc' ],
          buttons: [],
        });
      });
    },
    receiveVelocimeterDeltaTableData(data) {
      this.velocimeterDeltaTableData = data.ranking;
      this.loadingVelocimeterDelta = false;
      //this.loading = this.loadingStockData;
      this.checkLoading();

      this.$nextTick(() => {
        this.table = new DataTable('#delta-velocimeter-table', {
          //paging: true,
          deferRender: true,
          //pageLength: 20,
          searching: false,
          order: [ 1, 'desc' ],
          buttons: [],
        });
      });
    },
    receiveVelocimeterTableData(data) {
      console.log("receiveVelocimeterTableData");

      this.velocimeterTableData = data.ranking;
      this.loadingVelocimeter = false;
      //this.loading = this.loadingStockData;
      //this.loading = false;
      this.checkLoading();

      this.$nextTick(() => {
        this.table = new DataTable('#current-velocimeter-table', {
          //paging: true,
          deferRender: true,
          //pageLength: 20,
          searching: false,
          order: [ 1, 'desc' ],
          buttons: [],
        });
      });
    },
    checkLoading() {
      this.loading = this.loadingVelocimeter || this.loadingVelocimeterDelta || this.loadingVelocimeterFatOrdem || this.loadingStockData;
    },
    loadData() {
      this.tableData = [];
      this.velocimeterTableData = [];
      this.loading = true;
      this.loadingVelocimeter = true;
      this.loadingStockData = true;
      let params = {
        account_type: this.accountTypeFilter
      }
      QualiCampaignChannel.push('loadData', params).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
  },
};

</script>
