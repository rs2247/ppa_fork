<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Campanha do Farm
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

    </div>

    <div class="row">
      <!-- div class="transparent-loader" v-if="loadingFilters || dataLoading">
        <div class="loader"></div>
      </div -->

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="">CARTEIRA</label>
                  <multiselect v-model="accountTypeFilter" :options="accountTypeOptions" label="name" track-by="id" placeholder="Todas as carteira" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="filterValueSelected" @remove="filterValueRemoved"></multiselect>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row" v-if="hasData">
      <div class="col-md-4">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VARIAÇÃO DE VELOCÍMETRO DE ESTOQUE PROFUNDO</div>
          <div class="row">
            <!-- <div class="transparent-loader" v-if="loadingStockData">
              <div class="loader"></div>
            </div> -->
          </div>
          <div class="panel-body no-lat-padding" style="min-height: 500px;">
            <table id="stock-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>FARMER</th>
                  <th>CARTEIRA</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.key_account }}</td>
                  <td>C{{ entry.carteira }}</td>
                  <td>{{ entry.crescimento_estoque_profundo }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>


      <div class="col-md-4">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VARIAÇÃO DE VELOCÍMETRO</div>

          <div class="row">
            <!-- <div class="transparent-loader" v-if="loadingStockData">
              <div class="loader"></div>
            </div> -->
          </div>
          <div class="panel-body no-lat-padding" style="min-height: 500px;">
            <table id="velocimeter-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>FARMER</th>
                  <th>CARTEIRA</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.key_account }}</td>
                  <td>C{{ entry.carteira }}</td>
                  <td>{{ entry.crescimento_velocimetro }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-md-4">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">VELOCÍMETRO ATUAL</div>

          <div class="row">
            <!-- <div class="transparent-loader" v-if="loadingVelocimeter">
              <div class="loader"></div>
            </div> -->
          </div>

          <div class="panel-body no-lat-padding" style="min-height: 500px;">
            <table id="current-velocimeter-table" class="data-table sticky-header data-table-tiny">
              <thead id="table-header">
                <tr>
                  <th>FARMER</th>
                  <th>CARTEIRA</th>
                  <th>(%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in velocimeterTableData">
                  <td>{{ entry.key_account }}</td>
                  <td>C{{ entry.account_type }}</td>
                  <td>{{ entry.speed }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- div class="row" v-if="hasData">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="ranking-table" class="data-table sticky-header">
              <thead id="table-header">
                <tr>
                  <th>FARMER</th>
                  <th>CARTEIRA</th>
                  <th>VARIACAO VELOCIMETRO (diferença de %)</th>
                  <th>VARIACAO ESTOQUE PROFUNDO (crescimento  %)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entry in tableData">
                  <td>{{ entry.key_account }}</td>
                  <td>C{{ entry.carteira }}</td>
                  <td>{{ entry.crescimento_velocimetro }}</td>
                  <td>{{ entry.crescimento_estoque_profundo }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div -->
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
      loadingStockData: true,
      tableData: [],
      velocimeterTableData: [],
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
    FarmCampaignChannel.on('filters', (payload) => this.receiveFilters(payload));
    FarmCampaignChannel.on('tableData', (payload) => this.receiveTableData(payload));
    FarmCampaignChannel.on('velocimeterTableData', (payload) => this.receiveVelocimeterTableData(payload));

    this.loadData();
  },
  computed: {
    hasData() {
      return this.tableData.length > 0 || this.velocimeterTableData.length > 0;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 0;
    },
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
      this.loading = this.loadingVelocimeter;

      this.$nextTick(() => {
        this.table = new DataTable('#stock-table', {
          paging: true,
          deferRender: true,
          pageLength: 20,
          searching: false,
          order: [ 2, 'desc' ],
          buttons: [],
        });

        this.table = new DataTable('#velocimeter-table', {
          paging: true,
          deferRender: true,
          searching: false,
          pageLength: 20,
          order: [ 2, 'desc' ],
          buttons: [],
        });
      });
    },
    receiveVelocimeterTableData(data) {
      console.log("receiveVelocimeterTableData");

      this.velocimeterTableData = data.ranking;
      this.loadingVelocimeter = false;
      this.loading = this.loadingStockData;

      this.$nextTick(() => {
        this.table = new DataTable('#current-velocimeter-table', {
          paging: true,
          deferRender: true,
          pageLength: 20,
          searching: false,
          order: [ 2, 'desc' ],
          buttons: [],
        });
      });
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
      FarmCampaignChannel.push('loadData', params).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
  },
};

</script>
