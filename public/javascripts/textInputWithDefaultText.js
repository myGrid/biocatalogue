// From: http://chaolam.wordpress.com/2009/07/30/javascript-html-text-input-field-with-default-text/
// Modified/extended by Jits

var DefaultTextInput = Class.create();
DefaultTextInput.prototype = {
  initialize: function(inputElt, defaultText, defaultClass) {
    inputElt = this._inputElt = $(inputElt);
    this._defaultText = defaultText || inputElt.value;
    this._defaultClass = defaultClass || 'ex';
    this.fixParentFormSubmit();
    inputElt.observe('change', this.onChange.bindAsEventListener(this));
    inputElt.observe('focus', this.onFocus.bindAsEventListener(this));
    inputElt.observe('blur', this.onChange.bindAsEventListener(this));
    this.onChange();
  },
  onChange: function() {
    var inputElt = this._inputElt;
    if (!inputElt.value) {inputElt.value = this._defaultText;}
    if (inputElt.value == this._defaultText) {inputElt.addClassName(this._defaultClass);}
    else {inputElt.removeClassName(this._defaultClass);}
  },
  onFocus: function() {
    if (this._inputElt.value == this._defaultText && !this._isFocussing) {
      this._isFocussing = true;
      this._inputElt.removeClassName(this._defaultClass);
      this._inputElt.select();
      this._inputElt.value = '';
      this._isFocussing = false;
    }
  },
  fixParentFormSubmit: function() {
    var inputElt = this._inputElt;
    var form = inputElt.ancestors().find(function(elt) {return elt.tagName == 'FORM';});
    var self = this;
    if (form) {
      var oldSubmitFunc = form.onsubmit;
      form.onsubmit = function() {
        self.onFocus();
        if (oldSubmitFunc) {return oldSubmitFunc.call(form);}
      };
    }
  }
};
