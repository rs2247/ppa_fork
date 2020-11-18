export default class DatePicker {

  constructor(id, config = {}) {
    this.element = $(`#${id}`);
    this.config = config;
    if (!config["dateFormat"]) {
      config["dateFormat"] = "dd/mm/yy";
    }
    config.constrainInput = true;
    this.element.datepicker(this.config);
  }

  setDate(date) {
    this.element.datepicker("setDate", date);
  }

  getValue() {
    return this.element.datepicker().val();
  }
}
