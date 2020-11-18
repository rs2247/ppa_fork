import DatePicker from "./components/datepicker";
import moment from 'moment';
import AjaxRequest from "./components/ajax";
import Authentication from "./components/authentication";
import DataTable from "./components/datatable";
import UniversityFilter from "./components/universityFilter";
import $ from 'jquery'

let select2 = require('select2')();

const PAGE_URL = 'sales_stats';

class SalesReportPage {

  setup() {
    this.$levelFilterSelect = $('.js-levels-multi-select');
    this.$levelFilterSelect.select2({width: "resolve", height: "resolve", placeholder: "Todos"});
    this.$kindFilterSelect = $('.js-kinds-multi-select');
    this.$kindFilterSelect.select2({width: "resolve", height: "resolve", placeholder: "Todos"});
    this.startDatePicker = new DatePicker("start-date");
    this.endDatePicker = new DatePicker("end-date");
    this.removeWhitelabelsCheckbox = $("#remove-whitelabels");
    this.universityFilter = new UniversityFilter();

    $("#filters-form").submit((evt) => {
      evt.preventDefault();
      this.updateReport();
    });

    this.updateRequest = new AjaxRequest({
        url: `/${PAGE_URL}/generate`,
        onSuccess: () => this.afterShowReport(),
        onLoadOverlayElement: $(".report-panel")
    });
    this.loadInitialFilterValues();
    this.universityFilter.loadInitialValues();
    this.afterShowReport();
  }

  loadInitialFilterValues() {
    let yesterday = moment().subtract(1, 'days').toDate();
    let sixMonthsBehind = moment().subtract(1, 'days').subtract(6, 'months').toDate();

    let startDate = $("#initial-start-date").val() || sixMonthsBehind;
    let endDate = $("#initial-end-date").val() || yesterday;
    this.startDatePicker.setDate(startDate);
    this.endDatePicker.setDate(endDate);
  }

  updateReport() {
    const data = this.collectParameters();
    console.log("Filter Data: " + JSON.stringify(data));
    $("#update-btn").attr('disabled', '');
    this.updateRequest.getAndRenderPartial(data, $("#report-container"));
    this.updatePageHistory(data);
  }

  updatePageHistory(data) {
    const params = $.param(data);
    window.history.pushState("", "", `${PAGE_URL}?${params}`);
  }

  collectParameters() {
    console.log(this.startDatePicker.getValue())
    return {
      start_date: this.startDatePicker.getValue(),
      end_date: this.endDatePicker.getValue(),
      university_filter_type: this.universityFilter.universityTypeDropdown.getSelectedValue(),
      university_id: this.universityFilter.universityAutocomplete.getSelectedValue(),
      education_group_id: this.universityFilter.educationGroupAutocomplete.getSelectedValue(),
      admin_id: Authentication.getCurrentUserId(),
      remove_whitelabels: this.removeWhitelabelsCheckbox.is(":checked"),
      level: this.$levelFilterSelect.val(),
      kind: this.$kindFilterSelect.val(),
    }
  }

  afterShowReport() {
    this.dataTable = new DataTable('#report-table', {
      paging: true,
      deferRender: true,
      pageLength: 10,
      order: [0, 'asc']
    });
    $("#update-btn").removeAttr('disabled');
  }
}

window.salesReportPage = new SalesReportPage();
