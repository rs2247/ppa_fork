export default class Dropdown {

  constructor(id, onSelect) {
    this.selector = "#" + id;
    this.onSelect = onSelect;

    this.updateResponsiveness();
    this.setSelectedValue(this.getSelectedValue());
  }

  updateResponsiveness() {
    $(this.selector + " a").on('click', (e) => {
      e.preventDefault();
      this.updateSelection($(e.target));
    });
  }

  setSelectedValue(value) {
    const selection = $(this.selector +  ` a[data-ref=${value}]`);
    if (selection.size() > 0)
      this.updateSelection(selection);
    else
      console.log("Item not found for value: " + value);
  }

  getSelectedValue() {
    return $(this.selector).attr('data-ref');
  }

  updateSelection(element) {
    $(this.selector + " span.flex-grow").html(element.text());
    $(this.selector).attr('data-ref', element.attr('data-ref'));
    if (this.onSelect) {
      this.onSelect(this.getSelectedValue());
    }
  }

  replaceOptions(data) {
    const dropdownList = $(this.selector + " ul");
    dropdownList.empty();
    for (let i = 0, len = data.length; i < len; i++) {
      let newElement = `<li><a href="#!" data-ref="${data[i].value}">${data[i].label}</a></li>`;
      dropdownList.append(newElement);
    }
    this.setSelectedValue(data[0].value);
    this.updateResponsiveness();
  }
};

