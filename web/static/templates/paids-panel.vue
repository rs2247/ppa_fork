<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel de Pagos
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
                  <label for="date">DATA</label>
                  <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
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
                  <label for="kind-filter">SEMESTRE</label>
                  <multiselect v-model="filterSemesters" :options="semesterOptions" :multiple="true" label="name" track-by="id" placeholder="Todos os semestres" selectLabel="" deselectLabel=""></multiselect>
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
            Resultados
          </div>

          <div class="row" v-if="hasData">
            <div class="col-md-12">

              <table id="paids-table" class="data-table data-table-tiny">
                <thead>
                  <tr>
                    <th>Cupom ID</th>
                    <th>Nome</th>
                    <th>CPF</th>
                    <th>Telefone</th>
                    <th>Email</th>
                    <th>Preço</th>
                    <th>Posição no Grupo</th>
                    <th>Preço integral</th>
                    <th>Preço oferecido</th>
                    <th>Porcentagem de desconto Total</th>
                    <th>Porcentagem de desconto Fixo (QB)</th>
                    <th>Porcentagem de desconto Regressivo</th>
                    <th>Porcentagem de desconto Antecipação/Pontualidade</th>
                    <th>enabled_at</th>
                    <th>Nome do curso</th>
                    <th>Modalidade</th>
                    <th>Turno</th>
                    <th>Grau</th>
                    <th>Períodos</th>
                    <th>Tipo de contagem</th>
                    <th>Semestre</th>
                    <th>Nome do Campus</th>
                    <th>Cidade do Campus</th>
                    <th>Estado do Campus</th>
                    <th>Universidade ID</th>
                    <th>Nome da universidade</th>
                    <th>Nome completo universidade</th>
                    <th>Grupo Educacional</th>
                    <th>Situação de integração</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.coupon_id }}</td>
                    <td>{{ entry.coupon_name }}</td>
                    <td>{{ entry.cpf }}</td>
                    <td>{{ entry.telefone }}</td>
                    <td>{{ entry.email }}</td>
                    <td>{{ entry.price }}</td>
                    <td>{{ entry.position }}</td>
                    <td>{{ entry.full_price }}</td>
                    <td>{{ entry.offered_price }}</td>
                    <td>{{ entry.discount_percentage }}</td>
                    <td>{{ entry.fixed_discount_percentage }}</td>
                    <td>{{ entry.regressive_discount }}</td>
                    <td>{{ entry.punctuality_discount_percentage }}</td>
                    <td>{{ entry.enabled_at }}</td>
                    <td>{{ entry.name_course }}</td>
                    <td>{{ entry.kind }}</td>
                    <td>{{ entry.shift }}</td>
                    <td>{{ entry.level }}</td>
                    <td>{{ entry.max_periods }}</td>
                    <td>{{ entry.period_kind }}</td>
                    <td>{{ entry.enrollment_semester }}</td>
                    <td>{{ entry.campus_name }}</td>
                    <td>{{ entry.campus_city }}</td>
                    <td>{{ entry.campus_state }}</td>
                    <td>{{ entry.university_id }}</td>
                    <td>{{ entry.university_name }}</td>
                    <td>{{ entry.university_full_name }}</td>
                    <td>{{ entry.educational_group }}</td>
                    <td>{{ entry.integration_step }}</td>
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
      semesterOptions: [],
      kindOptions: [],
      levelOptions: [],
      blockCount: null,
      filterKinds: null,
      filterLevels: null,
      filterSemesters: [],

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

      shortcuts: [
        {
          text: '<< 6 m',
          onClick: () => {
            this.dateRange = [ moment(this.semesterStart).subtract(6, 'months').toDate(), moment(this.semesterEnd).subtract(6, 'months') ]
            //this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Semestre',
          onClick: () => {
            this.dateRange = [ this.semesterStart, this.semesterEnd ]
            //this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 30',
          onClick: () => {
            this.dateRange = [ moment().subtract(30, 'days').toDate(), new Date() ]
            //this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Últimos 7',
          onClick: () => {
            this.dateRange = [ moment().subtract(7, 'days').toDate(), new Date() ]
            //this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: '<< 7 d',
          onClick: () => {
            this.dateRange = [ moment(this.dateRange[0]).subtract(7, 'days').toDate(), this.dateRange[0] ]
            //this.timeRangeSelected(this.dateRange);
          }
        },
        {
          text: 'Até hoje',
          onClick: () => {
            this.dateRange = [ this.dateRange[0], moment().toDate() ]
            //this.timeRangeSelected(this.dateRange);
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
    PaidsChannel.on('filters', (payload) => this.receiveFilters(payload));
    PaidsChannel.on('tableData', (payload) => this.receiveTableData(payload));

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
      this.semesterOptions = data.semester_options;

      this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];

      this.loadingFilters = false;
    },
    receiveTableData(data) {
      console.log("receiveTableData#");
      this.tableData = data.paids;

      this.$nextTick(() => {
        this.table = new DataTable('#paids-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
        });
      });

      this.dataLoading = false;
    },
    loadFilters() {
      PaidsChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      let filter = this.$refs.filter.filterSelected();
      if (_.isNil(filter)) {
        alert('Selecione um filtro');
        return;
      }
      if (!this.$refs.filter.validateFilter()) {
        return false;
      }
      this.dataLoading = true;
      this.tableData = [];
      this.blockCount = null;
      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      filter.initialDate = initialDate;
      filter.finalDate = finalDate;

      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;
      filter.semesters = this.filterSemesters;

      PaidsChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
