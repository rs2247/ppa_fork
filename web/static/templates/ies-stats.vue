<template>
  <div class="container-fluid">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Estatísticas das IES
        </h2>
      </div>
    </div>

    <div class="row" style="position: relative;">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div class="">
                  <label for="date">PERÍODO</label>
                  <c-date-picker v-model="dateRange"></c-date-picker>
                </div>
              </div>

              <product-lines-filter ref="productLineFilter" :kind-options="kindOptions" :level-options="levelOptions" :product-line-options="productLineOptions"></product-lines-filter>


              <!-- <div class="col-md-2 col-sm-6">
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
              </div> -->
            </div>

            <div class="row">
              <div class="col-md-4 col-sm-6">
                <label for="">FILTRO</label>
                <multiselect v-model="filterType" :options="filterOptions" label="name" placeholder="Selecione o tipo de filtro" selectLabel="" deselectLabel="" selectedLabel="Selecionado" :allow-empty="false"></multiselect>
              </div>

              <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'owned_universities'">
                <div>
                  <label for="">UNIVERSIDADE</label>
                  <cs-multiselect v-model="ownedUniversityFilter" :options="ownedUniversityOptions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></cs-multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'university'">
                <div>
                  <label for="">UNIVERSIDADE</label>
                  <cs-multiselect v-model="universityFilter" :options="universityOptions" label="name" placeholder="Selecione a universidade" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></cs-multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'group'">
                <div>
                  <label for="">GRUPO</label>
                  <multiselect v-model="universityGroupFilter" :options="universityGroupOptions" label="name" placeholder="Selecione o grupo" selectLabel="" deselectLabel="" selectedLabel="Selecionado"></multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'account_type'">
                <div>
                  <label for="">CARTEIRA</label>
                  <multiselect v-model="accountTypeFilter" :options="acountTypeOptions" label="name" track-by="id" placeholder="Selecione as carteiras" selectLabel="" deselectLabel="" selectedLabel="Selecionado" :multiple="true"></multiselect>
                </div>
              </div>

              <div class="col-md-4 col-sm-6" v-if="filterType && filterType.type == 'farm_region'">
                <div>
                  <label for="">REGIÃO DO FARM</label>
                  <multiselect v-model="farmRegionFilter" :options="farmRegionOptions" label="name" track-by="id" placeholder="Selecione a regiões" selectLabel="" deselectLabel="" selectedLabel="Selecionado" :multiple="true"></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="update">
                    Atualizar
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row" v-if="tableData.length > 0">
      <div class="col-md-12">
        <div class="panel report-panel">
          <div class="panel-body no-lat-padding">
            <table id="ies-stats-table" class="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Universidade</th>
                  <th>Grupo</th>
                  <th>Região</th>
                  <th>Farm</th>
                  <th>Qualidade</th>
                  <template v-if="hasRevenueData">
                    <th>Meta semestre (R$)</th>
                    <th>Meta móvel (R$)</th>
                    <th>Realizado LTV (R$)</th>
                    <th>LTV Speed (%)</th>
                    <th>Speed (%)</th>
                    <th>Realizado (R$)</th>
                  </template>
                  <th>Tipo</th>
                  <th>Situação</th>
                  <th>Visitas em ofertas</th>
                  <th>Orders iniciadas</th>
                  <th>Atratividade</th>
                  <th>Orders pagas</th>
                  <th>Sucesso</th>
                  <th>Conversão</th>
                  <th>Reembolsos</th>
                  <th>Taxa de Reembolsos</th>
                  <th>Trocas</th>
                  <th>Faturamento por ordem R$</th>
                  <th>Receita Total</th>
                  <th>Receita Reembolsada</th>
                  <th>Ticket Médio R$</th>
                  <template v-if="hasRevenueData">
                    <th>LTV Speed 1d (%)</th>
                    <th>LTV Speed 7d (%)</th>
                    <th>GAP atual</th>
                    <th>GAP semestre</th>
                  </template>
                  <th>Carteira</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                  <tr v-for="entry in tableData">
                    <td>{{ entry.university_id }}</td>
                    <td>{{ entry.university_name }}</td>
                    <td>{{ entry.education_group_name }}</td>
                    <td>{{ entry.farm_region }}</td>
                    <td>{{ entry.owner }}</td>
                    <td>{{ entry.quality_owner }}</td>
                    <template v-if="hasRevenueData">
                      <td>{{ entry.semester_goal_formatted }}</span></td>
                      <td>{{ entry.mobile_goal_formatted }}</span></td>
                      <td>{{ entry.realized_formatted }}</span></td>
                      <td>{{ entry.speed }}</td>
                      <td>{{ entry.legacy_speed }}</td>
                      <td>{{ entry.legacy_realized_formatted }}</span></td>
                    </template>
                    <td><template v-if="entry.partner_plus">QB+</template><template v-else>Simples</template><template v-if="entry.billing"> - QAP</template><template v-else></template></td>
                    <td>{{ entry.status }}</td>
                    <td>{{ entry.visits }}</td>
                    <td>{{ entry.initiated_orders }}</td>
                    <td>{{ entry.new_orders_per_visits }}%</td>
                    <td>{{ entry.paid_orders }}</td>
                    <td>{{ entry.paid_per_new_orders }}%</td>
                    <td>{{ entry.paid_orders_per_visits }}%</td>
                    <td>{{ entry.refundeds }}</td>
                    <td>{{ entry.refunded_per_paid_orders }}%</td>
                    <td>{{ entry.exchangeds }}</td>
                    <td>{{ entry.mean_income }}</td>
                    <td><div class="no-wrap">R$ {{ entry.total_revenue }}</div></td>
                    <td><div class="no-wrap">R$ {{ entry.total_refunded }}</div></td>
                    <td>{{ entry.average_ticket }}</td>
                    <template v-if="hasRevenueData">
                      <td>{{ entry.last_day_velocity }}%</td>
                      <td>{{ entry.last_week_velocity }}%</td>
                      <td>{{ entry.gap_to_goal }}</td>
                      <td>{{ entry.gap_to_semester_goal }}</td>
                    </template>
                    <td>C{{ entry.account_type }}</td>
                    <td>
                      <!-- a :href="'dashboard?currentFilter={%22baseFilters%22:[{%22type%22:%22universities%22,%22value%22:[{%22id%22:' + entry.university_id + '}]}]}&comparingMode=no_compare'" target="_blank" -->
                      <a :href="dashboardLink(entry.university_id)" target="_blank">
                        Dashboard
                      </a>
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
import Multiselect from 'vue-multiselect'
import CsMultiselect from './custom-search-multiselect';
import DataTable from "../js/components/datatable";
import CDatePicker from './custom-date-picker'
import ProductLinesFilter from './product-lines-filter'

