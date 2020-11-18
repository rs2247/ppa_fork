import Dropdown from './components/dropdown';
import UniversityAutocomplete from "./components/universityAutocomplete";
import DatePicker from "./components/datepicker";
import moment from 'moment';
import AjaxRequest from "./components/ajax";

const PAGE_URL = 'view_competitors_flow';

class CompetitorsFlowPage {

  setup() {
    this.startDatePicker = new DatePicker("js-start-date");
    this.endDatePicker = new DatePicker("js-end-date");
    this.levelFilterDropdown = new Dropdown('js-level-filter');
    this.kindFilterDropdown = new Dropdown('js-kind-filter');
    this.universityAutocomplete = new UniversityAutocomplete('js-university-autocomplete', {onSelect: this.onSelectUniversity.bind(this)});
    this.firstAccess = true;
    this.stateFilterDropDown = new Dropdown('js-state-filter', this.onSelectState.bind(this));
    this.cityFilterDropDown = new Dropdown('js-city-filter');

    $(".js-filters-form").submit((evt) => {
      evt.preventDefault();
      this.updateReport();
    });

    this.updateRequest = new AjaxRequest({
        url: `/${PAGE_URL}/generate`,
        onSuccess: () => this.afterShowReport(),
        onLoadOverlayElement: $(".js-competitor-flow-tables-container")
    });
    this.loadInitialFilterValues();
  }

  loadInitialFilterValues() {
    let yesterday = moment().subtract(1, 'days').toDate();
    let sixMonthsBehind = moment().subtract(1, 'days').subtract(6, 'months').toDate();

    let startDate = $("#js-initial-start-date").val() || sixMonthsBehind;
    let endDate = $("#js-initial-end-date").val() || yesterday;
    this.startDatePicker.setDate(startDate);
    this.endDatePicker.setDate(endDate);

    let universityName = $("#js-initial-university-name").val() || "";
    let universityId = $("#js-initial-university-id").val() || "";

    this.universityAutocomplete.setSelectedValue(universityName, universityId);
  }

  defaultDropdownValue() {
    return [{value: "all", label: "Todos"}];
  }

  updateReport() {
    var data = this.collectParameters();
    console.log("Filter Data: " + JSON.stringify(data));
    $("#update-btn").attr('disabled', '');
    this.updateRequest.getAndRenderPartial(data, $(".js-competitor-flow-tables-container"));
    this.updatePageHistory(data);
  }

  updatePageHistory(data) {
    var params = $.param(data);
    window.history.pushState("", "", `${PAGE_URL}?${params}`);
  }

  collectParameters() {
    return {
      start_date: this.startDatePicker.getValue(),
      end_date: this.endDatePicker.getValue(),
      university_id: this.universityAutocomplete.getSelectedValue(),
      level: this.levelFilterDropdown.getSelectedValue(),
      kind: this.kindFilterDropdown.getSelectedValue(),
      state: this.stateFilterDropDown.getSelectedValue(),
      city: this.cityFilterDropDown.getSelectedValue(),
    }
  }

  updateStateOptions() {
    this.stateCityHash = JSON.parse($("#js-city-map").val());

    this.cityFilterDropDown.replaceOptions(this.defaultDropdownValue());
    
    let states = Object.keys(this.stateCityHash);
    let newStatesData = this.defaultDropdownValue();
    for (let i = 0, len = states.length; i < len; i++) {
      newStatesData.push({value: states[i], label: states[i]});
    }
    this.stateFilterDropDown.replaceOptions(newStatesData);
  }

  afterShowReport() {
    $("#update-btn").removeAttr('disabled');
    if (typeof this.stateCityHash == 'undefined') {
      this.updateStateOptions();
    }
  }

  resetStateOptions() {
    this.cityFilterDropDown.replaceOptions(this.defaultDropdownValue());
    this.stateFilterDropDown.replaceOptions(this.defaultDropdownValue());
  }

  onSelectUniversity() {
    this.resetStateOptions();
    delete this.stateCityHash;
  }

  onSelectState(state) {
    if (this.firstAccess) {
      this.stateCityHash = JSON.parse($("#js-city-map").val());
      this.firstAccess = false;
    } else {
      let newCitiesData = this.defaultDropdownValue();
      if (state != "all") {
        let cities = this.stateCityHash[state];
        for (let i = 0, len = cities.length; i < len; i++) {
          newCitiesData.push({value: cities[i], label: cities[i]});
        }
      }
      this.cityFilterDropDown.replaceOptions(newCitiesData);
    }
  }
}

window.competitorsFlowPage = new CompetitorsFlowPage();
