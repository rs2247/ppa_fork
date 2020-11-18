import Autocomplete from "./autocomplete";

export default class UniversityAutocomplete extends Autocomplete {

  constructor(id, config = {} ) {
    config["displayKey"] = name;
    config["url"] = '/api/university/name?q=%QUERY';
    super(id,config);
  }

  basicTemplate() {
    return `
    <div>
      <p>{{value}} - {{name}}</p>
      </div>
    </div>
    `;
  }
}
