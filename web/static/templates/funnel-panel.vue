<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Funil KPI's
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

            <div class="row">
              <div class="col-md-6 col-sm-6">
                <div>
                  <label for="kind-filter">UNIVERSIDADE</label>
                  <cs-multiselect v-model="filterUniversity" :options="universityOptions" label="name" track-by="id" placeholder="Selecione a universidade" selectLabel="" deselectLabel=""></cs-multiselect>
                </div>
              </div>
            </div>

            <div class="row">
              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="level-filter">NÍVEIS</label>
                  <multiselect v-model="filterLevels" :multiple="true" :options="levelOptions" label="name" track-by="id" placeholder="Todos os níveis" selectLabel="" deselectLabel=""></multiselect>
                </div>
              </div>

              <div class="col-md-2 col-sm-6">
                <div>
                  <label for="kind-filter">MODALIDADES</label>
                  <multiselect v-model="filterKinds" :multiple="true" :options="kindOptions" label="name" track-by="id" placeholder="Todas as modalidades" selectLabel="" deselectLabel=""></multiselect>
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
        <div id="funnel"></div>
      </div>
    </div>

    <!-- div class="row" v-if="hasData">
      <div class="col-md-12">
        <div class="panel report-panel panel-default">
          <table id="search-table" class="data-table data-table-tiny">
            <thead>
              <tr>
                <th>offer_id</th>
                <th>course_id</th>
                <th>IES</th>
                <th>Curso</th>
                <th>Desconto</th>
                <th>Modalidade</th>
                <th>Nível</th>
                <th>Turno</th>
                <th>Preço Oferecido</th>
                <th>Relevance Score</th>
                <th>Cidade</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in tableData">
                <td>{{ entry.offer_id }}</td>
                <td>{{ entry.course_id }}</td>
                <td>{{ entry.university_name }}</td>
                <td>{{ entry.course_name }}</td>
                <td>{{ entry.discount_percentage }}</td>
                <td>{{ entry.course_kind }}</td>
                <td>{{ entry.course_level }}</td>
                <td>{{ entry.course_shift }}</td>
                <td>{{ entry.offered_price }}</td>
                <td>{{ entry.relevance_score }}</td>
                <td>{{ entry.city }}</td>
                <td>{{ entry.state }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div -->

  </div>
</template>


<script>
import _ from 'lodash'

import PanelPrimaryFilter from './panel-primary-filter';
import moment from 'moment';
import DataTable from "../js/components/datatable";
import CsMultiselect from './custom-search-multiselect';
import Multiselect from 'vue-multiselect'
import LocationFilter from './location-filter';
import BaseChart from './base-chart'

import exportToCsv from "../js/utils/export";

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
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      coursesOptions: [],
      //meanRank: null,

      filterKinds: [],
      filterLevels: [],
      //filterCity: null,

      tableData: [],
      table: null,
      hasChartData: false,

      loadingFilters: true,
      dataLoading: false,
      currentFilter: null,
      filterCourse: null,
    }
  },
  components: {
    PanelPrimaryFilter,
    CsMultiselect,
    Multiselect,
    LocationFilter,
    BaseChart,
  },
  computed: {
    hasData() {
      return this.tableData.length > 0;
    },
  },
  mounted() {
    FunnelChannel.on('filters', (payload) => this.receiveFilters(payload));
    FunnelChannel.on('tableData', (payload) => this.receiveTableData(payload));

    this.loadFilters();
    //console.log("this.$route.query: " + window.location.search);


  },
  methods: {
    drawFunnel(data) {
      let width = 800;
      let height = 500;
      let horizontalMargin = 20;
      let marginTop = 20;

      d3.select('#funnel-div-id').remove();

      var svgFunnel = d3.select("#funnel")
               .append("div")
               //id, so we can clean it
               .attr('id', 'funnel-div-id')
               .append("svg")
               .attr("viewBox", `0 0 ${width} ${height}`)
               .append("g")
               .attr("transform", "translate(" + horizontalMargin + "," + marginTop + ")");


      var xScale = d3.scale.linear().range([0, width]);
      var yScale = d3.scale.linear().range([0, height]);

      //var trianglePoints = xScale(3) + ' ' + yScale(18) + ', ' + xScale(1) + ' ' + yScale(0) + ', ' + xScale(12) + ' ' + yScale(3) + ' ' + xScale(12) + ', ' + yScale(3) + ' ' + xScale(3) + ' ' + yScale(18);
      let funnelFullSize = 500;
      let rowHeigth = 70;
      let deslocation = 30;


      var visitsPart = `0 0, ${funnelFullSize} 0, ${funnelFullSize - deslocation} ${rowHeigth}, ${deslocation} ${rowHeigth}, 0 0`;
      var ordersPart = `${deslocation} ${rowHeigth}, ${funnelFullSize - deslocation} ${rowHeigth}, ${funnelFullSize - 2 * deslocation} ${2 * rowHeigth}, ${2 * deslocation} ${2 * rowHeigth}, ${deslocation} ${rowHeigth}`;
      var paidsPart = `${2 * deslocation} ${ 2 * rowHeigth}, ${funnelFullSize - 2 * deslocation} ${2 * rowHeigth}, ${funnelFullSize - 3 * deslocation} ${3 * rowHeigth}, ${3 * deslocation} ${3 * rowHeigth}, ${2 * deslocation} ${2 * rowHeigth}`;
      var revenuePart = `${3 * deslocation} ${ 3 * rowHeigth}, ${funnelFullSize - 3 * deslocation} ${3 * rowHeigth}, ${funnelFullSize - 4 * deslocation} ${4 * rowHeigth}, ${4 * deslocation} ${4 * rowHeigth}, ${3 * deslocation} ${3 * rowHeigth}`;

      console.log(visitsPart);

      svgFunnel.append('polyline')
          .attr('points', visitsPart)
          .style('stroke', 'blue')
          .style('fill', '#333333');


      let text = svgFunnel.append('text').text('VISITAS').style('fill', 'white')
      let textLength = text.node().getComputedTextLength();
      text.attr('y', rowHeigth / 2).attr('x', (funnelFullSize - textLength) / 2);

      text = svgFunnel.append('text').text(data.visits).style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', (rowHeigth / 2) + 15).attr('x', (funnelFullSize - textLength) / 2);

      svgFunnel.append('polyline')
          .attr('points', ordersPart)
          .style('stroke', 'blue')
          .style('fill', '#333333');

      text = svgFunnel.append('text').text('ATRATIVIDADE').style('fill', 'white');
      textLength = text.node().getComputedTextLength();
      text.attr('y', 1.5 * rowHeigth).attr('x', (funnelFullSize - textLength) / 2);

      text = svgFunnel.append('text').text(data.atraction_rate).style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', (1.5 * rowHeigth) + 15).attr('x', (funnelFullSize - textLength) / 2);

      svgFunnel.append('polyline')
          .attr('points', paidsPart)
          .style('stroke', 'blue')
          .style('fill', '#333333');

      text = svgFunnel.append('text').text('SUCESSO').style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', 2.5 * rowHeigth).attr('x', (funnelFullSize - textLength) / 2);
      text = svgFunnel.append('text').text(data.success_rate).style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', (2.5 * rowHeigth) + 15).attr('x', (funnelFullSize - textLength) / 2);

      svgFunnel.append('polyline')
          .attr('points', revenuePart)
          .style('stroke', 'blue')
          .style('fill', '#333333');

      text = svgFunnel.append('text').text('PEF').style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', 3.5 * rowHeigth).attr('x', (funnelFullSize - textLength) / 2);

      text = svgFunnel.append('text').text(data.mean_ticket).style('fill', 'white')
      textLength = text.node().getComputedTextLength();
      text.attr('y', (3.5 * rowHeigth) + 15).attr('x', (funnelFullSize - textLength) / 2);


      var arc = d3.svg.arc()
          .innerRadius(35)
          .outerRadius(40)
          .startAngle(45 * (Math.PI/180)) //converting from degs to radians
          .endAngle(3)
           //just radians


     var seta = `20 20, 0 10, 20 0`;
     // var arc1 = d3.svg.arc()
     //     .innerRadius(15)
     //     .outerRadius(20)
     //     .startAngle(-45 * (Math.PI/180)) //converting from degs to radians
     //     .endAngle(-20 * (Math.PI/180))

     svgFunnel.append('polyline')
         .attr('points', seta)
         .style('stroke', 'blue')
         .style('fill', 'blue')
         .attr("transform", `translate(${funnelFullSize - 5}, ${rowHeigth + 25})`)

      svgFunnel.append("path")
          .attr("d", arc)
          .attr("transform", `translate(${funnelFullSize}, ${rowHeigth})`)
          .style('fill', 'blue')


      text = svgFunnel.append('text').text('ORDENS').style('fill', 'white')
      text.attr('y', rowHeigth).attr('x', funnelFullSize + 43);

      text = svgFunnel.append('text').text(data.initiated_orders).style('fill', 'white')
      text.attr('y', rowHeigth + 15).attr('x', funnelFullSize + 43);


      svgFunnel.append("path")
          .attr("d", arc)
          .attr("transform", `translate(${funnelFullSize}, ${rowHeigth * 2})`)
          .style('fill', 'blue')

      svgFunnel.append('polyline')
          .attr('points', seta)
          .style('stroke', 'blue')
          .style('fill', 'blue')
          .attr("transform", `translate(${funnelFullSize - 5}, ${2 * rowHeigth + 25})`)


      text = svgFunnel.append('text').text('PAGOS').style('fill', 'white')
      text.attr('y', 2 * rowHeigth).attr('x', funnelFullSize + 43);

      text = svgFunnel.append('text').text(data.paid_follow_ups).style('fill', 'white')
      text.attr('y', 2 * rowHeigth + 15).attr('x', funnelFullSize + 43);


      svgFunnel.append("path")
          .attr("d", arc)
          .attr("transform", `translate(${funnelFullSize}, ${rowHeigth * 3})`)
          .style('fill', 'blue')

      svgFunnel.append('polyline')
          .attr('points', seta)
          .style('stroke', 'blue')
          .style('fill', 'blue')
          .attr("transform", `translate(${funnelFullSize - 5}, ${3 * rowHeigth + 25})`)

      text = svgFunnel.append('text').text('RECEITA').style('fill', 'white')
      text.attr('y', 3 * rowHeigth).attr('x', funnelFullSize + 43);

      text = svgFunnel.append('text').text(data.total_revenue).style('fill', 'white')
      text.attr('y', 3 * rowHeigth + 15).attr('x', funnelFullSize + 43);

      // svgFunnel.append("path")
      //     .attr("d", arc1)
      //     .attr("transform", `translate(${funnelFullSize}, ${rowHeigth})`)
      //     //.style('stroke', 'blue')
      //     .style('fill', 'blue')

    },
    receiveTableData(data) {
      this.tableData = data.table;

      this.drawFunnel(data.table);

      console.log("table: " + JSON.stringify(data.table));

      // this.$nextTick(() => {
      //   this.table = new DataTable('#search-table', {
      //     paging: true,
      //     deferRender: true,
      //     searchDelay: 500,
      //     pageLength: 30,
      //     order: [ 9, 'desc' ],
      //   });
      // });

      this.dataLoading = false;
    },
    receiveFilters(data) {
      this.universityOptions = data.universities;
      this.kindOptions = data.kinds;
      this.levelOptions = data.levels;
      // this.filterOptions = data.filters;
      // this.locationOptions = data.locationTypes;
      // this.citiesOptions = data.cities;
      // this.coursesOptions = data.courses;
      //
      // this.filterLevels = [ this.levelOptions[0] ];

      this.loadingFilters = false;
    },
    loadFilters() {
      FunnelChannel.push('loadFilters').receive('timeout', (data) => {
        console.log('filters timeout');
      });
    },
    loadData() {
      if (_.isNil(this.filterUniversity)) {
        alert('Selecione a Universidade');
        return;
      }
      this.dataLoading = true;
      this.tableData = [];

      let filter = {
        kinds: this.filterKinds,
        levels: this.filterLevels,
        university: this.filterUniversity,
      };

      FunnelChannel.push('loadData', filter).receive('timeout', (data) => {
        console.log('loadData timeout');
      });
    }
  },
};

</script>
