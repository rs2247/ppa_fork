import Dropdown from './components/dropdown';
import DatePicker from "./components/datepicker";
import moment from 'moment';
import AjaxRequest from "./components/ajax";
import Authentication from "./components/authentication";
import SimpleChart from "./components/simple-chart";
import MessageDialog from "./components/message-dialog";
import UniversityFilter from "./components/universityFilter";
import AppObject from "./utils/object";
import $ from 'jquery'

let select2 = require('select2')();

const PAGE_URL = 'university_charts';
const CHART_URL = `/${PAGE_URL}/generate`;

const TITLES = [
  'Visitas',
  'Ordens',
  'Ordens Pagas',
  'Atratividade (%)',
  'Sucesso (%)',
  'Conversão (%)',
  'Faturamento por Ordem (R$)',
  'Ticket Médio (CP) (R$)'
];

const COLORS = {'main': '#18ACC4', 'comparison': '#F4B342', 'base': '#DF5E4E'};

const DATE_FORMAT = 'DD/MM/YYYY';

class UniversityChartsPage {

  setup() {
    this.$levelFilterSelect = $('.js-levels-multi-select');
    this.$levelFilterSelect.select2({width: "resolve", height: "resolve", placeholder: "Todos"});
    this.$kindFilterSelect = $('.js-kinds-multi-select');
    this.$kindFilterSelect.select2({width: "resolve", height: "resolve", placeholder: "Todos"});
    this.startDatePicker = new DatePicker("start-date");
    this.endDatePicker = new DatePicker("end-date");
    this.universityComparisonFilter = new UniversityFilter({
      subject: 'comparison'
    });

    this.universityFilter = new UniversityFilter({
      afterInitialSelection: this.updateReport.bind(this)
    });
    this.exportButton = $('.js-export-csv');

    $("#filters-form").submit((evt) => {
      evt.preventDefault();
      this.updateReport();
      $('.js-export-csv').addClass('hidden');
    });

    this.updateRequest = new AjaxRequest({
        url: CHART_URL,
        onLoadOverlayElement: $(".report-panel")
    });
    this.loadInitialFilterValues();
    this.configCsvExport();

    this.universityComparisonFilter.loadInitialValues();
    // this must be the last thing done here because it will trigger the chart generation on after page load when
    // there is a selected university
    this.universityFilter.loadInitialValues();
    UniversityChartsPage.afterShowReport();
  }

  loadInitialFilterValues() {
    let today = moment().toDate();
    let sevenDaysBehind = moment().subtract(7, 'days').toDate();

    let startDate = $("#initial-start-date").val() || sevenDaysBehind;
    let endDate = $("#initial-end-date").val() || today;

    this.startDatePicker.setDate(startDate);
    this.endDatePicker.setDate(endDate);
  }

  _buildSeries(series, fieldName) {
    return series.map((serie) => ({
      name: serie['name'],
      data: serie[fieldName],
      color: COLORS[serie['type']]
    }));
  }

  _buildSeriesWithBase(series, fieldName) {
    const mainSerie = series.find((s) => s.type === 'main');
    let comparisonSeries = this._buildSeries(series, fieldName);
    if (mainSerie.compare){
      comparisonSeries.unshift({
        name: 'Valor Base',
        data: mainSerie['base_' + fieldName],
        color: COLORS['base']
      });
    }
    return comparisonSeries;
  }

  updateChart(series) {
    const xAxisSerie = series.find((s) => s.type === 'main')['dates'];

    this.visitsChart = new SimpleChart('university-chart-visits', {
      title: TITLES[0],
      type: 'column',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'visits')
    });

