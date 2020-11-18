<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Curvas de demanda
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
            <panel-filter
              :period-disabled="false"
              ref="currentFilter"
              index="0"
              @primaryFilterSelected="currentPrimarySelected"
              @locationTypeSelected="currentLocationTypeSelected"
              @locationSelected="currentLocationSelected"
              @timeRangeSelected="currentRangeSelected"
              @kindSelected="currentKindSelected"
              @levelSelected="currentLevelSelected"></panel-filter>

            <div class="row">
              <div class="transparent-loader" v-if="coursesLoading">
                <div class="loader"></div>
              </div>
              <div class="col-md-12 col-sm-12">
                <div>
                  <label for="">CURSO</label>
                  <cs-multiselect v-model="canonicalCourse" :options="canonicalCoursesOptions" label="name" placeholder="Todos os cursos" selectLabel="Enter para selecionar" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="loadData">
                    Atualizar
                  </button>

                  <div class="default-margin-left" v-if="hasData">

                    <div  class="dropdown" @click="exportData">
                      <div class="dropdown-toggle">
                        <span class="flex-grow dropdown-label">Exportar Tabela</span>
                      </div>
                    </div>
                  </div>
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

          <div style="float: right;" v-if="simulatedPrice || currentOfferedPrice">
            <table class="data-table data-table-tiny">
              <thead>
                <tr>
                  <th></th>
                  <th v-if="currentOfferedPrice">Atual</th>
                  <th v-if="simulatedPrice">Simulação</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Preço cheio</td>
                  <td v-if="currentOfferedPrice">
                    <template v-if="hasFullPrice">
                      R$ {{ currentFullPrice }}
                    </template>
                    <template v-else>
                      -
                    </template>
                  </td>
                  <td v-if="simulatedPrice">
                    <template v-if="hasFullPrice">
                      R$ {{ currentFullPrice }}
                    </template>
                    <template v-else>
                      -
                    </template>
                  </td>
                </tr>
                <tr>
                  <td>Preço com desconto</td>
                  <td v-if="currentOfferedPrice">R$ {{ currentOfferedPrice }}</td>
                  <td v-if="simulatedPrice">R$ {{ simulatedPrice }}</td>
                </tr>
                <tr>
                  <td>Desconto (%)</td>
                  <td v-if="currentOfferedPrice">
                    <template v-if="hasFullPrice">
                      {{ currentDiscount }}%
                    </template>
                    <template v-else>
                      -
                    </template>
                  </td>
                  <td v-if="simulatedPrice">
                    <template v-if="hasFullPrice">
                      {{ simulatedDiscount }}%
                    </template>
                    <template v-else>
                      -
                    </template>
                  </td>
                </tr>
                <tr>
                  <td>Receita ótima (%)</td>
                  <td v-if="currentOfferedPrice">{{ currentCoverage }}%</td>
                  <td v-if="simulatedPrice">{{ simulatedCoverage }}%</td>
                </tr>
                <tr>
                  <td>Demanda capturada (%)</td>
                  <td v-if="currentOfferedPrice">{{ currentDemandCoverage }}%</td>
                  <td v-if="simulatedPrice">{{ simulatedDemandCoverage }}%</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="panel-heading panel-heading--spaced-bottom">
            CURVA DE DEMANDA ( PRIMEIRA GERAÇÃO )
            <p v-if="curvePoints">Número de pontos: {{ curvePoints }}</p>

            <div class="row">
              <div class="col-md-3">
                <label for="">SIMULAÇÃO</label>
                <multiselect v-model="optimizedPointType" :options="optimizedOptions" label="name" track-by="id" placeholder="Selecione o tipo" selectLabel="" deselectLabel="" @input="optimizedSelected" :allow-empty="false"></multiselect>
              </div>
              <template v-if="optimizedPointType && optimizedPointType.id == 'custom'">
                <div class="col-md-3">
                  <label for="">VALOR</label>
                  <input type="text" v-model="currentOptimalPrice" style="color: #000000; height: 40px;" class="multiselect__input">
                </div>
                <div class="col-md-3">
                  <button class="btn-submit" @click="setOptimalOffered" style="margin-top: 25px;">
                    Setar
                  </button>
                </div>
              </template>

              <div class="col-md-3">


              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12 col-sm-12">
              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <scatter-chart ref="demandCurveChart" export-name="curva_de_demanda" :base-height="600"></scatter-chart>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>


    <!--- CURVAS SEGUNDA GERACAO -->
    <div v-show="secondDemandData || loadingSecondDemandData">

      <div class="row">
        <div class="col-md-12">
          <div class="row">
            <div class="transparent-loader" v-if="loadingSecondDemandData">
              <div class="loader"></div>
            </div>
          </div>
          <div class="panel report-panel panel-default">
            <div class="panel-heading panel-heading--spaced-bottom">
              CURVAS DE SEGUNDA GERAÇAO
            </div>
          </div>
        </div>
      </div>


      <div class="row">
        <div class="col-md-12">
          <div class="panel report-panel panel-default">

              <div style="float: right;" v-if="simulatedPriceSecond[0] || currentOfferedPrice">
                <table class="data-table data-table-tiny">
                  <thead>
                    <tr>
                      <th></th>
                      <th v-if="currentOfferedPrice">Atual</th>
                      <th v-if="simulatedPriceSecond[0]">Simulação</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Preço cheio</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[0]">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Preço com desconto</td>
                      <td v-if="currentOfferedPrice">R$ {{ currentOfferedPrice }}</td>
                      <td v-if="simulatedPriceSecond[0]">R$ {{ simulatedPriceSecond[0] }}</td>
                    </tr>
                    <tr>
                      <td>Desconto (%)</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          {{ currentDiscount }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[0]">
                        <template v-if="hasFullPrice">
                          {{ simulatedDiscount0 }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Receita ótima (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondCoverage[0] }}%</td>
                      <td v-if="simulatedPriceSecond[0]">{{ simulatedSecondCoverage[0] }}%</td>
                    </tr>
                    <tr>
                      <td>Demanda capturada (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondDemandCoverage[0] }}%</td>
                      <td v-if="simulatedPriceSecond[0]">{{ simulatedSecondDemandCoverage[0] }}%</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <div class="panel-heading panel-heading--spaced-bottom">
              MANHÃ

              <div class="row">
                <!-- div class="col-md-3">
                  <label for="">SIMULAÇÃO</label>
                  <multiselect v-model="optimizedPointType" :options="optimizedOptions" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @input="optimizedSelected" :allow-empty="false"></multiselect>
                </div>
                <template v-if="optimizedPointType && optimizedPointType.id == 'custom'">
                  <div class="col-md-3">
                    <label for="">VALOR</label>
                    <input type="text" v-model="currentOptimalPrice" style="color: #000000; height: 40px;" class="multiselect__input">
                  </div>
                  <div class="col-md-3">
                    <button class="btn-submit" @click="setOptimalOffered" style="margin-top: 25px;">
                      Setar
                    </button>
                  </div>
                </template>

                <div class="col-md-3">


                </div -->
              </div>
            </div>
            <div class="row">
              <div class="col-md-12 col-sm-12">
                <div class="row">
                  <div class="col-md-12 col-sm-12">
                    <scatter-chart ref="secondDemandCurveManhaSimplificado" export-name="curva_de_demanda_segunda_geracao" :base-height="600"></scatter-chart>
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

              <div style="float: right;" v-if="simulatedPriceSecond[1] || currentOfferedPrice">
                <table class="data-table data-table-tiny">
                  <thead>
                    <tr>
                      <th></th>
                      <th v-if="currentOfferedPrice">Atual</th>
                      <th v-if="simulatedPriceSecond[1]">Simulação</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Preço cheio</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[1]">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Preço com desconto</td>
                      <td v-if="currentOfferedPrice">R$ {{ currentOfferedPrice }}</td>
                      <td v-if="simulatedPriceSecond[1]">R$ {{ simulatedPriceSecond[1] }}</td>
                    </tr>
                    <tr>
                      <td>Desconto (%)</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          {{ currentDiscount }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[1]">
                        <template v-if="hasFullPrice">
                          {{ simulatedDiscount1 }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Receita ótima (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondCoverage[1] }}%</td>
                      <td v-if="simulatedPriceSecond[1]">{{ simulatedSecondCoverage[1] }}%</td>
                    </tr>
                    <tr>
                      <td>Demanda capturada (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondDemandCoverage[1] }}%</td>
                      <td v-if="simulatedPriceSecond[1]">{{ simulatedSecondDemandCoverage[1] }}%</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <div class="panel-heading panel-heading--spaced-bottom">
              TARDE

              <div class="row">
                <!-- div class="col-md-3">
                  <label for="">SIMULAÇÃO</label>
                  <multiselect v-model="optimizedPointType" :options="optimizedOptions" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @input="optimizedSelected" :allow-empty="false"></multiselect>
                </div>
                <template v-if="optimizedPointType && optimizedPointType.id == 'custom'">
                  <div class="col-md-3">
                    <label for="">VALOR</label>
                    <input type="text" v-model="currentOptimalPrice" style="color: #000000; height: 40px;" class="multiselect__input">
                  </div>
                  <div class="col-md-3">
                    <button class="btn-submit" @click="setOptimalOffered" style="margin-top: 25px;">
                      Setar
                    </button>
                  </div>
                </template>

                <div class="col-md-3">


                </div -->
              </div>
            </div>
            <div class="row">
              <div class="col-md-12 col-sm-12">
                <div class="row">
                  <div class="col-md-12 col-sm-12">
                    <scatter-chart ref="secondDemandCurveTardeSimplificado" export-name="curva_de_demanda_segunda_geracao" :base-height="600"></scatter-chart>
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
              <div style="float: right;" v-if="simulatedPriceSecond[2] || currentOfferedPrice">
                <table class="data-table data-table-tiny">
                  <thead>
                    <tr>
                      <th></th>
                      <th v-if="currentOfferedPrice">Atual</th>
                      <th v-if="simulatedPriceSecond[2]">Simulação</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Preço cheio</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[2]">
                        <template v-if="hasFullPrice">
                          R$ {{ currentFullPrice }}
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Preço com desconto</td>
                      <td v-if="currentOfferedPrice">R$ {{ currentOfferedPrice }}</td>
                      <td v-if="simulatedPriceSecond[2]">R$ {{ simulatedPriceSecond[2] }}</td>
                    </tr>
                    <tr>
                      <td>Desconto (%)</td>
                      <td v-if="currentOfferedPrice">
                        <template v-if="hasFullPrice">
                          {{ currentDiscount }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                      <td v-if="simulatedPriceSecond[2]">
                        <template v-if="hasFullPrice">
                          {{ simulatedDiscount2 }}%
                        </template>
                        <template v-else>
                          -
                        </template>
                      </td>
                    </tr>
                    <tr>
                      <td>Receita ótima (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondCoverage[2] }}%</td>
                      <td v-if="simulatedPriceSecond[2]">{{ simulatedSecondCoverage[2] }}%</td>
                    </tr>
                    <tr>
                      <td>Demanda capturada (%)</td>
                      <td v-if="currentOfferedPrice">{{ currentSecondDemandCoverage[2] }}%</td>
                      <td v-if="simulatedPriceSecond[2]">{{ simulatedSecondDemandCoverage[2] }}%</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <div class="panel-heading panel-heading--spaced-bottom">
              NOITE

              <div class="row">
                <!-- div class="col-md-3">
                  <label for="">SIMULAÇÃO</label>
                  <multiselect v-model="optimizedPointType" :options="optimizedOptions" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel="" @input="optimizedSelected" :allow-empty="false"></multiselect>
                </div>
                <template v-if="optimizedPointType && optimizedPointType.id == 'custom'">
                  <div class="col-md-3">
                    <label for="">VALOR</label>
                    <input type="text" v-model="currentOptimalPrice" style="color: #000000; height: 40px;" class="multiselect__input">
                  </div>
                  <div class="col-md-3">
                    <button class="btn-submit" @click="setOptimalOffered" style="margin-top: 25px;">
                      Setar
                    </button>
                  </div>
                </template -->

                <div class="col-md-3">


                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-12 col-sm-12">
                <div class="row">
                  <div class="col-md-12 col-sm-12">
                    <scatter-chart ref="secondDemandCurveNoiteSimplificado" export-name="curva_de_demanda_segunda_geracao" :base-height="600"></scatter-chart>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

  </div>
