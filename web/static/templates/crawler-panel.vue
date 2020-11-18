<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Concorrentes
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loadingFilters || dataLoading">
        <div class="loader"></div>
      </div>
    </div>

    <div class="panel report-panel panel-default">
      <div class="row">
        <ul class="nav navbar-nav justify-content-center">
          <li class="navbar__item" :class="{'active' : showIESActive}">
            <a class="nav-link clickable" @click="showIES">IES</a>
          </li>
          <li class="navbar__item" :class="{'active' : showOffersActive}">
            <a class="nav-link clickable" @click="showOffers">Ofertas</a>
          </li>
        </ul>
      </div>
    </div>

    <div class="row" v-show="showIESActive">
      <div class="col-md-12">
        <div class="row">
          <div class="col-md-12">
            <div class="row">
              <location-filter ref="locationFilterIes" class="default-margin-left" :class-multiplier="3" :location-options="iesLocationOptions" :cities-options="citiesOptions" :states-options="statesOptions" :regions-options="regionsOptions"></location-filter>

              <div class="col-md-6">
                <button class="btn-submit default-margin-top" @click="updateIesStats">
                  Atualizar
                </button>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="row">
              <div class="transparent-loader" v-if="iesLoading">
                <div class="loader"></div>
              </div>

              <div class="col-md-12">
                <div class="panel report-panel panel-default">
                  <div class="panel-heading panel-heading--spaced-bottom">
                    IES por conjunto
                  </div>
                  <!-- p v-if="totalIes" style="font-size: 30px;">NENHUM: -- </p -->
                  <div id="ies"></div>
                </div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="row">
              <div class="transparent-loader" v-if="iesStatesLoading">
                <div class="loader"></div>
              </div>
              <div class="col-md-12">
                <div class="panel report-panel panel-default">

                  <div class="panel-heading panel-heading--spaced-bottom">
                    IES por estado

                    <span class="clickable" style="font-size: 16px; font-weight: bolder; float: right;" @click="exportIes">
                      <div class="loader loader-tiny" style="display: inline-block;" v-if="exportIesLoading"></div>
                      <span v-else  class="glyphicon glyphicon-download-alt"></span>
                      Exportar IES Só EMB
                    </span>
                  </div>

                  <base-chart ref="iesStatesChart" export-name="comparativo_ies_emb" :base-height="390 "></base-chart>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row" v-show="showOffersActive">

      <div class="col-md-12">
        <div class="row">
          <div class="transparent-loader" v-if="offersLoading">
            <div class="loader"></div>
          </div>

          <div class="col-md-12">
            <div class="panel report-panel panel-default">
              <div class="panel-heading panel-heading--spaced-bottom">
                Comparativo de Ofertas
              </div>

              <div class="row small-margin-bottom">
                <div class="col-md-12">

                  <panel-primary-filter ref="filter" :permit-empty="true" :filter-options="filtersOptions" :university-group-options="universityGroupOptions" :university-options="universityOptions" :deal-owner-options="dealOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>

                  <div class="row">
                    <location-filter ref="locationFilter" :class-multiplier="4" :location-options="locationOptions" :cities-options="citiesOptions" :states-options="statesOptions" :regions-options="regionsOptions"></location-filter>
                  </div>

                  <div class="row">
                    <div class="col-md-3 default-margin-top">
                      <input type="radio" value="single_date" v-model="historySelectionType">
                      <label for="">
                        <span style="font-size: 18px;" class="tiny-padding-left tiny-padding-right">Foto diária</span>
                      </label>

                      <input type="radio" value="history" v-model="historySelectionType">
                      <label for="">
                        <span style="font-size: 18px;" class="tiny-padding-left">Série histórica</span>
                      </label><br>
                    </div>
                  </div>

                  <div class="row" v-show="historySelectionType == 'history'">
                    <div class="col-md-3">
                      <label>PERÍODO</label>
                      <c-date-picker v-model="dateRange" :shortcuts="shortcuts" :not-after="lastDate" :not-before="initialDate"></c-date-picker>
                    </div>
                  </div>

                  <div class="row" v-show="historySelectionType == 'single_date'">
                    <div class="col-md-3">
                      <label>AGRUPAMENTO</label>
                      <cs-multiselect v-model="groupingType" :options="groupingOptions" label="name" placeholder="Selecione o agrupamento"></cs-multiselect>
                    </div>

                    <div class="col-md-6">
                      <div class="row">
                        <div class="col-md-6">
                          <label>DATA REFÊRENCIA</label>
                          <cs-multiselect v-model="referenceDateType" :options="dateOptions" label="name" placeholder="Selecione a data de referência" selected-label="" deselect-label=""></cs-multiselect>
                        </div>
                        <div class="col-md-6" v-show="showDatePicker">
                          <c-date-picker class="default-margin-top" :range="false" :shortcuts="shortcuts" v-model="referenceDate" :not-after="lastDate" :not-before="initialDate" :disabled-days="disabledDays"></c-date-picker>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="row">
                    <div class="col-md-6">
                      <button class="btn-submit default-margin-top" @click="updateOffers">
                        Atualizar
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <div class="row">
                <div class="col-md-12 panel-heading">
                  <span class="clickable" style="font-size: 16px; font-weight: bolder;" @click="exportOffers">
                    <div class="loader loader-tiny" style="display: inline-block;" v-if="exportOffersLoading"></div>
                    <span v-else  class="glyphicon glyphicon-download-alt"></span>
                    Exportar Ofertas Só EMB
                  </span>
                </div>
              </div>

              <div class="row">
                <div class="col-md-6 col-sm-12">
                  <label>VISUALIZAÇÃO</label>
                  <div class="tiny-margin-left">
                    <input type="checkbox" v-model="farmHuntBreakDown" style="margin-right: 5px;"><label>FARM/HUNT</label>
                    <input type="checkbox" v-model="soldStockBreakDown" style="margin-left: 15px; margin-right: 5px;"><label>ESTOQUE ESGOTADO</label>
                    <template v-if="historySelectionType == 'single_date'">
                      <input type="checkbox" v-model="proportionalBars" style="margin-left: 15px; margin-right: 5px;"><label>BARRAS PROPORCIONAIS</label>
                      <input type="checkbox" v-model="alfabeticalOrdering" style="margin-left: 15px; margin-right: 5px;"><label>ORDENAÇÃO ALFABÉTICA</label>
                    </template>
                  </div>
                </div>
              </div>

              <base-chart ref="offersChart" export-name="comparativo_ofertas_emb" :base-height="390 " v-show="!proportionalBars"></base-chart>
              <div id="offers-bars" v-show="proportionalBars">&nbsp;</div>
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
import Multiselect from 'vue-multiselect';
import BaseChart from './base-chart';
import LocationFilter from './location-filter';
import CDatePicker from './custom-date-picker'