    this.ordersChart = new SimpleChart('university-chart-orders', {
      title: TITLES[1],
      type: 'column',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'orders')
    });

    this.paidOrdersChart = new SimpleChart('university-chart-paid-orders', {
      title: TITLES[2],
      type: 'column',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'paid_orders')
    });

    this.attractivenessChart = new SimpleChart('university-chart-attractiveness', {
      title: TITLES[3],
      type: 'line',
      xAxisLabels: xAxisSerie,
      series: this._buildSeriesWithBase(series, 'attractiveness')
    });

    this.exclusivityChart = new SimpleChart('university-chart-exclusivity', {
      title: TITLES[4],
      type: 'line',
      xAxisLabels: xAxisSerie,
      series: this._buildSeriesWithBase(series, 'exclusivity')
    });

    this.conversionChart = new SimpleChart('university-chart-conversion', {
      title: TITLES[5],
      type: 'line',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'conversion')
    });

    this.studentPriceChart = new SimpleChart('university-chart-student-price', {
      title: TITLES[6],
      type: 'line',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'student_price')
    });

    this.averagePriceChart = new SimpleChart('university-chart-average-price', {
      title: TITLES[7],
      tooltip: TITLES[7].toLowerCase(),
      type: 'line',
      xAxisLabels: xAxisSerie,
      series: this._buildSeries(series, 'average_price')
    });
  }

  updateReport() {
    let queryString = {};
    let inputs = [];

    this.collectMainParameters(queryString, inputs);
    this.collectComparisonParameters(queryString, inputs);

    this.updateRequest.getParallel(inputs, (responses) => {
      let chartSeries = [];
      responses.forEach((response, idx) => {
        if (response["message"]) {
          const dialog = new MessageDialog("global-dialog", "warning", "Erro");
          dialog.show(response["message"]);
        } else {
          response['data']['type'] = inputs[idx]['type'];
          response['data']['compare'] = inputs[idx]['compare_with_base'];
          chartSeries.push(response['data']);
        }
      });
      this.updateChart(chartSeries);
      this.mainChartData = chartSeries.find((s) => s.type === 'main');
      // only show export button when not comparing
      if (chartSeries.length === 1) {
        this.exportButton.removeClass("hidden");
      }
      UniversityChartsPage.afterShowReport();
    });

    this.updatePageHistory(queryString);
  }

  updatePageHistory(data) {
    const params = $.param(data);
    window.history.pushState("", "", `${PAGE_URL}?${params}`);
  }

  collectMainParameters(queryString, requestParams) {
    const data = {
      start_date: this.startDatePicker.getValue(),
      end_date: this.endDatePicker.getValue(),
      admin_id: Authentication.getCurrentUserId(),
      level: this.$levelFilterSelect.val(),
      kind: this.$kindFilterSelect.val(),
      university_filter_type: this.universityFilter.universityTypeDropdown.getSelectedValue(),
      university_id: this.universityFilter.universityAutocomplete.getSelectedValue(),
      education_group_id: this.universityFilter.educationGroupAutocomplete.getSelectedValue(),
      compare_with_base: ($("#compare-with-base:checked").length > 0),
      type: 'main'
    };
    AppObject.removeIfNullOrEmpty(data);
    Object.assign(queryString, data);
    requestParams.push(data);
  }

  collectComparisonParameters(queryString, requestParams) {
    const filterType = this.universityComparisonFilter.universityTypeDropdown.getSelectedValue();
    if (filterType === 'year_over_year') {
      this.collectYearOverYearComparisonParameters(queryString, requestParams);
    } else if (['university', 'education_group'].includes(filterType)) {
      this.collectUniversityComparisonParameters(queryString, requestParams);
    }
  }

  collectYearOverYearComparisonParameters(queryString, requestParams) {
    // Here, we go back 364 days instead of a complete year (365). It is done because 364 is a multiple of 7,
    // which will lead to the same week day in the previous year.
    const startDate =  moment(this.startDatePicker.getValue(), DATE_FORMAT).subtract(364, 'days').format(DATE_FORMAT);
    const endDate =  moment(this.endDatePicker.getValue(), DATE_FORMAT).subtract(364, 'days').format(DATE_FORMAT);

    let params = {
      start_date: startDate,
      end_date: endDate,
      admin_id: Authentication.getCurrentUserId(),
      level: this.$levelFilterSelect.val(),
      kind: this.$kindFilterSelect.val(),
      university_filter_type: this.universityComparisonFilter.universityTypeDropdown.getSelectedValue(),
      university_id: this.universityFilter.universityAutocomplete.getSelectedValue(),
      education_group_id: this.universityFilter.educationGroupAutocomplete.getSelectedValue(),
      type: 'comparison'
    };
    UniversityChartsPage.setQueryStringComparisonParameters(queryString, params);
    requestParams.unshift(params);
    return params;
  }

  collectUniversityComparisonParameters(queryString, requestParams) {
    let params = {
      start_date: this.startDatePicker.getValue(),
      end_date: this.endDatePicker.getValue(),
      admin_id: Authentication.getCurrentUserId(),
      level: this.$levelFilterSelect.val(),
      kind: this.$kindFilterSelect.val(),
      university_filter_type: this.universityComparisonFilter.universityTypeDropdown.getSelectedValue(),
      university_id: this.universityComparisonFilter.universityAutocomplete.getSelectedValue(),
      education_group_id: this.universityComparisonFilter.educationGroupAutocomplete.getSelectedValue(),
      type: 'comparison'
    };
    UniversityChartsPage.setQueryStringComparisonParameters(queryString, params);
    requestParams.push(params);
    return params;
  }

  static setQueryStringComparisonParameters(queryString, params) {
    queryString['comparison_university_id'] = params["university_id"];
    queryString['comparison_education_group_id'] = params["education_group_id"];
    queryString['comparison_university_filter_type'] = params["university_filter_type"];
    AppObject.removeIfNullOrEmpty(params);
  }

  static afterShowReport() {
    $("#update-btn").removeAttr('disabled');
  }

  configCsvExport() {
    const titleCsv = ["Data"].concat(TITLES.map((value) => {
      return value.normalize('NFD').replace(/[\u0300-\u036f]/g, "");
    }));
    const columns = ["dates", "visits", "orders", "paid_orders", "attractiveness", "exclusivity", "conversion",
                     "student_price", "average_price"];

    this.exportButton.on("click", (e) => {
      const rows = columns.map((column, index) => {
        return [titleCsv[index]].concat(this.mainChartData[columns[index]]);
      });

      let csvContent = "data:text/csv;charset=ISO-8859-1,";

      rows.forEach(function(rowArray){
        let row = rowArray.join(";").replace(/\./g,',');
        csvContent += row + "\r\n";
      });

      const encodedUri = encodeURI(csvContent);

      const link = document.createElement("a");
      link.setAttribute("href", encodedUri);
      link.setAttribute("download",`Relatório - ${this.mainChartData['name']}.csv`);
      document.body.appendChild(link);

      link.click();
    });
  }
}
window.universityChartsPage = new UniversityChartsPage();
