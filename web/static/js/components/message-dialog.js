export default class MessageDialog {

  constructor(id, type = "info", title = "") {
    this.id = id;
    this.type = type;
    this.title = title;
    this.element = $(`#${id}`)
    this.alert = $(`#${this.id} .alert`);
    this.modalBody = $(`#${this.id} .modal-body`);
    this.modalTitle = $(`#${this.id} .modal-title`);
  }

  show(message) {
    this.setMessage(message);
    this.setTitle(this.title);
    this.element.modal('show');
  }

  showMany(messages) {
    this.show(messages.join('<br/>'));
  }

  setMessage(message) {
    this.modalBody.html(`<div class="alert alert-${this.type}" role="alert">${message}</div>`);
  }

  setTitle(title) {
    this.modalTitle.html(title);
  }
};

