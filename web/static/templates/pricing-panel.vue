<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Precificaçao
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
            PRECIFICAÇAO
          </div>

          <div class="row" v-if="hasData">
            <div class="col-md-12">

              <table id="pricing-table" class="data-table data-table-tiny">
                <thead>
                  <tr>
                    <th>Cidade</th>
                    <th>Estado</th>
                    <th>Curso</th>
                    <!-- th>Curso canonico</th -->
                    <!-- th>Modalidade</th>
                    <th>Nivel</th>
                    <th>Turno</th -->
                    <th>Modalidade</th>
                    <th>Nivel</th>
                    <th>Turno</th>
                    <th>Familia</th>
                    <th>Preco cheio (R$)</th>
                    <th>Campus</th>
                    <th>Preco oferecido (R$)</th>
                    <th>ID IES</th>
                    <th>Valor otimo (R$)</th>
                    <th>Desconto otimo (%)</th>
                    <th>Oferta Ativa</th>
                    <th>curva_utilizada</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.canonical_campus_city }}</td>
                    <td>{{ entry.canonical_campus_state }}</td>
                    <td>{{ entry.course_name }}</td>
                    <!-- td>{{ entry.clean_canonical_course_name }}</td -->
                    <!-- td>{{ entry.clean_course_kind }}</td>
                    <td>{{ entry.clean_course_level }}</td>
                    <td>{{ entry.clean_course_shift }}</td -->
                    <td>{{ entry.course_kind }}</td>
                    <td>{{ entry.course_level }}</td>
                    <td>{{ entry.course_shift }}</td>
                    <td>{{ entry.family_old  }}</td>
                    <td>{{ entry.full_price }}</td>
                    <td>{{ entry.name }}</td>
                    <td>{{ entry.offered_price }}</td>
                    <td>{{ entry.university_id }}</td>
                    <td>{{ entry.valor_otimo }}</td>
                    <td>{{ entry.desconto_otimo }}</td>
                    <td>{{ entry.oferta_ativada }}</td>
                    <td>{{ curvesNames[entry.curva_utilizada] }}</td>
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

export default {
  data() {
    return {
      curvesNames: {
        '0': '-',
        '1': 'Curso na IES',
        '2': 'Família na IES',
        '3': 'Curso na região',
        '4': 'Família na região',
        '5': '-'
      },
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      kindOptions: [],
      levelOptions: [],

      filterKinds: null,
      filterLevels: null,

      tableData: [],
      table: null,

      loadingFilters: true,
      dataLoading: false,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    PricingChannel.on('filters', (payload) => this.receiveFilters(payload));
    PricingChannel.on('tableData', (payload) => this.receiveTableData(payload));

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

      this.loadingFilters = false;
    },
    receiveTableData(data) {
      console.log("receiveTableData#");
      this.tableData = data.pricing;

      this.$nextTick(() => {
        this.table = new DataTable('#pricing-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 30,
        });
      });

      this.dataLoading = false;
    },
    loadFilters() {
      PricingChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
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
      return true;
    },
    loadData() {
      if (!this.validateFilter()) {
        return;
      }

      let filter = this.$refs.filter.filterSelected();
      this.dataLoading = true;
      this.tableData = [];

      filter.kinds = this.filterKinds;
      filter.levels = this.filterLevels;

      PricingChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
