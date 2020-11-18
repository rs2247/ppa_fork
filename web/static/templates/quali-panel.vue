<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Painel do Qualidade
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


            <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :quality-owner-options="qualityOwnerOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>

            <div class="row">
              <div class="col-md-3 col-sm-6">
                <div class="">
                  <label for="date">DATA</label>
                  <c-date-picker v-model="dateRange" :shortcuts="shortcuts"></c-date-picker>
                </div>
              </div>
            </div>

            <div class="row">
              <template v-if="hasProductLineOptions">
                <div class="col-md-2 col-sm-6" style="margin-top: 10px;">
                  <input type="radio" :name="'product_line_selection_type_' + index" value="product_line" checked v-model="productLineSelectionType">
                  <label for="">
                    <span style="font-size: 18px;" class="tiny-padding-left">Linha de Produto</span>
                  </label><br>
                  <input type="radio" :name="'product_line_selection_type_' + index" value="kind_and_level" v-model="productLineSelectionType">
                  <label for="">
                    <span style="font-size: 18px;" class="tiny-padding-left">Customizado</span>
                  </label>
                </div>

                <div class="col-md-2 col-sm-6" v-if="showProductLineSelection">
                  <div>
                    <label for="kind-filter">LINHA DE PRODUTO</label>
                    <multiselect v-model="filterProductLine" :options="productLineOptions" label="name" track-by="id" placeholder="Todas as linhas de produto" selectLabel="" deselectLabel="" @input="productLineSelected"></multiselect>
                  </div>
                </div>
              </template>
              <template v-else>
              </template>

              <template v-if="showKindAndLevelSelection">
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
              </template>
              <template v-else>
              </template>
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
      <div class="col-md-6">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">FATURAMENTO POR ORDEM</div>
          <div class="row">
            <div class="col-md-12 col-sm-12">
              <div class="transparent-loader" v-if="tableLoading">
                <div class="loader"></div>
              </div>

              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny no-wrap">
                    <thead>
                      <tr>
                        <th colspan="2"></th>
                        <th colspan="2">FILTRO - {{ dataInicial }} - {{ dataFinal }}</th>
                        <th style="width: 100px; background-color: #3B4347;"></th>
                        <th colspan="1">7 DIAS</th>
                        <th style="width: 100px; background-color: #3B4347;"></th>
                        <th colspan="1">ANO ANTERIOR</th>
                      </tr>
                      <tr>
                        <th></th>
                        <th>META (R$)</th>
                        <th>REALIZADO (R$)</th>
                        <th>VELOCIMETRO (%)</th>
                        <th style="width: 100px; background-color: #3B4347;">
                        <th>VELOCIMETRO (%)</th>
                        <th style="width: 100px; background-color: #3B4347;">
                        <th>REALIZADO (R$)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>TOTAL</td>
                        <td>{{ fatOrderGoalTotal }}</td>
                        <td>{{ fatOrderTotal }}</td>
                        <td>{{ fatOrderSpeedTotal }}</td>
                        <td></td>
                        <td>{{ fatOrderSpeed7DaysTotal }}</td>
                        <td></td>
                        <td>{{ fatOrderPreviousTotal }}</td>
                      </tr>
                      <tr>
                        <td>EAD+SEMI</td>
                        <td>{{ fatOrderGoalEad }}</td>
                        <td>{{ fatOrderEad }}</td>
                        <td>{{ fatOrderSpeedEad }}</td>
                        <td></td>
                        <td>{{ fatOrderSpeed7DaysEad }}</td>
                        <td></td>
                        <td>{{ fatOrderPreviousEad }}</td>
                      </tr>
                      <tr>
                        <td>PRESENCIAL</td>
                        <td>{{ fatOrderGoalPres }}</td>
                        <td>{{ fatOrderPres }}</td>
                        <td>{{ fatOrderSpeedPres }}</td>
                        <td></td>
                        <td>{{ fatOrderSpeed7DaysPres }}</td>
                        <td></td>
                        <td>{{ fatOrderPreviousPres }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>


              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny no-wrap">
                    <thead>
                      <tr>
                        <th colspan="2"></th>
                        <th colspan="2">DATA ATUAL</th>
                        <th style="width: 200px; background-color: #3B4347;"></th>
                        <th colspan="1">ANO ANTERIOR</th>
                      </tr>
                      <tr>
                        <th></th>
                        <th>META (R$)</th>
                        <th>REALIZADO (R$)</th>
                        <th>VELOCIMETRO (%)</th>
                        <th style="width: 200px; background-color: #3B4347;"></th>
                        <th>REALIZADO (R$)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>TOTAL</td>
                        <td>{{ current_fatOrderGoalTotal }}</td>
                        <td>{{ current_fatOrderTotal }}</td>
                        <td>{{ current_fatOrderSpeedTotal }}</td>
                        <td></td>
                        <td>{{ current_fatOrderPreviousTotal }}</td>
                      </tr>
                      <tr>
                        <td>EAD+SEMI</td>
                        <td>{{ current_fatOrderGoalEad }}</td>
                        <td>{{ current_fatOrderEad }}</td>
                        <td>{{ current_fatOrderSpeedEad }}</td>
                        <td></td>
                        <td>{{ current_fatOrderPreviousEad }}</td>
                      </tr>
                      <tr>
                        <td>PRESENCIAL</td>
                        <td>{{ current_fatOrderGoalPres }}</td>
                        <td>{{ current_fatOrderPres }}</td>
                        <td>{{ current_fatOrderSpeedPres }}</td>
                        <td></td>
                        <td>{{ current_fatOrderPreviousPres }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>


      <div class="col-md-6" style="height: 100%;">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">RECEITA</div>
          <div class="row">
            <div class="col-md-12 col-sm-12">
              <div class="transparent-loader" v-if="tableLoading">
                <div class="loader"></div>
              </div>

              <!-- div class="panel-heading panel-heading--spaced-bottom">SHARE DE RECEITA</div -->

              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny no-wrap">
                    <thead>
                      <tr>
                        <th colspan="5">VELOCÍMETRO (%)</th>
                      </tr>
                      <tr>
                        <th colspan="2">ATUAL</th>
                        <!-- th style="width: 200px; background-color: #3B4347;">
                        <th colspan="2">ANO ANTERIOR</th -->
                      </tr>
                      <tr>
                        <th>SEMESTRE</th>
                        <th>7 DIAS</th>
                        <!-- th style="width: 200px; background-color: #3B4347;">
                        <th>SEMESTRE</th>
                        <th>7 DIAS</th -->
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>{{ revenueSemesterSpeed }}</td>
                        <td>{{ revenue7DaysSpeed }}</td>
                        <!-- td></td>
                        <td>{{ velocimetroSemestrePrev }}</td>
                        <td>{{ velocimetro7DiasPrev }}</td -->
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>


              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny no-wrap">
                    <thead>
                      <tr>
                        <th colspan="5">SHARE MODALIDADES (%)</th>
                      </tr>
                      <tr>
                        <th colspan="2">ATUAL</th>
                        <th style="width: 200px; background-color: #3B4347;">
                        <th colspan="2">ANO ANTERIOR</th>
                      </tr>
                      <tr>
                        <th>PRESENCIAL</th>
                        <th>EAD + SEMI</th>
                        <th style="width: 200px; background-color: #3B4347;">
                        <th>PRESENCIAL</th>
                        <th>EAD + SEMI</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>{{ sharePres }}</td>
                        <td>{{ shareEad }}</td>
                        <td></td>
                        <td>{{ sharePresPrev }}</td>
                        <td>{{ shareEadPrev }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Resultados
          </div>
        </div>
      </div -->
<!--
      Share de pagos do Presencial v.s EAD
    - Faturamento por ordem (Todas as modalidades e graus) em reais (Meta) --
    - Faturamento por ordem (EAD+Semi) em reais (Meta)
    - Faturamento por ordem do Presencial em reais (Meta)

    - Faturamento por ordem (Todas as modalidades e graus) em reais (Realizado) --
    - Faturamento por ordem (EAD+Semi) em reais (Realizado)
    - Faturamento por ordem do Presencial em reais (Realizado)

    - Faturamento por ordem (Speed em relação ao esperado para o período)  --
    - Faturamento por ordem  EAD + Semi(Speed em relação ao esperado para o período)
    - Faturamento por ordem Presencial (Speed em relação ao esperado para o período)
-->
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">FATURAMENTO/ORDEM Acumulado</div>
          <comparing-chart ref="cumMeanIncomeChart" export-name="ticket_medio_acumulado"></comparing-chart>
        </div>
      </div>

      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">FATURAMENTO/ORDEM ( Médial móvel )</div>
          <comparing-chart ref="meanIncomeChart" export-name="ticket_medio_acumulado"></comparing-chart>
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import _ from 'lodash'

import ComparingChart from './comparing-chart'
import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import CDatePicker from './custom-date-picker'

export default {
  data() {
    return {

      fatOrderTotal: null,
      fatOrderGoalTotal: null,

      fatOrderEad: null,
      fatOrderGoalEad: null,

      fatOrderPres: null,
      fatOrderGoalPres: null,

      fatOrderSpeedTotal: null,
      fatOrderSpeedEad: null,
      fatOrderSpeedPres: null,

      fatOrderPreviousTotal: null,
      fatOrderPreviousEad: null,
      fatOrderPreviousPres: null,

      fatOrderSpeed7DaysTotal: null,
      fatOrderSpeed7DaysEad: null,
      fatOrderSpeed7DaysPres: null,


      current_fatOrderGoalTotal: null,
      current_fatOrderTotal: null,
      current_fatOrderSpeedTotal: null,

      current_fatOrderGoalEad: null,
      current_fatOrderEad: null,
      current_fatOrderSpeedEad: null,

      current_fatOrderGoalPres: null,
      current_fatOrderPres: null,
      current_fatOrderSpeedPres: null,

      current_fatOrderPreviousTotal: null,
      current_fatOrderPreviousEad: null,
      current_fatOrderPreviousPres: null,

      dataInicial: null,
      dataFinal: null,


      shareEad: null,
      sharePres: null,
      shareEadPrev: null,
      sharePresPrev: null,

      //???
      // velocimetroSemestre: null,
      // velocimetro7Dias: null,
      // velocimetroSemestrePrev: null,
      // velocimetro7DiasPrev: null,

      revenueSemesterSpeed: null,
      revenue7DaysSpeed: null,

      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      kindOptions: [],
      levelOptions: [],
      //blockCount: null,
      filterKinds: [],
      filterLevels: [],

      dateRange: null,

      //tableData: [],
      table: null,
      enabledFilter: true,
      visibleFilter: false,
      restrictedFilter: false,


      loadingFilters: true,
      dataLoading: false,
      semesterStart: null,
      semesterEnd: null,

      productLineSelectionType: 'product_line',
      filterProductLine: null,
      productLineOptions: [],

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
    ComparingChart,
  },
  computed: {
    showProductLineSelection() {
      return this.productLineSelectionType == "product_line";
    },
    showKindAndLevelSelection() {
      return this.productLineSelectionType == "kind_and_level" || this.productLineOptions.length == 0;
    },
    hasProductLineOptions() {
      return this.productLineOptions.length > 0;
    },
  },
  mounted() {
    QualiChannel.on('filters', (payload) => this.receiveFilters(payload));
    QualiChannel.on('cumMeanIncomeData', (payload) => this.receiveCumMeanIncomeData(payload));
    QualiChannel.on('meanIncomeData', (payload) => this.receiveMeanIncomeData(payload));
    QualiChannel.on('tableData', (payload) => this.receiveTableData(payload));
    QualiChannel.on('velocimeterData', (payload) => this.receiveVelocimeterData(payload));
    QualiChannel.on('instantVelocimeterData', (payload) => this.receiveInstantVelocimeterData(payload));

    this.loadFilters();
  },
  methods: {
    primaryFilterSelected(data) {
      console.log('primaryFilterSelected data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      this.universityGroupOptions = data.groups;
      this.universityOptions = data.universities;
      this.qualityOwnerOptions = data.qualityOwners;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.semesterStart = data.semester_start
      this.semesterEnd = data.semester_end
      this.productLineOptions = data.product_lines;

      this.dateRange = [ moment(this.semesterStart).toDate(), moment(this.semesterEnd).toDate() ];

      this.loadingFilters = false;
    },
    receiveTableData(data) {
      this.fatOrderTotal = data.fat_ordem;
      this.fatOrderGoalTotal = data.fat_ordem_goal;
      this.fatOrderSpeedTotal = data.fat_ordem_speed;

      this.fatOrderEad = data.fat_ordem_ead;
      this.fatOrderGoalEad = data.fat_ordem_goal_ead;
      this.fatOrderSpeedEad = data.fat_ordem_speed_ead;

      this.fatOrderPres = data.fat_ordem_pres;
      this.fatOrderGoalPres = data.fat_ordem_goal_pres;
      this.fatOrderSpeedPres = data.fat_ordem_speed_pres;

      this.fatOrderPreviousTotal = data.fat_ordem_previous;
      this.fatOrderPreviousEad = data.fat_ordem_ead_previous;
      this.fatOrderPreviousPres = data.fat_ordem_pres_previous;

      this.shareEad = data.shared_ead;
      this.sharePres = data.shared_pres;
      this.shareEadPrev = data.shared_ead_prev;
      this.sharePresPrev = data.shared_pres_prev;

      this.fatOrderSpeed7DaysTotal = data.fat_ordem_speed_7_days;
      this.fatOrderSpeed7DaysEad = data.fat_ordem_speed_7_days_ead;
      this.fatOrderSpeed7DaysPres = data.fat_ordem_speed_7_days_pres;

      this.dataInicial = data.data_inicio_filtro;
      this.dataFinal = data.data_fim_filtro;
    },
    resetTable() {
      this.dataInicial = null;
      this.dataFinal = null;

      this.fatOrderTotal = null;
      this.fatOrderGoalTotal = null;
      this.fatOrderSpeedTotal = null;

      this.fatOrderEad = null;
      this.fatOrderGoalEad = null;
      this.fatOrderSpeedEad = null;

      this.fatOrderPres = null;
      this.fatOrderGoalPres = null;
      this.fatOrderSpeedPres = null;

      this.fatOrderPreviousTotal = null;
      this.fatOrderPreviousEad = null;
      this.fatOrderPreviousPres = null;

      this.fatOrderSpeed7DaysTotal = null;
      this.fatOrderSpeed7DaysEad = null;
      this.fatOrderSpeed7DaysPres = null;

      this.revenueSemesterSpeed = null;
      this.revenue7DaysSpeed = null;

      this.shareEad = null;
      this.sharePres = null;
      this.shareEadPrev = null;
      this.sharePresPrev = null;


      this.current_fatOrderGoalTotal = null;
      this.current_fatOrderTotal = null;
      this.current_fatOrderSpeedTotal = null;

      this.current_fatOrderGoalEad = null;
      this.current_fatOrderEad = null;
      this.current_fatOrderSpeedEad = null;

      this.current_fatOrderGoalPres = null;
      this.current_fatOrderPres = null;
      this.current_fatOrderSpeedPres = null;

      this.current_fatOrderPreviousTotal = null;
      this.current_fatOrderPreviousEad = null;
      this.current_fatOrderPreviousPres = null;
    },
    receiveVelocimeterData(data) {
      this.revenueSemesterSpeed = data.semester_velocimeter;
      this.revenue7DaysSpeed = data.seven_days_velocimeter;
    },
    receiveMeanIncomeData(data) {
      this.$refs.meanIncomeChart.setLabels(data.dates);

      this.$refs.meanIncomeChart.setSeries(0, data.mean_income, "ATUAL");
      this.$refs.meanIncomeChart.setSeries(1, data.mean_income_prev, "ANTERIOR");
      //this.$refs.meanIncomeChart.setSeries(2, data.goal, "META");

      this.$nextTick(() => {
        this.$refs.meanIncomeChart.updateChart();
      });
    },
    receiveCumMeanIncomeData(data) {
      this.$refs.cumMeanIncomeChart.setLabels(data.dates);

      this.$refs.cumMeanIncomeChart.setSeries(0, data.mean_income, "ATUAL");
      this.$refs.cumMeanIncomeChart.setSeries(1, data.mean_income_prev, "ANTERIOR");
      //this.$refs.cumMeanIncomeChart.setSeries(2, data.goal, "META");

      this.dataLoading = false;

      this.$nextTick(() => {
        this.$refs.cumMeanIncomeChart.updateChart();
      });
    },
    receiveInstantVelocimeterData(data) {
      this.current_fatOrderGoalTotal = data.fat_ordem_goal;
      this.current_fatOrderTotal = data.fat_ordem;
      this.current_fatOrderSpeedTotal = data.fat_ordem_speed;

      this.current_fatOrderGoalEad = data.fat_ordem_goal_ead;
      this.current_fatOrderEad = data.fat_ordem_ead;
      this.current_fatOrderSpeedEad = data.fat_ordem_speed_ead;

      this.current_fatOrderGoalPres = data.fat_ordem_goal_pres;
      this.current_fatOrderPres = data.fat_ordem_pres;
      this.current_fatOrderSpeedPres = data.fat_ordem_speed_pres;

      this.current_fatOrderPreviousTotal = data.fat_ordem_previous;
      this.current_fatOrderPreviousEad = data.fat_ordem_ead_previous;
      this.current_fatOrderPreviousPres = data.fat_ordem_pres_previous;
    },
    loadFilters() {
      QualiChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      if (!this.$refs.filter.validateFilter()) {
        return;
      }
      let filter = this.$refs.filter.filterSelected();

      this.dataLoading = true;

      let initialDate = this.dateRange[0];
      let finalDate = this.dateRange[1];

      this.$refs.meanIncomeChart.clearSeries();
      this.$refs.cumMeanIncomeChart.clearSeries();

      filter.initialDate = initialDate;
      filter.finalDate = finalDate;

      if (this.productLineSelectionType == 'kind_and_level' || this.productLineOptions.length == 0) {
        filter.kinds = this.filterKinds;
        filter.levels = this.filterLevels;
      } else {
        filter.kinds = [];
        filter.levels = [];
      }
      if (this.productLineSelectionType == 'product_line') {
        filter.productLine =  this.filterProductLine;
      }

      this.resetTable();

      QualiChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
