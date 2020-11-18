import Autocomplete from "./autocomplete";

export default class EducationGroupAutocomplete extends Autocomplete {

  constructor(id) {
    super(id, {
      displayKey: name,
      url: '/api/education_group/name?q=%QUERY',
    });
  }
}
