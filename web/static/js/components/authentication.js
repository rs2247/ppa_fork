export default class Authentication {

  static getCurrentUserId() {
    var element = $("#panel-main-container");
    return (element.length > 0 ? element.attr('data-admin-user-id') : null);
  }
};

