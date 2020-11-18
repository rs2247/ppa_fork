// File with some prototypes over the String type

export default (function () {

  String.prototype.nullIfBlank = function () {
    if (this.trim().length === 0) {
      return null;
    } else {
      return this;
    }
  };

}());

