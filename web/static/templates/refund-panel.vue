<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel de Reembolsos
        </h2>
      </div>
    </div>

    <modal-dialog ref="refundModal" :identification="stock-modal">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h2 class="modal-title">DETALHES DO REEMBOLSO</h2>
      </div>
      <div class="modal-body" v-if="currentRefundData">
        <div class="transparent-loader" v-if="refundDataLoading">
          <div class="loader"></div>
        </div>
        <label>CPF:</label>
        <p>{{ currentRefundData.cpf }}</p>
        <label>OBSERVAÇÔES</label>
        <p>{{ currentRefundData.observations }}</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-submit" data-dismiss="modal">Fechar</button>
      </div>
    </modal-dialog>

    <div class="row">
      <div class="transparent-loader" v-if="loadingFilters || dataLoading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">

            <div class="row">
              <div class="col-md-3 col-sm-6">
                <div class="">
                  <label for="date">PERÍODO</label>
                  <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
                </div>
              </div>

              <div class="col-md-3 col-sm-6">
                <div>
                  <label for="kind-filter">UNIVERSIDADES</label>
                  <multiselect v-model="filterUniversities" :options="universityOptions" :multiple="true" label="name" track-by="id" placeholder="Selecione as universidades" selectLabel="" deselectLabel="" @input="universityValueSelected"></multiselect>
                </div>
              </div>

              <div class="col-md-3 col-sm-6">
                <div>
                  <label for="kind-filter">GRUPOS</label>
                  <multiselect v-model="filterGroups" :options="universityGroupOptions" :multiple="true" label="name" track-by="id" placeholder="Selecione os grupos" selectLabel="" deselectLabel="" @input="universityValueSelected"></multiselect>
                </div>
              </div>
            </div>

            <div class="row">
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

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">STATUS</label>
                  <cs-multiselect v-model="filterStatus" :options="statusOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os status" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <div>
                  <label for="level-filter">MOTIVO</label>
                  <cs-multiselect v-model="filterReason" :options="reasonsOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os motivos" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>

              <div class="col-md-3 col-sm-6">
                <div class="form-text-input">
                  <label for="level-filter">CPF</label>
                  <input placeholder="Filtro por cpf" type="text" v-model="filterCpf" style="color: #647383; padding-left: 10px; height: 40px;" class="multiselect__input" @keyup.enter="loadData">
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


    <div class="row">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            REEMBOLSOS
          </div>

          <div class="row" v-if="hasData">
            <div class="col-md-12">

              <table id="bo-table" class="data-table data-table-tiny data-table-no-wrap">
                <thead>
                  <tr>
                    <th class="no-wrap"><span class="small-padding-right">ID IES</span></th>
                    <th>IES</th>
                    <th>Grupo</th>
                    <th>Carteira</th>
                    <th>Farmer</th>
                    <th>Quali</th>
                    <th>CPF</th>
                    <th>Status</th>
                    <th>Curso</th>
                    <th>Campus</th>
                    <th><span class="small-padding-right">Modalidade</span></th>
                    <th>Nível</th>
                    <th><span class="small-padding-right">Turno</span></th>
                    <th>Motivo</th>
                    <th><span class="small-padding-right">Data de criação da ordem</span></th>
                    <th>Data de criação da ordem R</th>
                    <th><span class="small-padding-right">Data de pagamento da ordem</span></th>
                    <th>Data de pagamento da ordem R</th>
                    <th><span class="small-padding-right">Data de criação</span></th>
                    <th>Data de criação R</th>
                    <th><span class="small-padding-right">Data de atualização</span></th>
                    <th>Data de atualização R</th>
                    <th>Taxa Pré-Matrícula</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData" class="clickable" @click="showRefundModal(entry)">
                    <td>{{ entry.university_id }}</td>
                    <td>{{ entry.university_name }}</td>
                    <td>{{ entry.education_group }}</td>
                    <td>C{{ entry.carteira }}</td>
                    <td>{{ entry.farmer }}</td>
                    <td>{{ entry.quali }}</td>
                    <td class="no-wrap">{{ entry.cpf }}</td>
                    <td>{{ statuses[entry.status] }}</td>
                    <td>{{ entry.course }}</td>
                    <td>{{ entry.campus }}</td>
                    <td>{{ entry.level }}</td>
                    <td>{{ entry.kind }}</td>
                    <td>{{ entry.shift }}</td>
                    <td>{{ entry.reason }}</td>
                    <td>{{ entry.order_created }}</td>
                    <td>{{ entry.order_created_raw }}</td>
                    <td>{{ entry.order_paid }}</td>
                    <td>{{ entry.order_paid_raw }}</td>
                    <td>{{ entry.creation_date }}</td>
                    <td>{{ entry.creation_date_raw }}</td>
                    <td>{{ entry.update_date }}</td>
                    <td>{{ entry.update_date_raw }}</td>
                    <td>{{ entry.coupon_price }}</td>
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
import ModalDialog from './modal-dialog'

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

      dateRange: null,
      filterUniversities: null,
      filterGroups: null,
      shortcuts: [
        {
          text: '<< 6 m',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).subtract(6, 'months').toDate(), moment(this.semesterEnd).subtract(6, 'months') ]
          }
        },
        {
          text: 'Semestre',
          onClick: () => {
            this.dateRange = [ this.semesterStart, this.semesterEnd ]
          }
        },
        {
          text: 'Últimos 30',
          onClick: () => {
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            this.dateRange = [ moment().subtract(7, 'days').toDate(), new Date() ]
          }
        },
        {
          text: '<< 7 d',
          onClick: () => {
            this.dateRange = [ moment(this.dateRange[0]).subtract(7, 'days').toDate(), this.dateRange[0] ]
          }
        },
        {
          text: 'Até hoje',
          onClick: () => {
            this.dateRange = [ this.dateRange[0], moment().toDate() ]
          }
        }
      ],

      statusOptions: [],
      reasonsOptions: [],

      filterKinds: null,
      filterLevels: null,
      filterReason: null,
      filterStatus: null,
      filterCpf: null,

      tableData: [],
      currentRefundData: null,
      table: null,

      loadingFilters: true,
      dataLoading: false,
      refundDataLoading: false,
      semesterEnd: null,
      semesterStart: null,
      statuses: {
        open: 'Novo',
        refund_request_open: 'No financeiro',
        no_contact_email: 'Sem contato',
        reverted: 'Revertido',
        rejected: 'Rejeitado',
        canceled: 'Cancelado'
      },
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    CDatePicker,
    ModalDialog,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    RefundChannel.on('filters', (payload) => this.receiveFilters(payload));
    RefundChannel.on('tableData', (payload) => this.receiveTableData(payload));
    RefundChannel.on('refundData', (payload) => this.receiveRefundData(payload));

    this.loadFilters();
  },
  methods: {
    receiveRefundData(data) {
      this.refundDataLoading = false;
    },
    showRefundModal(refundData) {
      //this.refundDataLoading = true;
      this.currentRefundData = refundData;
      this.$refs.refundModal.show();
      // RefundChannel.push('loadRefundData', { operation_id: refundData.id }).receive('timeout', (data) => {
      //   console.log('refund data timeout');
      // });
    },
    primaryFilterSelected(data) {
      console.log('receiveFilters data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      //console.log('receiveFilters data: ' + JSON.stringify(data));
      this.universityOptions = data.universities;
      this.universityGroupOptions = data.groups
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.semesterStart = data.semester_start;
      this.semesterEnd = data.semester_end;

      this.statusOptions = data.status;
      this.reasonsOptions = data.reasons;

      this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];

      this.loadingFilters = false;
    },
    receiveTableData(data) {
      console.log("receiveTableData#");
      this.tableData = data.bos;

      this.$nextTick(() => {
        this.table = new DataTable('#bo-table', {
          buttons: [
            { extend: 'copy', exportOptions: { columns: ':visible' } },
            { extend: 'excel', exportOptions: { columns: ':visible' } },
          ],
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
          order: [ 16, 'desc' ],
          columnDefs: [
            { orderData: [ 15 ], targets: [ 14 ] },
            { targets: [ 15 ], visible: false, searchable: false },
            { orderData: [ 17 ], targets: [ 16 ] },
            { targets: [ 17 ], visible: false, searchable: false },
            { orderData: [ 19 ], targets: [ 18 ] },
            { targets: [ 19 ], visible: false, searchable: false },
            { orderData: [ 21 ], targets: [ 20 ] },
            { targets: [ 21 ], visible: false, searchable: false },
          ]
        });
      });

      this.dataLoading = false;
    },
    loadFilters() {
      RefundChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      this.dataLoading = true;
      this.tableData = [];

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      let filter = {};
      filter.universities = this.filterUniversities;
      filter.groups = this.filterGroups;
      filter.reasons = this.filterReason;
      filter.status = this.filterStatus;
      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;
      filter.cpf = this.filterCpf;
      filter.initialDate = initialDate;
      filter.finalDate = finalDate;

      RefundChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
