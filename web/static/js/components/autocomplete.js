export default class Autocomplete {

  constructor(id, config) {
    this.id = id;
    this.element = $(`#${id}`);
    this.limit = (config.limit || 10);
    this.displayKey = (config.displayKey || 'name');
    this.minLength = (config.minLength || 3);
    this.url = config.url;
    this.template = (config.template || this.basicTemplate());
    this.typeahedConfig = new Bloodhound({
      datumTokenizer: function(d) { return d.tokens; },
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      limit: this.limit,
      remote: {
        url: this.url,
        rateLimitWait: 500
      }
    });
    this.typeahedConfig.initialize();
    this.element.typeahead('destroy');
    this.element.typeahead(null, {
      name: this.id,
      displayKey: this.displayKey,
      minLength: this.minLength,
      source: this.typeahedConfig.ttAdapter(),
      templates: {
        suggestion: Handlebars.compile([
          this.template
        ].join('')),
        notFound: "Nenhum registro encontrado."
      }
    });

    this.onSelect = config.onSelect;

    this.element.on('typeahead:selected', (ev, json) => {
      this.element.attr('data-ref', json.value);
      if (this.onSelect) {
        this.onSelect(ev, json);
      }
    });

  }

  basicTemplate() {
    return `
    <div>
      <p>{{name}}</p>
      </div>
    </div>
    `;
  }

  disable() {
    this.element.prop('disabled', true);
  }

  enable() {
    this.element.prop('disabled', false);
  }

  clear() {
    this.element.typeahead('val','');
    this.setSelectedValue('','')
  }

  setSelectedValue(name, value) {
    this.element.attr('data-ref', value);
    this.element.typeahead('val', name);
    this.element.typeahead('close');
    this.element.blur();
  }

  getSelectedValue() {
    return this.element.attr('data-ref');
  }

  get selectedValue() {
    return this.getSelectedValue();
  }

  getSelectedLabel() {
    this.element.val();
  }

  get selectedLabel() {
    return this.getSelectedLabel();
  }
};
