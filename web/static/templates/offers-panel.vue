<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Ofertas
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
                  <label for="date">INÍCIO APÓS</label><br>
                  <c-date-picker :range="false" v-model="dateStart" :shortcuts="shortcuts"></c-date-picker>
                </div>
              </div>

              <!-- div class="col-md-3 col-sm-6">
                <div class="">
                  <label for="date">FIM ENTRE</label>
                  <c-date-picker v-model="dateRangeEnd" :shortcuts="shortcuts"></c-date-picker>
                </div>
              </div -->

              <div class="col-md-1 col-sm-3">
                <div class="default-margin-top">
                  <input type="checkbox" v-model="enabledFilter" style="margin-right: 5px;" checked><label>SOMENTE ATIVADAS</label>
                </div>
              </div>

              <div class="col-md-1 col-sm-3">
                <div class="default-margin-top">
                  <input type="checkbox" v-model="visibleFilter" style="margin-right: 5px;" checked><label>SOMENTE VISÍVEIS</label>
                </div>
              </div>

              <div class="col-md-1 col-sm-3">
                <div class="default-margin-top">
                  <input type="checkbox" v-model="restrictedFilter" style="margin-right: 5px;"><label>RESTRITAS</label>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADE</label>
                  <multiselect v-model="filterKinds" :options="kindOptions" :multiple="true" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEL</label>
                  <multiselect v-model="filterLevels" :options="levelOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">STATUS</label>
                  <multiselect v-model="filterStatus" :options="statusOptions" label="name" track-by="id" placeholder="Todos os status" selectLabel="" deselectLabel="" ></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">SEMESTRE</label>
                  <multiselect v-model="filterSemesters" :options="semesterOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os semestres" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <div class="col-md-1 col-sm-3">
                <div class="default-margin-top">
                  <input type="checkbox" v-model="hideFilter" style="margin-right: 5px;"><label>ESCONDIDAS NA BUSCA</label>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadData">
                    Atualizar
                  </button>

                  <button class="btn-submit default-margin-left" @click="exportData">
                    Exportar
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
            Ofertas
          </div>

          <div class="row" v-if="dataLimit">
            <p style="color: red; font-size: 18px;"><b>O número de ofertas do filtro excede o limite de 5000 linhas. Use a opção de exportar para ter todos os resultados</b></p>
          </div>

          <div class="row" v-if="hasNoData">
            <p><b>Nenhuma oferta encontrada para os filtros selecionados</b></p>
          </div>

          <div class="row" v-if="hasData">
            <div class="col-md-12">

              <table id="offers-table" class="data-table data-table-tiny no-wrap">
                <thead>
                  <tr>
                    <th>ID Curso</th>
                    <th>ID Oferta</th>
                    <th>Curso</th>
                    <th>IES</th>
                    <th>Grupo</th>
                    <th>Nível</th>
                    <th>Modalidade</th>
                    <th>Turno</th>
                    <th>Campus ID</th>
                    <th>Campus</th>
                    <th>Cidade</th>
                    <th>Estado</th>
                    <th>Semestre</th>
                    <th>Ativada</th>
                    <th>Visível</th>
                    <th>Ocultar preços</th>
                    <th>Limitada</th>
                    <th>Restrita</th>
                    <th>Início</th>
                    <th>Fim</th>
                    <th>Desconto</th>
                    <th>Desconto Comercial</th>
                    <th>Desconto Comercial Regressivo</th>
                    <th>Campanha</th>
                    <th>Preço Cheio</th>
                    <th>Preço Oferecido</th>
                    <th>Preços de pré-matrícula</th>
                    <th>Total de Bolsas</th>
                    <th>Pagos</th>
                    <th>Status</th>
                    <th>On Search</th>
                    <th>Position</th>
                    <th>Canal Aberto</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.course_id }}</td>
                    <td>{{ entry.offer_id }}</td>
                    <td>{{ entry.course_name }}</td>
                    <td>{{ entry.university_name }}</td>
                    <td>{{ entry.group_name }}</td>
                    <td>{{ entry.level }}</td>
                    <td>{{ entry.kind }}</td>
                    <td>{{ entry.shift }}</td>
                    <td>{{ entry.campus_id }}</td>
                    <td>{{ entry.campus_name }}</td>
                    <td>{{ entry.campus_city }}</td>
                    <td>{{ entry.campus_state }}</td>
                    <td>{{ entry.semester }}</td>
                    <td>{{ entry.enabled }}</td>
                    <td>{{ entry.visible }}</td>
                    <td>{{ entry.hide_prices }}</td>
                    <td>{{ entry.limited }}</td>
                    <td>{{ entry.restricted }}</td>
                    <td>{{ entry.start_date }}</td>
                    <td>{{ entry.end_date }}</td>
                    <td>{{ entry.discount_percentage }}</td>
                    <td>{{ entry.commercial_discount }}</td>
                    <td>{{ entry.regressive_commercial_discount }}</td>
                    <td>{{ entry.campaign }}</td>
                    <td>{{ entry.full_price }}</td>
                    <td>{{ entry.offered_price }}</td>
                    <td>{{ entry.pre_enrollment_fees }}</td>
                    <td>{{ entry.total_seats }}</td>
                    <td>{{ entry.paid_seats }}</td>
                    <td>{{ entry.status }}</td>
                    <td>{{ entry.show_on_main_search }}</td>
                    <td>{{ entry.position }}</td>
                    <td>{{ entry.open_channel_type }}</td>
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
      semesterOptions: [],
      statusOptions: [ { name: 'Congelada', id: 'frozen' }],
      filterKinds: null,
      filterLevels: null,
      filterStatus: null,
      dataLimit: false,

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
      hasNoData: false,
      filterSemesters: [],

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
    OffersChannel.on('filters', (payload) => this.receiveFilters(payload));
    OffersChannel.on('tableData', (payload) => this.receiveTableData(payload));
    OffersChannel.on('tableDownload', (payload) => this.receiveTableDownload(payload));

    this.loadFilters();
  },
  methods: {
    primaryFilterSelected(data) {
      console.log('receiveFilters data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      //console.log('receiveFilters data: ' + JSON.stringify(data));
      this.universityGroupOptions = data.groups;
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.semesterStart = data.semester_start
      this.semesterEnd = data.semester_end
      this.semesterOptions = data.semester_options
      this.accountTypeOptions = data.accountTypes;
      this.dealOwnerOptions = data.dealOwners;

      //this.dateRangeStart = [ moment(this.semesterStart).subtract(6, 'months').toDate(), moment(this.semesterEnd).toDate() ];
      //this.dateRangeEnd = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];

      //this.dateStart = moment(this.semesterStart).subtract(6, 'months').toDate();

      this.loadingFilters = false;
    },
    receiveTableData(data) {
      console.log("receiveTableData#");
      this.tableData = data.offers;
      if (data.offers.length == 0) {
        this.hasNoData = true;
      }

      this.dataLimit = data.data_limit;

      this.$nextTick(() => {
        this.table = new DataTable('#offers-table', {
          ordering: false,
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
          buttons: [],
        });
      });

      this.dataLoading = false;
    },
    saveXlsx(input, filename, contentType) {
      const byteCharacters = atob(input);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], {type: contentType});

      saveAs(blob, filename);
    },
    receiveTableDownload(data) {
      this.saveXlsx(data.xlsx, data.filename, data.contentType);
      this.dataLoading = false;
    },
    loadFilters() {
      OffersChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    exportData() {
      if (!this.$refs.filter.validateFilter()) {
        return;
      }

      let filter = this.filtersMap();

      if (_.isNil(filter)) {
        alert('Selecione um filtro');
        return;
      }

      this.dataLoading = true;


      OffersChannel.push('exportData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    },
    filtersMap() {
      let filter = this.$refs.filter.filterSelected();
      if (_.isNil(filter)) {
        return;
      }

      filter.dateStart = this.dateStart;

      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;

      filter.status = this.filterStatus;

      filter.enabled = this.enabledFilter;
      filter.restricted = this.restrictedFilter;
      filter.visible = this.visibleFilter;
      filter.hidden = this.hideFilter;
      filter.semesters = this.filterSemesters;

      return filter;
    },
    loadData() {
      if (!this.$refs.filter.validateFilter()) {
        return;
      }

      let filter = this.filtersMap();

      if (_.isNil(filter)) {
        alert('Selecione um filtro');
        return;
      }

      this.dataLoading = true;
      this.tableData = [];
      this.hasNoData = false;
      this.dataLimit = false;

      OffersChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