export default {
  data() {
    return {
      dateRange: [],
      shortcuts: [],
      totalIes: null,
      historySelectionType: 'single_date',
      filterOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      dealOwnerOptions: [],
      accountTypeOptions: [],
      kindOptions: [],
      levelOptions: [],

      statesOptions: [],
      regionsOptions: [],
      citiesOptions: [],
      groupingType: null,

      filterKinds: null,
      filterLevels: null,
      iesRegion: null,

      tableData: [],
      table: null,

      loadingFilters: true,
      dataLoading: false,
      iesLoading: false,
      iesStatesLoading: false,
      offersLoading: false,

      farmHuntBreakDown: false,
      soldStockBreakDown: false,
      proportionalBars: false,
      //proportionalBars: true,

      alfabeticalOrdering: false,

      groupingOptions: [
        { id: 'state', name: 'Estado'},
        { id: 'city', name: 'Cidade'}
      ],

      iesLocationOptions: [
        { type: 'states', name: 'Estados'},
        { type: 'regions', name: 'Regiões'},
      ],

      locationOptions: [
        { type: 'states', name: 'Estados'},
        { type: 'cities', name: 'Cidades'},
        { type: 'regions', name: 'Regiões'},
      ],

      dateOptions: [
        { type: 'last', name: 'Ultima disponível'},
        { type: 'custom', name: 'Customizada'},
      ],

      showIESActive: true,
      showOffersActive: false,
      exportOffersLoading: false,
      exportIesLoading: false,

      offersData: [],
      shortcuts: [],
      lastDate: null,
      initialDate: null,

      filtersOptions: [
        { type: 'university', name: 'IES'},
        { type: 'group', name: 'Grupo'},
        { type: 'account_type', name: 'Carteira'},
        { type: 'deal_owner', name: 'Farmer'}
      ],
      referenceDateType: null,
      referenceDate: null,
      disabledDays: [],
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    BaseChart,
    LocationFilter,
    CDatePicker,
  },
  watch: {
    farmHuntBreakDown: function (value) {
      this.$nextTick(() => {
        this.updateOffersChart();
        this.updateProportionalBarsChart();
      });
    },
    soldStockBreakDown: function (value) {
      this.$nextTick(() => {
        this.updateOffersChart();
        this.updateProportionalBarsChart();
      });
    },
    proportionalBars: function (value) {
      this.$nextTick(() => {
        this.updateOffersChart();
        this.updateProportionalBarsChart();
      });
    },
    alfabeticalOrdering: function (value) {
      this.$nextTick(() => {
        this.updateOffersChart();
        this.updateProportionalBarsChart();
      });
    }
  },
  computed: {
    showDatePicker() {
      if (_.isNil(this.referenceDateType)) {
        return false;
      }
      return this.referenceDateType.type == 'custom';
    },
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    CrawlerChannel.on('filterData', (payload) => this.receiveFilters(payload));
    CrawlerChannel.on('iesData', (payload) => this.receiveIesData(payload));
    CrawlerChannel.on('offerData', (payload) => this.receiveOfferData(payload));
    CrawlerChannel.on('iesPerStateData', (payload) => this.receiveIesPerStateData(payload));
    CrawlerChannel.on('downloadData', (payload) => this.receiveDownloadData(payload));
    CrawlerChannel.on('downloadIesData', (payload) => this.receiveDownloadIesData(payload));
    CrawlerChannel.on('downloadNoData', (payload) => this.receiveDownloadNoData(payload));

    this.referenceDateType = this.dateOptions[0];
    this.groupingType = this.groupingOptions[0];
    this.loadFilters();
  },
  methods: {
    updateProportionalBarsChart() {
      let offerData = this.offersData;



      let labels = [];
      labels.push('Só QB')
      labels.push('QB Melhor');
      if (this.soldStockBreakDown) {
        labels.push('EMB melhor - QB Melhor Esgotado');
      }
      labels.push('Igual');
      if (this.soldStockBreakDown) {
        labels.push('EMB melhor - QB Igual Esgotado');
        labels.push('EMB melhor');
      } else {
        labels.push('EMB melhor');
      }
      if (this.farmHuntBreakDown) {
        labels.push('Só EMB - FARM');
        labels.push('Só EMB - HUNT');
      } else {
        labels.push('Só EMB');
      }
      labels.push('Devry');

      labels = labels.reverse();

      d3.select('#offers-div-id').remove();

      let colors = [];
      let zipped = [];

      if (!this.farmHuntBreakDown && !this.soldStockBreakDown) {
        zipped = _.zip(offerData["chaves"], offerData["total"], offerData["grupo_devry"], offerData["so_emb"], offerData["emb_melhor"], offerData["igual"], offerData["qb_melhor"], offerData["so_qb"]);
        colors = ['red', '#ff9429', '#ffee00', '#00ec93', '#00afc7', '#004c5c'];
      } else if (this.farmHuntBreakDown && !this.soldStockBreakDown) {
        zipped = _.zip(offerData["chaves"], offerData["total"], offerData["grupo_devry"], offerData["so_emb_qb_hunt"], offerData["so_emb_qb_farm"], offerData["emb_melhor"], offerData["igual"], offerData["qb_melhor"], offerData["so_qb"]);
        colors = ['red', 'brown', 'orange', '#ffee00', '#00ec93', '#00afc7', '#004c5c'];
      } else if (!this.farmHuntBreakDown && this.soldStockBreakDown) {
        zipped = _.zip(offerData["chaves"], offerData["total"], offerData["grupo_devry"], offerData["so_emb"], offerData["emb_melhor_qb_not"], offerData["emb_melhor_qb_sold_equal"], offerData["igual"], offerData["emb_melhor_qb_sold_melhor"], offerData["qb_melhor"], offerData["so_qb"]);
        colors = ['red', '#ff9429', '#ffee00', '#ff8400', '#00ec93', '#00869c', '#00afc7', '#004c5c'];
      } else {
        zipped = _.zip(offerData["chaves"], offerData["total"], offerData["grupo_devry"], offerData["so_emb_qb_hunt"], offerData["so_emb_qb_farm"], offerData["emb_melhor_qb_not"], offerData["emb_melhor_qb_sold_equal"], offerData["igual"], offerData["emb_melhor_qb_sold_melhor"], offerData["qb_melhor"], offerData["so_qb"]);
        colors = ['red', 'brown', 'orange', '#ffee00', '#ff8400', '#00ec93', '#00869c', '#00afc7', '#004c5c'];
      }

      if (this.alfabeticalOrdering) {
        zipped.sort();
      }

      let mapped = _.map(zipped, (entry) => {
        return { 'key': entry[0], total: entry[1], 'vector': entry.splice(2, entry.length) };
      });

      var width = 800, height = 200, marginLeft = 20, marginRight = 10;
      var marginTop = 3;
      var marginBottom = 30;

      var x = d3.scale.linear().range([0, width - marginLeft - marginRight]);
      var y = d3.scale.linear().range([0, height - marginTop - marginBottom]);
      var n = d3.format(",d"), p = d3.format("%");


      var tooltip = d3.select("body")
        .append("div")
        .style("opacity", 0)
        .style("position", "absolute")
        .style("background-color", "black")
        .style("border", "solid")
        .style("border-width", "1px")
        .style("border-radius", "5px")
        .style("padding", "10px")

      var svgOffers = d3.select("#offers-bars")
         .append("div")
         .attr('id', 'offers-div-id')
         .append("svg")
         .attr("viewBox", `0 0 ${width} ${height}`)

         .append("g")
         .attr("transform", "translate(" + marginLeft + "," + marginTop + ")");



      var sumTotal = 0;
      _.forEach(mapped, (entry) => {
        sumTotal += eval(entry.total);
      });

      var mappedSum = mapped.reduce((accumulator, entry) => {
        entry.offset = accumulator;
        entry.sum = accumulator + eval(entry.total)
        entry.valuesSum = 0;
        let valuesIndex = 0;
        entry.values = _.map(entry.vector, (value) => {
          let valueEntry = {
            'value': eval(value),
            'offset': entry.valuesSum,
            'color': colors[valuesIndex],
            'parent': entry,
            'label': labels[valuesIndex]
          };
          entry.valuesSum = entry.valuesSum + eval(value);
          valuesIndex++;
          return valueEntry
        });
        return entry.sum;
      }, 0);



     var groupKeys = svgOffers.selectAll(".group_key")
       .data(mapped)
     .enter().append("g")
       .attr("class", "group_key")
       .attr("xlink:title", function(d) {
          return d.key; })
       .attr("transform", function(d) {
          return "translate(" + x(d.offset / mappedSum) + ")";
        }); //.append('text').text('TTT');

    //console.log("groupKeys: " + JSON.stringify(Object.keys(groupKeys[0][0])));

      //gera um vetor de causas
        //sao as barras dentro de um mes ( group_key no nosso caso )
      // Add a rect for each month.
      var parts = groupKeys.selectAll (".group_key")
        .data(function(d) {
           return d.values; })
        .enter().append("a")
        .attr("class", "group_key");

      parts.append("rect")
        .attr("y", function(d) {
           return y(d.offset / d.parent.valuesSum); })
        .attr("height", function(d) {
           return y(d.value / d.parent.valuesSum); })
        .attr("width", function(d) {
           return x(d.parent.total / mappedSum); })
        .style("fill", function(d) {
           return d.color;
        }).on('mouseover', function (d) {
          tooltip.style("opacity", 1)
            .html('<b><span style="color: white;">' + d.parent.key + '</span></b><br><div style="display: flex; align-items: center;"><div style="display: inline-block; width: 10px; height: 10px; margin-right: 5px; background-color: ' + d.color + ';">&nbsp</div><span style="color: white; font-size: 14px;">' + d.label + ": " + d.value + " %</span></div>");
        }).on('mouseout', function (d) {
          tooltip.style("opacity", 0);
        }).on('mousemove', function (d) {
          //console.log("MOUSE: " + JSON.stringify(d3.mouse(this)) + " EVT: " + d3.event.pageX + " - " + d3.event.pageY);
          tooltip
            .style("left", (d3.event.pageX) + "px")
            .style("top", (d3.event.pageY + 28) + "px");
        });

      svgOffers.selectAll(".group_key").each(function (d) {
        if (d.total > 300) {
          d3.select(this)
            .append('text')
            .text(d.key)
            .attr("y", height - marginBottom + 8)
            //.attr("x", (d.parent.total / mappedSum) / 2)
            .attr("font-family", "proxima-nova")
            .attr("font-size", "8px")
            .style("fill", "white")
          }
      });


      //legends
      let currentX = 25;
      _.forEach(_.zip(labels, colors).reverse(), (entry) => {
        //console.log("entry: " + entry[0] + " color: " + entry[1]);
        svgOffers.append("circle").attr("cx",currentX).attr("cy",height - marginBottom + 20).attr("r", 4).style("fill", entry[1])
        let textInfo =  svgOffers.append("text").attr("x", currentX + 8).attr("y", height - marginBottom + 20).text(entry[0]).style("font-size", "8px").style("fill", "white").attr("alignment-baseline","middle")
        //console.log("textInfo: " + JSON.stringify(textInfo.node().getComputedTextLength()));

        //entry[0]
        currentX += textInfo.node().getComputedTextLength() + 20;
      });

      //Y axis

      // Create scale
      var scale = d3.scale.linear()
                    .domain([100, 0])
                    .range([0, height - marginTop - marginBottom]);

      // Add scales to axis
      var yAxis = d3.svg.axis().scale(scale).orient("left").tickFormat(function (d) {
          d3.select(this).attr('font-size', '8px').style('fill', 'white')
          return d;
      });

      //Append group and insert axis
      svgOffers.append("g")
         .call(yAxis, function (d) {
           //d3.select(this).style('fill', 'white');
         });

      svgOffers.select(".domain").remove();

    },
    showIES() {
      this.showIESActive = true;
      this.showOffersActive = false;

      this.$nextTick(() => {
        this.$refs.iesStatesChart.updateChart();
      });
    },
    showOffers() {
      this.showIESActive = false;
      this.showOffersActive = true;

      this.$nextTick(() => {
        this.$refs.offersChart.updateChart();
      });
    },
    drawIesCharts(qb, emb, intersection) {
      let qbKey = `QB - ${qb}`;
      let embKey = `EMB - ${emb}`;
      let allKey = `${intersection}`

      // var sets = [
      //   {sets: [qbKey], size: qb + intersection},
      //   {sets: [embKey], size: emb + intersection},
      //   {sets: [qbKey,embKey], size: intersection, label: allKey}];

      var sets = [
        {sets: [qbKey], size: 200},
        {sets: [embKey], size: 200},
        {sets: [qbKey,embKey], size: 100, label: allKey}];

      //d3.select('#ies').select('svg').remove();

      let width = 500;
      let height = 300;

      var colours = ['#35b6cc', '#fdc029'];
      var chart = venn.VennDiagram().width(width).height(height);
      d3.select("#ies").datum(sets).call(chart);

      const vennDiv = document.getElementById("ies");
      const vennSvg = vennDiv.children[0];

      vennSvg.removeAttribute("height");
      vennSvg.removeAttribute("width");
      vennSvg.setAttribute("viewBox", `0 0 ${width} ${height}`);

      d3.selectAll("#ies .venn-circle path")
        .style("fill", function(d,i) { return colours[i]; })

      d3.selectAll("#ies .venn-circle text")
        .style("fill", function(d,i) { return colours[i]})
        .style("font-weight", "100")
        .style("font-size", "36px");

      d3.selectAll("#ies text")
        .style("fill", function(d,i) { return colours[i]})
        .style("font-weight", "100")
        .style("font-size", "36px");

    },
    primaryFilterSelected(data) {
      console.log('primaryFilterSelected data: ' + JSON.stringify(data));
    },
    receiveFilters(data) {
      //console.log('receiveFilters data: ' + JSON.stringify(data));
      this.universityOptions = data.universities;
      this.filterOptions = data.filters;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      this.citiesOptions = data.cities;
      this.regionsOptions = data.regions;
      this.statesOptions = data.states;

      this.dealOwnerOptions = data.dealOwners;
      this.accountTypeOptions = data.accountTypes;
      this.universityGroupOptions = data.groups;

      this.loadingFilters = false;

      this.initialDate = moment(data.initial_date_filter).toDate();
      this.lastDate = moment(data.final_date_filter).toDate();

      this.dateRange = [ this.initialDate, this.lastDate];

      this.disabledDays = _.map(data.missing_days, (entry) => {
        return moment(entry).toDate();
      });

      this.updateOffers();
      this.loadIesPerState();
    },
    receiveOfferData(data) {
      this.offersData = data;
      this.updateProportionalBarsChart();
      this.updateOffersChart();

      this.offersLoading = false;
    },
    updateOffersChart() {

      let updateData = this.offersData;

      //console.log("updateData: " + JSON.stringify(updateData));

      if (this.alfabeticalOrdering) {
        let zipped = _.zip(this.offersData['chaves'],
              this.offersData['so_qb'],
              this.offersData['qb_melhor'],
              this.offersData['emb_melhor_qb_sold_melhor'],
              this.offersData['igual'],
              this.offersData['emb_melhor_qb_sold_equal'],
              this.offersData['emb_melhor_qb_not'],
              this.offersData['emb_melhor'],
              this.offersData['so_emb_qb_farm'],
              this.offersData['so_emb_qb_hunt'],
              this.offersData['so_emb'],
              this.offersData['grupo_devry']);

        zipped.sort();

        updateData = _.reduce(zipped, (accumulator, entry) => {
          console.log("entry: " + JSON.stringify(entry) + " accumulator: " + JSON.stringify(accumulator));
          accumulator.chaves.push(entry[0]);
          accumulator.so_qb.push(entry[1]);
          accumulator.qb_melhor.push(entry[2]);
          accumulator.emb_melhor_qb_sold_melhor.push(entry[3]);
          accumulator.igual.push(entry[4]);
          accumulator.emb_melhor_qb_sold_equal.push(entry[5]);
          accumulator.emb_melhor_qb_not.push(entry[6]);
          accumulator.emb_melhor.push(entry[7]);
          accumulator.so_emb_qb_farm.push(entry[8]);
          accumulator.so_emb_qb_hunt.push(entry[9]);
          accumulator.so_emb.push(entry[10]);
          accumulator.grupo_devry.push(entry[11]);
          return accumulator;
        }, {
          chaves: [],
          so_qb: [],
          qb_melhor: [],
          emb_melhor_qb_sold_melhor: [],
          igual: [],
          emb_melhor_qb_sold_equal: [],
          emb_melhor_qb_not: [],
          emb_melhor: [],
          so_emb_qb_farm: [],
          so_emb_qb_hunt: [],
          so_emb: [],
          grupo_devry: []
        });
      }

      //console.log("updateData: SORTED: " + JSON.stringify(updateData));

      this.$refs.offersChart.clearSeries();
      this.$refs.offersChart.setLabels(updateData.chaves);

      this.$refs.offersChart.setSeriesWithOptions(0, updateData.so_qb, 'Só QB', { seriesColor: '#004c5c'});
      this.$refs.offersChart.setSeriesWithOptions(1, updateData.qb_melhor, 'QB Melhor', { seriesColor: '#00afc7'});

      let currentIndex = 1;
      if (this.soldStockBreakDown) {
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.emb_melhor_qb_sold_melhor, 'EMB melhor - QB Melhor Esgotado', { seriesColor: '#00869c'});
      }

      currentIndex++;
      this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.igual, 'Igual', { seriesColor: '#00ec93'});

      if (this.soldStockBreakDown) {
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.emb_melhor_qb_sold_equal, 'EMB melhor - QB Igual Esgotado', { seriesColor: '#ff8400'});
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.emb_melhor_qb_not, 'EMB melhor', { seriesColor: '#ffee00'});
      } else {
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.emb_melhor, 'EMB melhor', { seriesColor: '#ffee00'});
      }

      if (this.farmHuntBreakDown) {
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.so_emb_qb_farm, 'Só EMB - FARM', { seriesColor: 'orange'});
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.so_emb_qb_hunt, 'Só EMB - HUNT', { seriesColor: 'brown'});
      } else {
        currentIndex++;
        this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.so_emb, 'Só EMB', { seriesColor: '#ff9429'});
      }
      currentIndex++;
      this.$refs.offersChart.setSeriesWithOptions(currentIndex, updateData.grupo_devry, 'Devry', { seriesColor: 'red'});

      this.$refs.offersChart.setXAxesStacked();
      this.$refs.offersChart.setYAxesStacked();

      this.$refs.offersChart.setYMax(100);

      this.$nextTick(() => {
        this.$refs.offersChart.updateChart();
      });
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
    receiveDownloadNoData(data) {
      if (data.type == 'offers') {
        alert('Sem ofertas para exportar');
        this.exportOffersLoading = false;
      } else {
        alert('Sem IES para exportar');
        this.exportIESLoading = false;
      }
    },
    receiveDownloadIesData(data) {
      this.saveXlsx(data.xlsx, data.filename, data.contentType);
      this.exportIESLoading = false;
    },
    receiveDownloadData(data) {
      this.saveXlsx(data.xlsx, data.filename, data.contentType);
      this.exportOffersLoading = false;
    },
    receiveIesPerStateData(data) {
      console.log("receiveIesPerStateData#" + JSON.stringify(data));

      this.$refs.iesStatesChart.setLabels(data.keys);

      this.$refs.iesStatesChart.setSeriesWithOptions(0, data.so_qb, 'Só QB', { seriesColor: '#00afc7' });
      this.$refs.iesStatesChart.setSeriesWithOptions(1, data.qb_e_emb, 'QB e EMB', { seriesColor: '#00ec93' });
      this.$refs.iesStatesChart.setSeriesWithOptions(2, data.so_emb, 'Só EMB', { seriesColor: 'red' });

      this.$refs.iesStatesChart.setXAxesStacked();
      this.$refs.iesStatesChart.setYAxesStacked();

      this.$refs.iesStatesChart.setYMax(100);

      this.$nextTick(() => {
        this.$refs.iesStatesChart.updateChart();
      });

      this.iesStatesLoading = false;
    },
    receiveIesData(data) {
      this.totalIes = data.total;

      this.drawIesCharts(data.so_qb, data.so_emb, data.qb_e_emb);
      this.iesLoading = false;
    },
    iesParamsMap() {
      return {
        locationType: this.$refs.locationFilterIes.locationFilter(),
        locationValue: this.$refs.locationFilterIes.locationValue()
      };
    },
    loadIesPerState() {
      if (!this.$refs.locationFilterIes.validateFilter()) {
        return false;
      }
      let params = this.iesParamsMap();

      d3.select('#ies').select('svg').remove();

      this.iesStatesLoading = true;
      this.iesLoading = true;
      CrawlerChannel.push('loadIesPerState', params).receive('timeout', (data) => {
        console.log('loadIesPerState timeout');
      });
    },
    updateIesStats() {
      this.loadIesPerState();
    },
    offersFiltersMap() {
      let params = this.$refs.filter.filterSelected() || {};

      params.groupingType = this.groupingType;
      params.locationType = this.$refs.locationFilter.locationFilter();
      params.locationValue = this.$refs.locationFilter.locationValue();
      params.historyType = this.historySelectionType;

      if (this.historySelectionType == 'single_date') {

        if (this.referenceDateType.type == 'custom') {
          params.dateFilter = this.referenceDate;
        }
      } else {
        params.initialDate = this.dateRange[0];
        params.finalDate = this.dateRange[1];
      }

      return params;
    },
    updateOffers() {
      if (!this.$refs.locationFilter.validateFilter()) {
        return false;
      }

      if(!this.$refs.filter.validateFilter()) {
        return false;
      }

      if (this.referenceDateType.type == 'custom') {
        if (_.isNil(this.referenceDate)) {
          alert('Selecione a data de referência');
          return false;
        }
      }

      let params = this.offersFiltersMap();

      this.offersLoading = true;
      CrawlerChannel.push('loadOffersData', params).receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    exportIes() {
      if (this.exportIesLoading) {
        return;
      }
      this.exportIesLoading = true;

      let params = this.iesParamsMap();

      CrawlerChannel.push('downloadMissingIES', params).receive('timeout', (data) => {
        console.log('exportOffers timeout');
      });
    },
    exportOffers() {
      if (this.exportOffersLoading) {
        return;
      }
      let params = this.offersFiltersMap();

      this.exportOffersLoading = true;

      CrawlerChannel.push('downloadMissingOffers', params).receive('timeout', (data) => {
        console.log('exportOffers timeout');
      });
    },
    loadFilters() {
      CrawlerChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
  },
};

</script>
