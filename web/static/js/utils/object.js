
export default class AppObject {

  static removeIfNullOrEmpty(obj) {
    if (obj == null) return null;

    Object.keys(obj).forEach(function (key) {
      if (obj[key] == null || obj[key].toString() === '')
        delete obj[key];
    });
    return obj;
  }

}
