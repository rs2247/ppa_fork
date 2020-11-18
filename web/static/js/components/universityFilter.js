import Autocomplete from "./autocomplete";
import EducationGroupAutocomplete from "./educationGroupAutocomplete";
import UniversityAutocomplete from "./universityAutocomplete";
import Dropdown from "./dropdown";

/**
 * Filter composed by a select box, an university autocomplete and an education group autocomplete,
 * used to select one or more universities.
 *
 * It MUST be used together with the `university-filter.html.eex` template file
 */
export default class UniversityFilter {

  constructor(config = {} ) {
    this.subject =  config['subject'] || '';

    this.universityAutocomplete = new UniversityAutocomplete(this._idFor('university-autocomplete'));
    this.educationGroupAutocomplete = new EducationGroupAutocomplete(this._idFor('education-group-autocomplete'));
    this.universityTypeDropdown = new Dropdown(this._idFor('university-filter-type'), this.onSelectFilterType.bind(this));
    this.afterInitialSelection = config.afterInitialSelection;
  }

  loadInitialValues() {
    const universityId = this.getElement('initial-university-id').val().nullIfBlank();
    if (universityId) {
      const universityName = this.getElement('initial-university-name').val();
      this.universityAutocomplete.setSelectedValue(universityName, universityId);
      this._fireSelectionEvent();
    }

    const groupId = this.getElement('initial-education-group-id').val().nullIfBlank();
    if (groupId && !universityId) { // only execute for educational group if we don't have a university set.
      const groupName = this.getElement('initial-education-group-name').val();
      this.educationGroupAutocomplete.setSelectedValue(groupName, groupId);
      this._fireSelectionEvent();
    }
  }

  onSelectFilterType(newType) {
    this.hideFilters();

    if (newType === 'education_group') {
      this.getElement('education-group-autocomplete').val('');
      this.educationGroupAutocomplete.enable();
      this.getElement('education-group-filter').show();
      this.getElement('education-group-autocomplete').focus();
    } else if (newType === 'university') {
      this.getElement('university-autocomplete').val('');
      this.universityAutocomplete.enable();
      this.getElement('university-filter').show();
      this.getElement('university-autocomplete').focus();
    } else { // for other types of filter, just show the university autocomplete disabled to fill the spaces.
      this.getElement('university-autocomplete').val('');
      this.getElement('university-filter').show();
    }

  }

  hideFilters() {
    this.getElement('university-filter').hide();
    this.getElement('education-group-filter').hide();
    this.universityAutocomplete.disable();
    this.universityAutocomplete.clear();
    this.educationGroupAutocomplete.disable();
    this.educationGroupAutocomplete.clear();
  }

  _fireSelectionEvent() {
    if (this.afterInitialSelection)
      this.afterInitialSelection();
  }

  _idFor(fieldName) {
    const subjectWithDash = (this.subject.length > 0 ? `${this.subject}-` : "");
    return `${subjectWithDash}${fieldName}`;
  }

  getElement(fieldName) {
    return $(`#${this._idFor(fieldName)}`);
  }


}