export default {
  data() {
    return {
      dateRange: null,
      filterKinds: null,
      filterLevels: null,
      filterType: null,
      filterOptions: [],
      kindOptions: [],
      levelOptions: [],
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      productLineOptions: [],
      loading: true,
      hasRevenueData: true,

      ownedUniversityFilter: null,
      universityFilter: null,
      universityGroupFilter: null,
      farmRegionFilter: null,
      ownedUniversityOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      farmRegionOptions: [],

      semesterStart: null,
      semesterEnd: null,
      tableData: [],
      accountTypeFilter: null,
      acountTypeOptions: [
        { name: "C1", id: 1 },
        { name: "C2", id: 2 },
        { name: "C3", id: 3 },
        { name: "C4", id: 4 },
        { name: "C5", id: 5 },
      ],
    }
  },
  components: {
    CDatePicker,
    CsMultiselect,
    Multiselect,
    ProductLinesFilter,
  },
  mounted() {
    console.log("mounted");
    IesStatsChannel.on('filtersData', (payload) => this.receiveFilters(payload));
    IesStatsChannel.on('tableData', (payload) => this.receiveTableData(payload));

    this.loading = true;
    this.loadFilters();
  },
  methods: {
    dashboardLink(university_id) {
      let productLineFilters = this.$refs.productLineFilter.filters();

      let productLineFilterStr = '';
      if ('productLine' in productLineFilters) {
        if (!_.isNil(productLineFilters.productLine)) {
          productLineFilterStr = ',"productLine":{%22id%22:' + productLineFilters.productLine.id + '}';
        }
      } else {
        let mappedKinds = _.map(productLineFilters.kinds, (entry) => { return '{%22id%22:' + entry.id + '}'});
        let mappedLevels = _.map(productLineFilters.levels, (entry) => { return '{%22id%22:' + entry.id + '}'});
        productLineFilterStr = ',"productLineSelectionType":"kind_and_level","kinds":[' + mappedKinds + '],"levels":[' + mappedLevels + ']';
      }

      return 'dashboard?currentFilter={%22baseFilters%22:[{%22type%22:%22universities%22,%22value%22:[{%22id%22:' + university_id + '}]}]' + productLineFilterStr + '}&comparingMode=no_compare';
    },
    currentFilterValue() {
      if (this.filterType.type == "group") {
        return this.universityGroupFilter.id;
      }
      if (this.filterType.type == "university") {
        return this.universityFilter.id;
      }
      if (this.filterType.type == "account_type") {
        return this.accountTypeFilter;
      }
      if (this.filterType.type == "farm_region") {
        return this.farmRegionFilter;
      }
      return;
    },
    update() {
      if (_.isNil(this.dateRange[0]) || _.isNil(this.dateRange[1])) {
        alert('Selecione um período');
        return;
      }

      console.log("this.farmRegionFilter: " + this.farmRegionFilter + " - " + JSON.stringify(this.farmRegionFilter));

      if (this.filterType.type == 'farm_region' && (_.isNil(this.farmRegionFilter) || _.isEmpty(this.farmRegionFilter))) {
        alert('Selecione uma região');
        return;
      }

      this.loading = true;
      this.tableData = [];

      let productLineFilters = this.$refs.productLineFilter.filters();

      let parameter = {
        filterType: this.filterType.type,
        filterValue: this.currentFilterValue(),
        initialDate: this.dateRange[0],
        finalDate: this.dateRange[1],
        kinds: productLineFilters.kinds,
        levels: productLineFilters.levels
      };

      if ('productLine' in productLineFilters) {
        parameter.productLine = productLineFilters.productLine;
      }

      IesStatsChannel.push('filter', parameter).receive('timeout', () => {
        console.log("filter timeout");
      });
    },
    loadFilters() {
      IesStatsChannel.push('loadFilters').receive('timeout', () => {
        console.log("filters timeout");
      })
    },
    receiveTableData(data) {
      console.log("receiveTableData");
      this.tableData = data.universities;
      this.hasRevenueData = data.has_revenue_data;
      this.loading = false;

      this.$nextTick(() => {

        this.table = new DataTable('#ies-stats-table', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 8, 'desc' ]
        });

      });

    },
    receiveFilters(data) {
      console.log("receiveFilters");
      this.loading = false;
      this.levelOptions = data.levels;
      this.kindOptions = data.kinds;
      this.filterOptions = data.filters;
      this.universityGroupOptions = data.groups;
      this.farmRegionOptions = data.farm_regions;
      this.universityOptions = data.universities;
      this.ownedUniversityOptions = data.owned_universities;
      this.semesterStart = data.semester_start;
      this.semesterEnd = data.semester_end;
      this.productLineOptions = data.product_lines;

      if (!_.isNil(data.current_product_line)) {
        let filteredOptions = _.filter(this.productLineOptions, (entry) => {
          return entry.id === data.current_product_line;
        })
        //this.productLineFilter = filteredOptions[0];
        this.$refs.productLineFilter.setProductLineFilter(filteredOptions[0]);
      }

      this.dateRange = [ this.semesterStart, this.semesterEnd ];

      this.filterType = this.filterOptions[0];

      //quando recebeu os filtros pode disparar uma consulta, mas precisa de informacao pra saber qual consulta disparar
      this.update();
    }
  }
}
</script>