</template>


<script>
import _ from 'lodash'

import PanelFilter from './panel-filter';
import moment from 'moment';
import ScatterChart from './scatter-chart';
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import QueryString from '../js/query-string'

export default {
  data() {
    return {
      loadingFilters: true,
      coursesLoading: false,
      movelMean: true,
      dataLoading: false,
      canonicalCoursesOptions: [],
      canonicalCourse: null,
      totalPoints: null,
      usedPoints: null,
      currentOfferedPrice: null,
      currentDemandCoverage: null,
      simulatedDemandCoverage: null,
      currentCoverage: null,
      currentFullPrice: null,
      simulatedPrice: null,
      simulatedCoverage: null,
      currentOptimalPrice: null,
      calculatedOptimalDemand: null,
      calculatedOptimalPrice: null,
      calculatedSecondOptimalDemand: [],
      calculatedSecondOptimalPrice: [],
      curvePoints: null,
      optimizedOptions: [
        { id: 'optimal', name: 'Ponto ótimo'},
        { id: 'custom', name: 'Customizada'},
        { id: 'none', name: 'Sem simulação'},
      ],
      optimizedPointType: null,
      optimalIndex: null,
      currentLocationType: null,
      currentLocationValue: null,
      hasData: false,
      priceSeries: [],
      revenueSeries: [],
      currentSecondCoverage: [],
      simulatedSecondCoverage: [],
      currentSecondDemandCoverage: [],
      simulatedSecondDemandCoverage: [],
      simulatedPriceSecond: [null, null, null],
      simulatedDiscountSecond: [],
      simulatedRectangleColor: '#FDB913',
      currentOfferedRectangleColor: '#bbbbbb',
      simulationDash: [15, 2],
      offeredDash: [15, 5],
      secondDemandData: false,
      secondOptimalIndexes: [],
      loadingSecondDemandData: false,
    }
  },
  components: {
    PanelFilter,
    ScatterChart,
    CsMultiselect,
    Multiselect,
  },
  mounted() {
    DemandCurvesChannel.on('filters', (payload) => this.receiveFilters(payload));
    DemandCurvesChannel.on('demandData', (payload) => this.receiveDemandData(payload));
    DemandCurvesChannel.on('demandNoData', (payload) => this.receiveDemandNoData(payload));
    DemandCurvesChannel.on('loadingSecondDemandData', () => this.receiveLoadingSecondDemandData());
    DemandCurvesChannel.on('demandNoSecondData', () => this.receiveDemandNoSecondData());


    DemandCurvesChannel.on('demandData2', (payload) => this.receiveDemandData(payload)); //deprecado, remover

    DemandCurvesChannel.on('secondDemandDataManhaSimplificado', (payload) => this.receiveSecondDemandDataManhaSimplificado(payload));
    DemandCurvesChannel.on('secondDemandDataTardeSimplificado', (payload) => this.receiveSecondDemandDataTardeSimplificado(payload));
    DemandCurvesChannel.on('secondDemandDataNoiteSimplificado', (payload) => this.receiveSecondDemandDataNoiteSimplificado(payload));

    DemandCurvesChannel.on('citiesFilters', (payload) => this.receiveCitiesFilters(payload));
    DemandCurvesChannel.on('coursesFilters', (payload) => this.receiveCoursesFilters(payload));

    this.optimizedPointType = this.optimizedOptions[0];

    this.loadFilters();
  },
  computed: {
    hasFullPrice() {
      return !_.isNil(this.currentFullPrice);
    },
    fullTest() {
      return _.isNil(this.currentFullPrice);
    },
    hasSimulations() {
      return !_.isNil(this.simulatedPrice);
    },
    currentDiscount() {
      if (_.isNil(this.currentOfferedPrice) || _.isNil(this.currentFullPrice)) {
          return null;
      }
      return Math.round(((this.currentFullPrice - this.currentOfferedPrice) / this.currentFullPrice) * 100);
    },
    simulatedDiscount() {
      if (_.isNil(this.simulatedPrice) || _.isNil(this.currentFullPrice)) {
        return null;
      }
      return Math.round(((this.currentFullPrice - this.simulatedPrice) / this.currentFullPrice) * 100);
    },
    simulatedDiscount0() {
      if (_.isNil(this.simulatedPriceSecond[0]) || _.isNil(this.currentFullPrice)) {
        return null;
      }
      return Math.round(((this.currentFullPrice - this.simulatedPriceSecond[0]) / this.currentFullPrice) * 100);
    },
    simulatedDiscount1() {
      if (_.isNil(this.simulatedPriceSecond[1]) || _.isNil(this.currentFullPrice)) {
        return null;
      }
      return Math.round(((this.currentFullPrice - this.simulatedPriceSecond[1]) / this.currentFullPrice) * 100);
    },
    simulatedDiscount2() {
      if (_.isNil(this.simulatedPriceSecond[2]) || _.isNil(this.currentFullPrice)) {
        return null;
      }
      return Math.round(((this.currentFullPrice - this.simulatedPriceSecond[2]) / this.currentFullPrice) * 100);
    },
  },
  methods: {
    dumpQueryString() {
      let filter = this.getFilter();
      if (!_.isNil(filter)) {
        let queryString = '?currentFilter=' + JSON.stringify(filter['currentFilter']);
        window.history.pushState('', '', window.location.pathname + queryString);
      }
    },
    parseQueryString() {
      const urlParams = new URLSearchParams(window.location.search);
      let hasFilter = false;

      let currentFilter = urlParams.get('currentFilter');
      if (!_.isNil(currentFilter)) {
        currentFilter = JSON.parse(currentFilter);
        this.$refs.currentFilter.setFiltersData(currentFilter);
        if (!_.isNil(currentFilter['canonicalCourse'])) {
          this.canonicalCourse = QueryString.solveEntry(this.canonicalCoursesOptions, currentFilter['canonicalCourse'].id, 'id');
        }
        hasFilter = true;
      }

      if (hasFilter) {
        this.$nextTick(() => {
          this.loadData();
        });
      }
    },
    exportData() {
      let zipped = _.zip(this.priceSeries, this.revenueSeries)
      var filename = "curva_demanda_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';

      var content = "% Demanda;Preço;% Receita\n";
      _.each(zipped, (entry) => {
        content = content + entry[0].x + ";" + entry[0].y + ";" + entry[1].y + "\n";
      })

      var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
      saveAs(blob, filename);
    },
    setChartRectangles(chart, chartIndex) {
      console.log("setChartRectangles: " + chartIndex + " TYPE: " + this.optimizedPointType.id + " CURR_OFFERED: " + this.currentOfferedPrice);
      let curveRects = []
      let currentOfferedPoint = chart.solvePlotData({ y: this.currentOfferedPrice }, 0);
      // currentOptimalPrice

      // SIMULATED - currentOptimalPrice -> de onde vem?
      if (this.optimizedPointType.id == 'custom') {
        //TODO - currentOptimalPrice or index?
        let currentOptimalPoint = chart.solvePlotData({ y: this.currentOptimalPrice }, 0);
        let coverage = { x: currentOptimalPoint.x }
        let currentCoveragePoint = chart.solvePlotData(coverage, 1);
        //TODO
        this.$set(this.simulatedSecondCoverage, chartIndex, currentCoveragePoint.y.toFixed(1));
        this.$set(this.simulatedSecondDemandCoverage, chartIndex, currentCoveragePoint.x.toFixed(1));
        curveRects.push({ x: 0, y: 0, to_scale_point: currentOptimalPoint , color: this.simulatedRectangleColor, dash: this.simulationDash, legend: 'Preço simulado' });
      }

      if (this.optimizedPointType.id == 'optimal') {
        this.$set(this.simulatedSecondCoverage, chartIndex, 100.0);
        this.$set(this.simulatedSecondDemandCoverage, chartIndex, this.calculatedSecondOptimalDemand[chartIndex]);
        this.$set(this.simulatedPriceSecond, chartIndex, this.calculatedSecondOptimalPrice[chartIndex]);

        curveRects.push({ x: 0, y: 0, to_point: { dataset: 0, index: this.secondOptimalIndexes[chartIndex] - 1 } , color: this.simulatedRectangleColor, dash: this.simulationDash, legend: 'Preço simulado', legendColor: '#FFFFFF' });
      }

      // CURRENT
      if (!_.isNil(this.currentOfferedPrice)) {
        let currenteCoveragePoint = chart.solvePlotData({ x: currentOfferedPoint.x }, 1);
        this.$set(this.currentSecondCoverage, chartIndex, currenteCoveragePoint.y.toFixed(1));
        this.$set(this.currentSecondDemandCoverage, chartIndex, currenteCoveragePoint.x.toFixed(1));
        curveRects.push({ x: 0, y: 0, to_scale_point: currentOfferedPoint , color: this.currentOfferedRectangleColor, dash: this.offeredDash, legend: 'Preço médio no site', legendColor: '#FFFFFF' });
      }

      chart.setRectangles(curveRects);
      chart.updateChart();
    },
    setRectangles() {
      var curveRects = [];
      let currentOfferedPoint = this.$refs.demandCurveChart.solvePlotData({ y: this.currentOfferedPrice }, 0);

      // SIMULATED
      if (this.optimizedPointType.id == 'custom') {
        let currentOptimalPoint = this.$refs.demandCurveChart.solvePlotData({ y: this.currentOptimalPrice }, 0);
        let coverage = { x: currentOptimalPoint.x }
        let currentCoveragePoint = this.$refs.demandCurveChart.solvePlotData(coverage, 1);
        this.simulatedCoverage = currentCoveragePoint.y.toFixed(1);
        this.simulatedDemandCoverage = currentCoveragePoint.x.toFixed(1);
        curveRects.push({ x: 0, y: 0, to_scale_point: currentOptimalPoint , color: this.simulatedRectangleColor, dash: this.simulationDash, legend: 'Preço simulado' });
      }

      if (this.optimizedPointType.id == 'optimal') {
        this.simulatedCoverage = 100.0;
        this.simulatedDemandCoverage = this.calculatedOptimalDemand;
        this.simulatedPrice = this.calculatedOptimalPrice;
        curveRects.push({ x: 0, y: 0, to_point: { dataset: 0, index: this.optimalIndex - 1 } , color: this.simulatedRectangleColor, dash: this.simulationDash, legend: 'Preço simulado', legendColor: '#FFFFFF' });
      }

      // CURRENT
      if (!_.isNil(this.currentOfferedPrice)) {
        let currenteCoveragePoint = this.$refs.demandCurveChart.solvePlotData({ x: currentOfferedPoint.x }, 1);
        this.currentCoverage = currenteCoveragePoint.y.toFixed(1);
        this.currentDemandCoverage = currenteCoveragePoint.x.toFixed(1);
        curveRects.push({ x: 0, y: 0, to_scale_point: currentOfferedPoint , color: this.currentOfferedRectangleColor, dash: this.offeredDash, legend: 'Preço médio no site', legendColor: '#FFFFFF' });
      }

      this.$refs.demandCurveChart.setRectangles(curveRects);
      this.$refs.demandCurveChart.updateChart();
    },
    setOptimalOffered() {
      console.log("setOptimalOffered# currentOfferedPrice: " + this.currentOptimalPrice);
      this.simulatedPrice = this.currentOptimalPrice;
      this.simulatedPriceSecond[0] = this.currentOptimalPrice;
      this.simulatedPriceSecond[1] = this.currentOptimalPrice;
      this.simulatedPriceSecond[2] = this.currentOptimalPrice;
      this.setRectangles();

      this.setChartRectangles(this.$refs.secondDemandCurveManhaSimplificado, 0);
      this.setChartRectangles(this.$refs.secondDemandCurveTardeSimplificado, 1);
      this.setChartRectangles(this.$refs.secondDemandCurveNoiteSimplificado, 2);
      this.updateCharts();
    },
    optimizedSelected(data) {
      console.log("optimizedSelected: " + JSON.stringify(data));
      if (data.id == 'optimal' || data.id == 'none') {
        if (data.id == 'none') {
          this.currentOptimalPrice = null;
          this.simulatedPrice = null;

          this.simulatedPriceSecond[0] = null;
          this.simulatedPriceSecond[1] = null;
          this.simulatedPriceSecond[2] = null;
        }
        this.setRectangles();

        this.setChartRectangles(this.$refs.secondDemandCurveManhaSimplificado, 0);
        this.setChartRectangles(this.$refs.secondDemandCurveTardeSimplificado, 1);
        this.setChartRectangles(this.$refs.secondDemandCurveNoiteSimplificado, 2);

        this.updateCharts();
      }
    },
    updateCharts() {
      this.$nextTick(() => {
        this.$refs.demandCurveChart.updateChart();
        this.$refs.secondDemandCurveManhaSimplificado.updateChart();
        this.$refs.secondDemandCurveTardeSimplificado.updateChart();
        this.$refs.secondDemandCurveNoiteSimplificado.updateChart();
      });
    },
    currentPrimarySelected() {
      console.log('currentPrimarySelected');
      //TODO - como saber se tem que completar?
      this.$nextTick(() => {
        this.completeCourses();
      });
    },
    currentLocationTypeSelected(data) {
      if (_.isNil(data)) {
        return;
      }
      console.log('currentLocationTypeSelected ' + data.type);
      this.currentLocationType = data.type;
      if (data.type == 'city') {
        var currentFilter = this.$refs.currentFilter.filterData(true);
        if (!currentFilter) {
          console.log("current filter vazio");
          currentFilter = {};
          //return;
        }
        currentFilter.canonicalCourse = this.canonicalCourse;
        let filter = { currentFilter };

        this.$refs.currentFilter.setCitiesLoading();

        DemandCurvesChannel.push('completeCities', filter).receive('timeout', (data) => {
          console.log('completeCities timeout');
        });
      }
    },
    completeCourses() {
      console.log("completeCourses");
      var currentFilter = this.$refs.currentFilter.filterData(true);
      if (!currentFilter) {
        currentFilter = {};
        //nao tem filtro, seta o default!
        return;
      }
      let filter = { currentFilter };

      DemandCurvesChannel.push('completeCourses', filter).receive('timeout', (data) => {
        console.log('completeCourses timeout');
      });

    },
    currentLocationSelected(type, value) {
      console.log('currentLocationSelected: ' + JSON.stringify(type) + " value: " + JSON.stringify(value));
      this.currentLocationValue = value;
    },
    currentRangeSelected() {
      console.log('currentRangeSelected');
    },
    currentKindSelected() {
      console.log('currentKindSelected');
    },
    currentLevelSelected() {
      console.log('currentLevelSelected');
    },
    receiveDemandNoData(data) {
      this.dataLoading = false;
      this.totalPoints = 0;
      this.usedPoints = 0;
      alert("Sem pontos para traçar");
    },
    receiveDemandNoSecondData() {
      this.loadingSecondDemandData = false;
    },
    receiveLoadingSecondDemandData() {
      this.loadingSecondDemandData = true;
    },
    solveSimulatedPrice(input, max_index, chart_index) {
      this.calculatedSecondOptimalPrice[chart_index] = input[max_index - 1].y;
      this.calculatedSecondOptimalDemand[chart_index] = input[max_index - 1].x;
      this.simulatedPriceSecond[chart_index] = this.calculatedSecondOptimalPrice[chart_index];
      this.simulatedSecondCoverage[chart_index] = 100;
    },
    //-----------
    receiveSecondDemandDataTardeSimplificado(data) {
      this.secondDemandData = true;
      this.$refs.secondDemandCurveTardeSimplificado.setXAxisTitle(0, "Demanda capturada (%)");
      this.$refs.secondDemandCurveTardeSimplificado.setYAxisTitle(0, "Preço (R$)");
      this.$refs.secondDemandCurveTardeSimplificado.setYAxisTitle(1, "Receita (%)");
      this.$refs.secondDemandCurveTardeSimplificado.setSeries(0, data.offered, "Preco oferecido");
      this.$refs.secondDemandCurveTardeSimplificado.setSeries(1, data.revenue, "Receita esperada");
      this.secondOptimalIndexes[1] = data.max_index

      this.solveSimulatedPrice(data.offered, data.max_index, 1);

      this.setChartRectangles(this.$refs.secondDemandCurveTardeSimplificado, 1);

      this.$nextTick(() => {
        this.$refs.secondDemandCurveTardeSimplificado.updateChart();
      });
    },
    receiveSecondDemandDataNoiteSimplificado(data) {
      this.secondDemandData = true;
      this.$refs.secondDemandCurveNoiteSimplificado.setXAxisTitle(0, "Demanda capturada (%)");
      this.$refs.secondDemandCurveNoiteSimplificado.setYAxisTitle(0, "Preço (R$)");
      this.$refs.secondDemandCurveNoiteSimplificado.setYAxisTitle(1, "Receita (%)");
      this.$refs.secondDemandCurveNoiteSimplificado.setSeries(0, data.offered, "Preco oferecido");
      this.$refs.secondDemandCurveNoiteSimplificado.setSeries(1, data.revenue, "Receita esperada");
      this.secondOptimalIndexes[2] = data.max_index

      this.solveSimulatedPrice(data.offered, data.max_index, 2);

      this.setChartRectangles(this.$refs.secondDemandCurveNoiteSimplificado, 2);

      this.$nextTick(() => {
        this.$refs.secondDemandCurveNoiteSimplificado.updateChart();
      });
    },
    receiveSecondDemandDataManhaSimplificado(data) {
      this.loadingSecondDemandData = false;

      this.secondDemandData = true;
      this.$refs.secondDemandCurveManhaSimplificado.setXAxisTitle(0, "Demanda capturada (%)");
      this.$refs.secondDemandCurveManhaSimplificado.setYAxisTitle(0, "Preço (R$)");
      this.$refs.secondDemandCurveManhaSimplificado.setYAxisTitle(1, "Receita (%)");
      this.$refs.secondDemandCurveManhaSimplificado.setSeries(0, data.offered, "Preco oferecido");
      this.$refs.secondDemandCurveManhaSimplificado.setSeries(1, data.revenue, "Receita esperada");
      this.secondOptimalIndexes[0] = data.max_index

      this.solveSimulatedPrice(data.offered, data.max_index, 0);

      this.setChartRectangles(this.$refs.secondDemandCurveManhaSimplificado, 0);

      this.$nextTick(() => {
        this.$refs.secondDemandCurveManhaSimplificado.updateChart();
      });
    },
    receiveDemandData(data) {
      if (!_.isNil(data.current_offered)) {
        this.currentOfferedPrice = eval(data.current_offered).toFixed(2);
      }
      if (!_.isNil(data.current_full) && data.current_full != '') {
        this.currentFullPrice = eval(data.current_full).toFixed(2);
      }

      this.optimalIndex = data.max_index;
      this.curvePoints = data.points_count;

      // OPTIMAL PRICE
      this.calculatedOptimalPrice = data.offered[data.max_index -1].y;
      this.calculatedOptimalDemand = data.offered[data.max_index -1].x;
      this.simulatedPrice = this.calculatedOptimalPrice;
      this.simulatedCoverage = 100;
      // --

      this.$refs.demandCurveChart.setXAxisTitle(0, "Demanda capturada (%)");
      this.$refs.demandCurveChart.setYAxisTitle(0, "Preço (R$)");
      this.$refs.demandCurveChart.setYAxisTitle(1, "Receita (%)");

      this.$refs.demandCurveChart.setSeries(0, data.offered, "Preco oferecido");
      this.$refs.demandCurveChart.setSeries(1, data.revenue, "Receita esperada");

      this.priceSeries = data.offered;
      this.revenueSeries = data.revenue;

      this.setRectangles();
      this.$refs.demandCurveChart.updateChart();

      this.dataLoading = false;
      this.hasData = true;
    },
    receiveCitiesFilters(data) {
      this.$refs.currentFilter.setCities(data.cities);
    },
    receiveCoursesFilters(data) {
      this.coursesLoading = true;
      this.canonicalCoursesOptions = data.courses;
      this.coursesLoading = false;
    },
    receiveFilters(data) {
      console.log('receiveFilters');
      this.$refs.currentFilter.setLevels(data.levels)
      this.$refs.currentFilter.setKinds(data.kinds);
      this.$refs.currentFilter.setLocations(data.locationTypes);
      this.$refs.currentFilter.setGroups(data.groupTypes);
      this.$refs.currentFilter.setAccountTypes(data.accountTypes);
      this.$refs.currentFilter.setUniversities(data.universities);
      this.$refs.currentFilter.setUniversityGroups(data.groups);
      this.$refs.currentFilter.setSemesterRange(moment().subtract(6, 'months').toDate(), moment().toDate());
      this.$refs.currentFilter.setDealOwners(data.dealOwners);
      this.$refs.currentFilter.setQualityOwners(data.qualityOwners);
      this.$refs.currentFilter.setRegions(data.regions);
      this.$refs.currentFilter.setStates(data.states);
      this.$refs.currentFilter.setCities([]);
      this.$refs.currentFilter.setCampus([]);

      this.baseCanonicalCoursesOptions = data.courses;
      this.canonicalCoursesOptions = data.courses;

      this.loadingFilters = false;

      this.parseQueryString();
    },
    loadFilters() {
      DemandCurvesChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    getFilter() {
      let currentFilter = this.$refs.currentFilter.filterData();
      if (!currentFilter) {
        console.log("currentFilter vazio");
        return;
      }
      currentFilter.canonicalCourse = this.canonicalCourse;
      return { currentFilter: currentFilter };
    },
    loadData() {
      let filter = this.getFilter();
      if (!filter) {
        return;
      }

      this.curvePoints = null;
      this.currentOfferedPrice = null;
      this.optimizedPointType = this.optimizedOptions[0];
      this.simulatedPrice = null;
      this.currentFullPrice = null;

      this.$refs.demandCurveChart.clearSeries();

      this.$refs.secondDemandCurveManhaSimplificado.clearSeries();
      this.$refs.secondDemandCurveTardeSimplificado.clearSeries();
      this.$refs.secondDemandCurveNoiteSimplificado.clearSeries();


      this.dataLoading = true;
      this.totalPoints = null;
      this.usedPoints = null;
      this.hasData = false;
      this.secondDemandData = false;

      DemandCurvesChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });

      this.dumpQueryString();
    }
  },
};

</script>
