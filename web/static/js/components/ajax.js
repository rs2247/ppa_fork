import MessageDialog from "./message-dialog";

export default class AjaxRequest {

  constructor({url=null, onSuccess=null, onFailure=null, onLoadOverlayElement=null} = {}) {
    this.url = url;
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onLoadOverlayElement = onLoadOverlayElement;
  }

  getParallel(dataArray, callback) {
    const requests = [];
    for (let idx = 0; idx < dataArray.length; idx++) {
      const req = $.ajax({
        type: 'GET',
        url: this.url,
        data: dataArray[idx],
        beforeSend: () => this.beforeSend()
      });
      requests.push(req);
    }
    $.when.apply(this, requests)
      .done(function() {
        const responses = Array.prototype.slice.call(arguments, 0, requests.length);
        if (requests.length <= 1) {
          callback(responses);
        } else {
          const responseData = responses.map((resp) => resp[0]);
          callback(responseData);
        }
      }).fail(this.handleError)
        .always(() => this.afterSend());
  }

  get(jsonData, callbackFunction) {
    $.ajax({
      type: 'GET',
      url: this.url,
      data: jsonData,
      beforeSend: () => this.beforeSend()
    }).done(callbackFunction)
      .fail(this.handleError)
      .always(() => this.afterSend());
  }

  postAndRenderPartial(jsonData, containerElement) {
    $.ajax({
      type: 'POST',
      url: this.url,
      data: jsonData,
      beforeSend: () => this.beforeSend()
    }).done(this.renderFunction(containerElement))
      .fail(this.handleError)
      .always(() => this.afterSend());
  }

  getAndRenderPartial(jsonData, containerElement) {
    $.ajax({
      type: 'GET',
      url: this.url,
      data: jsonData,
      beforeSend: () => this.beforeSend()
    }).done(this.renderFunction(containerElement))
      .fail(this.handleError)
      .always(() => this.afterSend());
  }

  renderFunction(containerElement) {
    return (html) => {
      containerElement.empty();
      containerElement.html(html);
      if (this.onSuccess) {
        this.onSuccess(html);
      }
    }
  }

  beforeSend(jqXHR, settings) {
    this.addLoadOverlay();
  }

  afterSend() {
    this.removeLoadOverlay();
  }

  addLoadOverlay() {
    if (this.onLoadOverlayElement) {
      var position = this.onLoadOverlayElement.offset();
      this.onLoadOverlayElement.addClass('overlay');
      this.onLoadOverlayElement.parent().append(
        `<div class="loader-container" style="top:${position.top}px;">
          <div class="loader"></div><p>Loading...</p>
        </div>`
      );
    }
  }

  removeLoadOverlay() {
    if (this.onLoadOverlayElement) {
      this.onLoadOverlayElement.parent().children(".loader-container").remove();
      this.onLoadOverlayElement.removeClass('overlay');
    }
  }

  handleError(jqXHR, exception) {
    var dialog = new MessageDialog("global-dialog", "danger", "Erro");
    console.log(`Error during ajax request. XHR status: ${jqXHR.status}, ${jqXHR.statusText}. Exception: ${JSON.stringify(exception)}`);

    if (jqXHR.status === 0) {
      dialog.show('Não há conexão com o servidor. Verifique sua rede');
    } else if (jqXHR.status == 404) {
      dialog.show('Recurso não encontrado no servidor.');
    } else if (jqXHR.status == 500) {
      dialog.show('Ocorreu um erro não esperado.');
    }

    if (this.onFailure) {
      this.onFailure(jqXHR, exception);
    }
  }

};

