<template>
  <div class="container-fluid" style="position: relative;">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Velocímetro QueroPago
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-4 col-sm-12 default-margin-top">
        <label>VISUALIZAÇÃO</label>
        <div style="margin-left: 10px;">
          <input type="radio" name="kind" value="ies" v-model="visualizationType">
          <span style="font-size: 16px;" class="tiny-padding-left">Por IES</span>
          <input type="radio" name="kind" value="product_line" style="margin-left: 10px;" checked v-model="visualizationType">
          <span style="font-size: 16px;" class="tiny-padding-left">Por linha de produto</span>
        </div>
      </div>

      <div class="col-md-8 col-sm-12 default-margin-top" v-if="hasProductLineOptions">
        <div style="float: right; margin-top: -10px">
          <label>LINHA DE PRODUTO</label>
          <multiselect v-model="productLineOption" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
        </div>
      </div>
    </div>

    <div class="row" v-if="hasData">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="report-table" class="data-table sticky-header">
              <thead id="table-header">
                <tr>
                  <th>IES ID</th>
                  <th>IES</th>
                  <th>Carteira</th>
                  <th>Vendas Semestre</th>
                  <th>Vendas sem QAP</th>
                  <th>Vendas com QAP</th>
                  <th>Matrículados QAP</th>
                  <th>Taxa matrícula QAP</th>
                  <th>
                    <p style="display: flex;">
                      Meta móvel
                      <span style="padding-left: 10px;" class="glyphicon glyphicon-info-sign tooltip__icon">
                        <div class="tooltip__content">
                          <span>
                            Meta móvel com base na meta prometida. <br>Quando não existe meta prometida a meta projetada é utilizada.
                          </span>
                        </div>
                      </span>
                    </p>
                  </th>
                  <th>Meta projetada</th>
                  <th>Meta prometida</th>
                  <th>
                    <p style="display: flex;">
                      Velocímetro
                      <span style="padding-left: 10px;" class="glyphicon glyphicon-info-sign tooltip__icon">
                        <div class="tooltip__content">
                          <span>
                            Velocímetro com base na meta prometida. <br>Quando não existe meta prometida a meta projetada é utilizada.
                          </span>
                        </div>
                      </span>
                    </p>
                  </th>
                  <th>
                    <p style="display: flex;">
                      Velocímetro QAP
                      <span style="padding-left: 10px;" class="glyphicon glyphicon-info-sign tooltip__icon">
                        <div class="tooltip__content">
                          <span>
                            Velocímetro levando em conta apenas <br>o período que a IES estava no produto.
                          </span>
                        </div>
                      </span>
                    </p>
                  </th>
                  <th>Meta móvel QAP</th>
                  <th>Data de inicio</th>
                  <th>Data de inicio R</th>
                  <th>Linhas de produto</th>
                </tr>
              </thead>
              <tbody>
                  <tr v-for="university in tableData">
                    <td>{{ university.university_id }}</td>
                    <td>{{ university.university_name }}</td>
                    <td>C{{ university.account_type }}</td>
                    <td>{{ university.full_count }}</td>
                    <td>{{ university.not_qap_count }}</td>
                    <td>{{ university.qap_count }}</td>
                    <td>{{ university.qap_enrolled_count }}</td>
                    <td>{{ university.qap_enrolled_rate }}%</td>
                    <td>{{ university.projecao_movel }}</td>
                    <td>{{ university.adjusted_projection }}</td>
                    <td>
                      {{ university.promisse }}
                      <!-- div class="transparent-loader" v-if="loagindPromisseFor(university.university_id)">
                        <div class="loader"></div>
                      </div>
                      <template v-if="editPromisseFor(university.university_id)">
                        <input type="text" size="10" style="color: #000000" v-model="promisseInput">
                        <span style="padding-left: 10px; color: #00ff00;" class="glyphicon glyphicon-ok-sign tooltip__icon" @click="editPromisse(university.university_id)">&nbsp;</span>
                        <span style="padding-left: 10px; color: #ff0000;" class="glyphicon glyphicon-remove tooltip__icon" @click="closePromisseEdit">&nbsp;</span>
                      </template>
                      <template v-else>
                        {{ university.promisse }}
                        <span v-if="canEditPromisses" style="padding-left: 10px; " class="glyphicon glyphicon-pencil tooltip__icon" @click="showPromisseEdit(university.university_id, university.promisse)" title="Editar meta prometida">&nbsp;</span>
                      </template -->
                    </td>
                    <td>{{ university.velocimetro }}%</td>
                    <td>{{ university.velocimetro_qap }}%</td>
                    <td>{{ university.meta_movel_qap }}</td>
                    <td>{{ university.billing_start }}</td>
                    <td>{{ university.billing_start_raw }}</td>
                    <td>
                      <p v-for="productLine in university.product_lines">
                        {{ productLine }}
                      </p>
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
import GaugeChart from "../js/components/gauge-chart";
import SolidGaugeChart from "../js/components/solid-gauge-chart";
import DataTable from "../js/components/datatable";
import Multiselect from 'vue-multiselect'

