<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Estoque
        </h2>
      </div>
    </div>

    <div class="row" style="position: relative;">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="row">
          <div class="col-md-12" >
            <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-group-options="universityGroupOptions" :university-options="universityOptions" :account-type-options="accountTypeOptions" :farm-region-options="farmRegionsOptions" :deal-owner-options="dealOwnersOptions"></panel-primary-filter>
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
          <location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" :campus-options="campusOptions" @cityLocationSelected="loadCities" @campusLocationSelected="loadCampuses"></location-filter>
        </div>

        <div class="row">
          <div class="col-md-12 col-sm-12">
            <div>
              <label for="kind-filter">CURSOS</label>
              <div class="col-md-12 col-sm-12 tiny-margin-left">
                <input type="radio" id="20_top_clean" name="canonicals_filter" value="20_top_clean" checked v-model="filterCanonicals">
                <label for="20_top_clean">
                  <span style="font-size: 18px;" class="tiny-padding-left">
                    TOP 20 EM VENDAS (Curso Mãe)
                    <span class="glyphicon glyphicon-info-sign tooltip__icon">
                      <div class="tooltip__content">
                        <span>
                            <p>O curso canônico mãe do SKU está entre os mais vendidos</p>
                        </span>
                      </div>
                    </span>
                  </span>
                </label>
                <input type="radio" id="20_top" name="canonicals_filter" value="20_top" style="margin-left: 10px;" v-model="filterCanonicals">
                <label for="20_top">
                  <span style="font-size: 18px;" class="tiny-padding-left">
                    TOP 20 EM VENDAS
                    <span class="glyphicon glyphicon-info-sign tooltip__icon">
                      <div class="tooltip__content">
                        <span>
                            <p>O curso canônico diretamente ligado ao SKU está entre os mais vendidos</p>
                        </span>
                      </div>
                    </span>
                  </span>
                </label>
                <input type="radio" id="all" name="canonicals_filter" value="all" style="margin-left: 10px;" v-model="filterCanonicals">
                <label for="all">
                  <span style="font-size: 18px;" class="tiny-padding-left">TODOS</span>
                </label>
              </div>
            </div>
          </div>
        </div>


        <div class="row">
          <div class="col-md-12 default-margin-top">
            <button class="btn-submit" @click="execute">
              Executar
            </button>
          </div>
        </div>
      </div>
    </div>

    <modal-dialog ref="groupingModal" identification="grouping-modal">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h2 class="modal-title">Agupamento</h2>
        <div class="modal-body">
          <label>SELECIONE O SEMESTRE</label><br>
          <cs-multiselect v-model="groupingSemester" :options="gropingSemesterOptions" label="name" track-by="id" placeholder="Selecione o semestre" selectLabel="" deselectLabel=""></cs-multiselect>

          <label>SELECIONE O AGRUPAMENTO</label><br>
          <cs-multiselect v-model="grouping" :options="gropingOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel=""></cs-multiselect>

          <label>SELECIONE A ORDENAÇÃO</label><br>
          <cs-multiselect v-model="groupingOrdering" :options="gropingOrderingOptions" label="name" track-by="id" placeholder="Selecione a ordenação" selectLabel="" deselectLabel=""></cs-multiselect>
          <button class="btn-submit default-margin-top" @click="executeGroup">
            Agrupar
          </button>
        </div>
      </div>
    </modal-dialog>

    <modal-dialog ref="reportModal" identification="report-modal">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h2 class="modal-title">Relatório IES</h2>
      </div>
      <div class="modal-body">
        <label>SELECIONE O INDICE DA DATA</label><br>
        <input type="text" v-model="reportIndex" style="color: #647383; padding-left: 10px; height: 40px;" class="multiselect__input">
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-submit" @click="exportReportData">Exportar</button>
        <button type="button" class="btn btn-submit" data-dismiss="modal">Fechar</button>
      </div>
    </modal-dialog>

    <modal-dialog ref="exportModal" identification="stock-modal">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h2 class="modal-title">Exportar SKU's</h2>
      </div>
      <div class="modal-body">
        <div class="row">
          <div class="col-md-6">
            <label>SELECIONE UMA DATA PARA EXPORTAR</label><br>
            <c-date-picker v-model="exportDate" :shortcuts="shortcuts" :range="false" :not-after="lastDate"></c-date-picker>
          </div>
          <div class="col-md-6">
            <input type="checkbox" v-model="exportMetadataField" style="margin-right: 8px;"><label>EXPORTAR CAMPO DO METADATA</label>
            <template v-if="exportMetadataField">
              <input type="text" v-model="metadataExportField" style="color: #000000; height: 40px;" class="multiselect__input">
            </template>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-submit" @click="exportSkuData">Exportar</button>
        <button type="button" class="btn btn-submit" data-dismiss="modal">Fechar</button>
      </div>
    </modal-dialog>


    <div class="panel report-panel panel-default"> <!-- v-show="stockChartData" -->
      <div class="row">
        <ul class="nav navbar-nav justify-content-center">
          <li class="navbar__item" :class="{'active' : showMeanPanel}">
            <a class="nav-link clickable" @click="showMeans">SKU's e médias</a>
          </li>
          <li class="navbar__item" :class="{'active' : showDepthPanel}">
            <a class="nav-link clickable" @click="showDepths">Profundidade</a>
          </li>
        </ul>
      </div>
    <!-- /div -->

      <div class="panel-default" v-show="showDepthPanel">
        <div class="panel-heading panel-heading--spaced-bottom default-margin-top">NÚMERO DE SKUS PROFUNDOS ( SKU's com mais de uma ordem em 7 dias)</div>
        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="deepStockChart" export-name="deep_skus"></comparing-chart>
          </div>
        </div>

        <div class="panel-heading panel-heading--spaced-bottom default-margin-top">NÚMERO DE SKUS RASOS ( SKU's com apenas uma ordem em 7 dias)</div>
        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="flatStockChart" export-name="flat_skus"></comparing-chart>
          </div>
        </div>
      </div>

      <div class="panel-default" v-show="showMeanPanel">

      <!-- div class="panel report-panel panel-default" v-show="stockChartData" -->
        <div class="panel-heading panel-heading--spaced-bottom default-margin-top">
          NÚMERO DE SKUS DISPONÍVEIS

          <span class="clickable" style="float: right;" @click="showExportModal">
            Exportar SKU's
          </span>
          <span class="clickable" style="margin-right: 40px; float: right;" @click="showReportModal" v-show="currentFilterType && currentFilterType != 'university'">
            Relatório IES
          </span>

          <template v-if="showGroupingData">
            <span class="clickable" style="margin-right: 40px; float: right;" @click="hideGrouping">
              Desagrupar
            </span>
          </template>
          <template v-else>
          <span class="clickable" style="margin-right: 40px; float: right;" @click="showGroupingModal" v-show="currentFilterType && currentFilterType != 'university'">
            Agrupar
          </span>
          </template>
          <template v-if="currentCoursesType != 'all'">
            ( SKU's dos 20 cursos canônicos <template v-if="currentCoursesType == '20_top_clean'">mãe</template> mais vendidos <span class="glyphicon glyphicon-info-sign tooltip__icon">
              <div class="tooltip__content">
                <span>
                  <template v-if="currentCoursesType == '20_top_clean'">
                    <p>O curso canônico mãe do SKU está entre os mais vendidos</p>
                  </template>
                  <template v-else>
                    <p>O curso canônico diretamente ligado ao SKU está entre os mais vendidos</p>
                  </template>
                  <p>Os 20 cursos canônicos mais vendidos são:</p>
                  Administração<br>
                  Análise e Desenvolvimento de Sistemas<br>
                  Arquitetura e Urbanismo<br>
                  Biomedicina<br>
                  Ciências Contábeis<br>
                  Direito<br>
                  Educação Física<br>
                  Enfermagem<br>
                  Engenharia Civil<br>
                  Engenharia de Produção<br>
                  Engenharia Mecânica<br>
                  Estética<br>
                  Farmácia<br>
                  Fisioterapia<br>
                  Logística<br>
                  Nutrição<br>
                  Pedagogia<br>
                  Psicologia<br>
                  Publicidade e Propaganda<br>
                  Recursos Humanos<br>
                </span>
              </div>
            </span> )
          </template>
        </div>

        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="stockChart" export-name="skus"></comparing-chart>
          </div>
        </div>
      <!-- /div -->

      <div class="panel report-panel panel-default" v-show="showGroupingData">
        <div class="panel-heading panel-heading--spaced-bottom">NÚMERO DE SKUS ( AGRUPADO )</div>
        <div class="row">
          <div class="col-md-3">
            <label>NÚMERO DE SÉRIES</label>
            <multiselect v-model="nGroupingSeries" :options="seriesOptions" label="name" placeholder="Selecione o número de séries" selectLabel="" deselectLabel="" selectedLabel=""></multiselect>
          </div>
        </div>

        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="groupedStockChart" export-name="skus_agrupado"></comparing-chart>
          </div>
        </div>
      </div>

      <!-- div class="panel report-panel panel-default" v-show="showFrozenData" -->
        <template v-show="showFrozenData">
          <div class="panel-heading panel-heading--spaced-bottom default-margin-top">NÚMERO DE SKUS COM OFERTAS CONGELADAS</div>
          <div class="row">
            <div class="col-md-12">
              <comparing-chart ref="frozenStockChart" export-name="frozen_skus"></comparing-chart>
            </div>
          </div>
        </template>
      <!-- /div -->

      <!-- div class="panel report-panel panel-default" v-show="discountChartData" -->
        <template v-show="discountChartData">
          <div class="panel-heading panel-heading--spaced-bottom default-margin-top">MÉDIA DO DESCONTO OFERECIDO DISPONÍVEL NO SITE</div>
          <div class="row">
            <div class="col-md-12">
              <comparing-chart ref="discountChart" export-name="desconto"></comparing-chart>
            </div>
          </div>
        </template>
      <!-- /div -->

      <div class="panel report-panel panel-default" v-show="showGroupingData">
        <div class="panel-heading panel-heading--spaced-bottom">MÉDIA DO DESCONTO ( AGRUPADO )</div>
        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="groupedDiscountChart" export-name="desconto_agrupado"></comparing-chart>
          </div>
        </div>
      </div>

      <!-- div class="panel report-panel panel-default" v-show="priceChartData" -->
        <template v-show="priceChartData">
          <div class="panel-heading panel-heading--spaced-bottom default-margin-top">MÉDIA DO PREÇO OFERECIDO DISPONÍVEL NO SITE</div>
          <div class="row">
            <div class="col-md-12">
              <comparing-chart ref="priceChart" export-name="preco"></comparing-chart>
            </div>
          </div>
        </template>

      <div class="panel report-panel panel-default" v-show="showGroupingData">
        <div class="panel-heading panel-heading--spaced-bottom">MÉDIA DO PREÇO ( AGRUPADO )</div>
        <div class="row">
          <div class="col-md-12">
            <comparing-chart ref="groupedPriceChart" export-name="preco_agrupado"></comparing-chart>
          </div>
        </div>
      </div>

      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import Multiselect from 'vue-multiselect'
import CsMultiselect from 'vue-multiselect'
import MessageDialog from "../js/components/message-dialog";
import ComparingChart from './comparing-chart'
import DataTable from "../js/components/datatable";
import PanelPrimaryFilter from './panel-primary-filter';
import LocationFilter from './location-filter';
import CDatePicker from './custom-date-picker'
import ModalDialog from './modal-dialog'
import moment from 'moment';

export default {
  data() {
    return {
      loading: false,
      filterKinds: null,
      filterLevels: null,
      universityOptions: [],
      universitySugestions: [],
      kindOptions: [],
      levelOptions: [],
      filterOptions: [],
      universityGroupOptions: [],
      accountTypeOptions: [],
      stockData: null,
      stockDatachart: null,
      stockSeriesNames: null,
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      priceChartData: false,
      discountChartData: false,
      stockChartData: false,
      filterCanonicals: '20_top_clean',
      exportDate: null,
      lastDate: null,
      shortcuts: [],
      currentCoursesType: null,
      reportIndex: null,
      currentFilterType: null,
      metadataField: null,
      metadataExportField: null,
      exportMetadataField: false,
      grouping: null,
      gropingOptions: [],
      baseGropingOptions: [
        { name: 'IES', id: 'ies' },
        { name: 'Grupo', id: 'group' },
      ],
      showGroupingData: false,
      gropingSemesterOptions: [],
      groupingSemester: null,
      seriesOptions: [
        { name: '5', id: 5 },
        { name: '10', id: 10 },
        { name: '15', id: 15 },
        { name: '20', id: 20 },
      ],
      nGroupingSeries: null,
      groupedDates: [],
      groupedSkus: [],
      groupedPrices: [],
      groupedDiscounts: [],
      groupsKeys: [],
      groupsKeysNames: [],
      gropingOrderingOptions: [
        { name: 'SKU\'s', id: 'skus' },
        { name: 'Desconto', id: 'discount' },
        { name: 'Preço', id: 'price' },
      ],
      groupingOrdering: [],
      showFrozenData: false,
      showMeanPanel: true,
      showDepthPanel: false,
      farmRegionsOptions: [],
      dealOwnersOptions: [],
    }
  },
  components: {
    Multiselect,
    ComparingChart,
    PanelPrimaryFilter,
    LocationFilter,
    CDatePicker,
    ModalDialog,
    CsMultiselect,
  },
  watch: {
    nGroupingSeries: function (value) {
      this.setGroupCharts();
    },
  },
  mounted() {
    console.log("mounted");

    this.lastDate = moment().subtract(1, 'days').toDate();
    this.exportDate = this.lastDate;

    StockChannel.on('stockError', (payload) => this.receiveStockError(payload));
    StockChannel.on('citiesComplete', (payload) => this.receiveCitiesComplete(payload));
    StockChannel.on('campusComplete', (payload) => this.receiveCampusComplete(payload));

    StockChannel.on('meansData', (payload) => this.receiveStockMeans(payload));
    StockChannel.on('filterData', (payload) => this.receiveFilterData(payload));
    StockChannel.on('skuExportData', (payload) => this.receiveExportData(payload));
    StockChannel.on('iesReportData', (payload) => this.receiveReportData(payload));
    StockChannel.on('groupData', (payload) => this.receiveGroupData(payload));
    StockChannel.on('frozenData', (payload) => this.receiveFrozenData(payload));
    StockChannel.on('depthData', (payload) => this.receiveDepthData(payload));

    this.nGroupingSeries = this.seriesOptions[0];
    this.groupingOrdering = this.gropingOrderingOptions[0];

    this.loading = true;
    this.loadFilters();
  },
  methods: {
    showMeans() {
      this.showMeanPanel = true;
      this.showDepthPanel = false;

      this.updateMeansCharts();
    },
    showDepths() {
      console.log("showDepths");
      this.showMeanPanel = false;
      this.showDepthPanel = true;

      this.updateDepthCharts();
    },
    hideGrouping() {
      this.showGroupingData = false;
      this.$refs.groupedStockChart.clearSeries();
    },
    executeGroup() {
      if (_.isNil(this.groupingSemester)) {
        alert('Selecione o semestre');
        return;
      }
      if (_.isNil(this.grouping)) {
        alert('Selecione o agrupamento');
        return;
      }
      if (_.isNil(this.groupingOrdering)) {
        alert('Selecione a ordenação');
        return;
      }

      this.$refs.groupingModal.setLoader();
      const currentFilter = this.$refs.filter.filterSelected();

      var locationType = this.$refs.locationFilter.locationFilter();
      var locationValue = this.$refs.locationFilter.locationValue();

      let parameters = {
        type: currentFilter.type,
        value: currentFilter.value,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        locationType: locationType,
        locationValue: locationValue,
        courses: this.filterCanonicals,
        grouping: this.grouping,
        groupingSemester: this.groupingSemester,
        groupingOrdering: this.groupingOrdering,
      }

      StockChannel.push('groupStats', parameters).receive('timeout', (data) => {
        console.log('groupStats timeout');
      });
    },
    currenFilterMap() {
      const currentFilter = this.$refs.filter.filterSelected();
      let parameters = {
        type: currentFilter.type,
        value: currentFilter.value,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        locationType: this.$refs.locationFilter.locationFilter(),
        locationValue: this.$refs.locationFilter.locationValue(),
        courses: this.filterCanonicals,
        date: this.exportDate,
      }
      return parameters;
    },
    exportReportData() {
      console.log("exportReportData");
      this.$refs.reportModal.setLoader();
      let parameters = this.currenFilterMap();
      parameters.dayIndex = this.reportIndex;

      StockChannel.push('reportIes', parameters).receive('timeout', () => {
        console.log("export timeout");
      });
    },
    exportSkuData() {
      console.log("exportSkuData");
      this.$refs.exportModal.setLoader();

      if (!_.isNil(this.metadataExportField) && this.metadataExportField != '') {
        this.metadataField = this.metadataExportField;
      }

      const currentFilter = this.$refs.filter.filterSelected();
      let parameters = {
        type: currentFilter.type,
        value: currentFilter.value,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        locationType: this.$refs.locationFilter.locationFilter(),
        locationValue: this.$refs.locationFilter.locationValue(),
        courses: this.filterCanonicals,
        date: this.exportDate,
      }

      StockChannel.push('exportSkus', parameters).receive('timeout', () => {
        console.log("export timeout");
      });
    },
    emptyNull(value) {
      if (_.isNil(value)) {
        return "";
      }
      return value;
    },
    showExportModal() {
      this.exportMetadataField = false;
      this.metadataExportField = null;
      this.$refs.exportModal.show();
    },
    showReportModal() {
      this.$refs.reportModal.show();
    },
    showGroupingModal() {
      this.$refs.groupingModal.show();
    },
    loadCampuses() {
      console.log("loadCampuses");
      this.$refs.locationFilter.setCampusLoader(true);
      const currentFilter = this.$refs.filter.filterSelected();
      const parameters = { type: currentFilter.type, value: currentFilter.value, kinds: this.filterKinds, levels: this.filterLevels }
      StockChannel.push('completeCampus', parameters).receive('timeout', () => {
        console.log("campus timeout");
      });
    },
    loadCities() {
      console.log("loadCities");
      this.$refs.locationFilter.setCitiesLoader(true);
      const currentFilter = this.$refs.filter.filterSelected();
      const parameters = { type: currentFilter.type, value: currentFilter.value, kinds: this.filterKinds, levels: this.filterLevels }
      StockChannel.push('completeCities', parameters).receive('timeout', () => {
        console.log("cities timeout");
      });
    },
    loadFilters() {
      StockChannel.push('loadFilters').receive('timeout', () => {
        console.log('filters timeout');
      });
    },
    setGroupCharts() {
      this.$refs.groupedStockChart.clearSeries();
      this.$refs.groupedPriceChart.clearSeries();
      this.$refs.groupedDiscountChart.clearSeries();

      this.$refs.groupedStockChart.setLabels(this.groupedDates);
      this.$refs.groupedPriceChart.setLabels(this.groupedDates);
      this.$refs.groupedDiscountChart.setLabels(this.groupedDates);

      let maximo = this.nGroupingSeries.id;
      for (var i = 0; i < maximo; i++) {
        this.$refs.groupedStockChart.setSeries(i, this.groupedSkus[this.groupsKeys[i]], `${this.groupsKeysNames[i]}`);
        this.$refs.groupedPriceChart.setSeries(i, this.groupedPrices[this.groupsKeys[i]], `${this.groupsKeysNames[i]}`);
        this.$refs.groupedDiscountChart.setSeries(i, this.groupedDiscounts[this.groupsKeys[i]], `${this.groupsKeysNames[i]}`);
      }

      this.$nextTick(() => {
        this.$refs.groupedStockChart.updateChart();
        this.$refs.groupedPriceChart.updateChart();
        this.$refs.groupedDiscountChart.updateChart();
      });
    },
    receiveDepthData(data) {
      //console.log('receiveDepthData DATES: ' + JSON.stringify(data.flat_skus));

      this.$refs.deepStockChart.clearSeries();
      this.$refs.flatStockChart.clearSeries();

      this.$refs.deepStockChart.setLabels(data.dates);

      this.$refs.deepStockChart.setSeries(0, data.deep_skus_sem2, data.semester_2);
      this.$refs.deepStockChart.setSeries(1, data.deep_skus_sem1, data.semester_1);
      this.$refs.deepStockChart.setSeries(2, data.deep_skus, data.semester);

      this.$refs.flatStockChart.setLabels(data.dates);
      this.$refs.flatStockChart.setSeries(0, data.flat_skus_sem2, data.semester_2);
      this.$refs.flatStockChart.setSeries(1, data.flat_skus_sem1, data.semester_1);
      this.$refs.flatStockChart.setSeries(2, data.flat_skus, data.semester);

      this.$nextTick(() => {
        this.$refs.deepStockChart.updateChart();
        this.$refs.flatStockChart.updateChart();
      });

    },
    receiveFrozenData(data) {
      console.log('receiveFrozenData');

      this.showFrozenData = true;

      this.$refs.frozenStockChart.setLabels(data.dates);
      this.$refs.frozenStockChart.setSeries(0, data.skus, data.semester);

      if (!_.isNil(data.current_point)) {
        this.$refs.frozenStockChart.setCurrentPoint(data.current_point);
      }

      this.$nextTick(() => {
        this.$refs.frozenStockChart.updateChart();
      });
    },
    receiveGroupData(data) {
      console.log('receiveGroupData keys: ' + JSON.stringify(data.keys));
      this.showGroupingData = true;


      this.$refs.groupingModal.resetLoader();
      this.$refs.groupingModal.close();

      this.groupedDates = data.dates;
      this.groupedSkus = data.grouped_skus;
      this.groupedPrices = data.grouped_prices;
      this.groupedDiscounts = data.grouped_discounts;
      this.groupsKeys = data.keys;
      this.groupsKeysNames = data.keys_names;

      this.setGroupCharts();
    },
    receiveReportData(data) {
      console.log('receiveReportData');
      this.$refs.reportModal.resetLoader();
      this.$refs.reportModal.close();

      if (data.report.length === 0) {
        alert("Nenhum dado para o dia selecionado");
      } else {
        var filename = "ies_report_" + moment().format('DD_MM_YYYY') + '.csv';
        var content = "ID_IES;IES;sem-2;sem-1;sem\n";
        _.each(data.report, (item, itemIndex) => {
          //console.log(JSON.stringify(item));
          content = content + item['id'] + ";"
            + item['name'] + ";"
            + this.emptyNull(item['sem_2']) + ";"
            + this.emptyNull(item['sem_1']) + ";"
            + this.emptyNull(item['sem'])
            + "\n";
        });

        var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
        saveAs(blob, filename);
      }
    },
    receiveExportData(data) {
      console.log('receiveExportData');
      this.$refs.exportModal.resetLoader();
      this.$refs.exportModal.close();

      if (data.courses.length === 0) {
        alert("Nenhum SKU para a data selecionada");
      } else {
        var filename = "skus_em_" + moment(this.exportDate).format('DD_MM_YYYY') + '.csv';
        var content = "Curso;Nivel;Modalidade;Turno;Campus;IES;Curso Canônico;Curso Canônico RAIZ";
        if (!_.isNil(this.metadataField)){
          content = content + ";metadata";
        }
        content = content + "\n";
        _.each(data.courses, (item, itemIndex) => {
          console.log(JSON.stringify(item));
          content = content + item['name'] + ";"
            + item['level'] + ";"
            + item['kind'] + ";"
            + item['shift'] + ";"
            + item['campus_name'] + ";"
            + item['university_name'] + ";"
            + item['canonical_name'] + ";"
            + item['root_canonical_name'];
           if (!_.isNil(this.metadataField)) {
             if (!_.isNil(item['metadata'])) {
               content = content + ";" + this.emptyNull(item['metadata'][this.metadataField]);
             } else {
               content = content + ";";
             }
           }
           content = content + "\n";
        });

        var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
        saveAs(blob, filename);
      }
    },
    receiveFilterData(data) {
      this.universityOptions = data.universities;
      this.universitySugestions = data.universities;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.filterOptions = data.filters;
      this.universityGroupOptions = data.groups;
      this.accountTypeOptions = data.accountTypes;
      this.locationOptions = data.locations;
      this.regionsOptions = data.regions;
      this.statesOptions = data.states;
      this.farmRegionsOptions = data.farm_regions;
      this.dealOwnersOptions = data.deal_owners;
      this.loading = false;
      console.log("dealOwnersOptions: " + JSON.stringify(this.dealOwnersOptions));
    },
    receiveCitiesComplete(data) {
      this.citiesOptions = data.cities;
      this.$refs.locationFilter.setCitiesLoader(false);
    },
    receiveCampusComplete(data) {
      this.campusOptions = data.campuses;
      this.$refs.locationFilter.setCampusLoader(false);
    },
    receiveStockMeans(data) {
      console.log("receiveStockMeans");

      this.loading = false;
      this.discountChartData = true;
      this.priceChartData = true;
      this.stockChartData = true;

      this.reportIndex = data.current_point

      this.currentCoursesType = data.courses_type;

      this.$refs.discountChart.setXAxisTitle('Dia da captação');
      this.$refs.priceChart.setXAxisTitle('Dia da captação');
      this.$refs.stockChart.setXAxisTitle('Dia da captação');

      if (!_.isNil(data.current_point)) {
        this.$refs.discountChart.setCurrentPoint(data.current_point);
        this.$refs.priceChart.setCurrentPoint(data.current_point);
        this.$refs.stockChart.setCurrentPoint(data.current_point);
      }

      this.$refs.discountChart.setLabels(data.dates);
      this.$refs.priceChart.setLabels(data.dates);
      this.$refs.stockChart.setLabels(data.dates);

      this.$refs.discountChart.setSeries(0, data.discounts2, data.semester_2);
      this.$refs.priceChart.setSeries(0, data.prices2, data.semester_2);

      this.$refs.discountChart.setSeries(1, data.discounts1, data.semester_1);
      this.$refs.priceChart.setSeries(1, data.prices1, data.semester_1);

      this.$refs.discountChart.setSeries(2, data.discounts, data.semester);
      this.$refs.priceChart.setSeries(2, data.prices, data.semester);

      this.$refs.stockChart.setSeries(0, data.count_sem2, data.semester_2);
      this.$refs.stockChart.setSeries(1, data.count_sem1, data.semester_1);
      this.$refs.stockChart.setSeries(2, data.count_sem, data.semester);
      this.$refs.stockChart.resetLoader();
      this.$refs.discountChart.resetLoader();
      this.$refs.priceChart.resetLoader();

      this.gropingSemesterOptions = [];
      this.gropingSemesterOptions.push({id: data.semester_id, name: data.semester});
      this.gropingSemesterOptions.push({id: data.semester_1_id, name: data.semester_1});
      this.gropingSemesterOptions.push({id: data.semester_2_id, name: data.semester_2});

      this.groupingSemester = this.gropingSemesterOptions[0];

      this.$nextTick(() => {
        this.$refs.discountChart.updateChart();
        this.$refs.priceChart.updateChart();
        this.$refs.stockChart.updateChart();
      });
    },
    updateMeansCharts() {
      this.$nextTick(() => {
        this.$refs.frozenStockChart.updateChart();
        this.$refs.discountChart.updateChart();
        this.$refs.priceChart.updateChart();
        this.$refs.stockChart.updateChart();
      });
    },
    updateDepthCharts() {
      this.$nextTick(() => {
        this.$refs.flatStockChart.updateChart();
        this.$refs.deepStockChart.updateChart();
      });
    },
    receiveStockError(data) {
      const dialog = new MessageDialog("global-dialog", "danger", "Erro");
      dialog.show("Erro ao gerar análise");
      this.loading = false;
    },
    loadGroupingOptions() {
      console.log("CURR: " + this.currentFilterType + " A: " + JSON.stringify(this.baseGropingOptions));
      if (this.currentFilterType == 'account_type') {
        this.gropingOptions = _.filter(this.baseGropingOptions, entry => entry.id != 'account_type');
      } else {
        this.gropingOptions = this.baseGropingOptions;
      }
    },
    execute() {
      const currentFilter = this.$refs.filter.filterSelected();
      if (_.isNil(currentFilter)) {
        alert("Selecione o filtro");
        return;
      }
      if ((_.isNil(currentFilter.value) || currentFilter.value == '') && currentFilter.type != 'all') {
        alert("Selecione o filtro");
        return;
      }

      var locationType = this.$refs.locationFilter.locationFilter();
      var locationValue = this.$refs.locationFilter.locationValue();
      if (!_.isNil(locationType)) {
        if (_.isNil(locationValue) || locationValue == '') {
          alert('Selecione o valor para localização');
          return;
        }
      }

      this.loading = true;

      this.showFrozenData = false;
      this.$refs.stockChart.setLoader();
      this.$refs.discountChart.setLoader();
      this.$refs.priceChart.setLoader();

      this.$refs.stockChart.clearSeries();
      this.$refs.discountChart.clearSeries();
      this.$refs.priceChart.clearSeries();

      this.stockChartData = null;
      this.discountChartData = false;
      this.priceChartData = false;

      this.showGroupingData = false;
      this.$refs.groupedStockChart.clearSeries();
      this.$refs.frozenStockChart.clearSeries();

      this.$refs.deepStockChart.clearSeries();
      this.$refs.flatStockChart.clearSeries();

      this.currentFilterType = currentFilter.type;
      let parameters = {
        type: currentFilter.type,
        value: currentFilter.value,
        kinds: this.filterKinds,
        levels: this.filterLevels,
        locationType: locationType,
        locationValue: locationValue,
        courses: this.filterCanonicals,
      }

      StockChannel.push('stats', { parameters }).receive('timeout', (data) => {
        console.log('stats timeout');
      });

      this.loadGroupingOptions();
    }
  }
}
</script>