export default {
  data() {
    return {
      loading: true,
      tableData: [],
      table: null,
      currentEditingPromisse: null,
      promisseInput: null,
      promisseLoading: false,
      //canEditPromisses: false,
      visualizationType: 'ies',
      productLineOptions: [],
      visualizationOptions: [
        { name: 'Por IES', type: 'ies' },
        { name: 'Por linha de produto', type: 'product_line' },
      ],
      visualization: null,
      initialized: false,
      productLineOption: null,
    }
  },
  components: {
    Multiselect,
  },
  watch: {
    visualizationType: function(value) {
      this.loadData();
    },
    productLineOption: function (value) {
      if (!this.initialized) {
        return;
      }
      this.loadData();
    },
  },
  mounted() {
    this.visualization = this.visualizationOptions[0];

    BillingChannel.on('filters', (payload) => this.receiveFilters(payload));
    BillingChannel.on('tableData', (payload) => this.receiveTableData(payload));

    //BillingChannel.on('promisseEdit', (payload) => this.receivePromisseEdit(payload));

    this.loadFilters();
    //this.loadData();
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 0;
    },
  },
  methods: {
    visualizationTypeInput(data) {
      this.visualizationType = this.visualization.type;
      this.$nextTick(() => {
        this.loadData();
      });
    },
    // editPromisse(universityId) {
    //   if (_.isNil(this.promisseInput) || this.promisseInput == '') {
    //     alert('Insira um valor');
    //     return;
    //   }
    //   console.log("editPromisse# universityId: " + universityId + " promisseInput: " + this.promisseInput);
    //   this.promisseLoading = true;
    //   let params = { university_id: universityId, promisse: this.promisseInput }
    //   BillingChannel.push('editPromisse', params).receive('timeout', (data) => {
    //     console.log("loadData timeout");
    //   });
    // },
    // closePromisseEdit() {
    //   this.currentEditingPromisse = null;
    // },
    // loagindPromisseFor(universityId) {
    //   return this.currentEditingPromisse == universityId && this.promisseLoading;
    // },
    // editPromisseFor(universityId) {
    //   return this.currentEditingPromisse == universityId;
    // },
    // showPromisseEdit(id, currentInput) {
    //   console.log("edit promisse id: " + id);
    //   this.currentEditingPromisse = id;
    //   this.promisseInput = currentInput;
    // },
    // receivePromisseEdit(data) {
    //   console.log("receivePromisseEdit");
    //   this.promisseLoading = false;
    //   this.currentEditingPromisse = null;
    //
    //   this.loadData();
    // },
    receiveFilters(data) {
      this.productLineOptions = data.product_lines;
      if (!_.isNil(data.current_product_line)) {
        let filteredOptions = _.filter(this.productLineOptions, (entry) => {
          return entry.id === data.current_product_line;
        })
        this.productLineOption = filteredOptions[0];
      }

      this.$nextTick(() => {
        this.initialized = true;
        this.loadData();
      });
    },
    receiveTableData(data) {
      console.log("receiveTableData");

      //this.canEditPromisses = data.editPromisses;
      this.tableData = data.universities;
      this.loading = false;

      this.$nextTick(() => {
        this.table = new DataTable('#report-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 11, 'desc' ],
          columnDefs: [
            { orderData: [ 15 ], targets: [ 14 ] },
            { targets: [ 15 ], visible: false, searchable: false },
          ],
        });
      });
    },
    loadFilters() {
      BillingChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      this.tableData = [];
      this.loading = true;
      let params = {
        type: this.visualizationType,
      };
      if (!_.isNil(this.productLineOption)) {
        params.product_line_id = this.productLineOption.id;
      }
      BillingChannel.push('loadData', params).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
  },
};

</script>
