// Generated by CoffeeScript 1.5.0
(function() {

  describe("Select2", function() {
    beforeEach(function() {
      console.log('beforeEach');
      $('body').append("      <select>\n<option value=\"1\">one of one </option>\n<option value=\"2\">two of two</option>\n<option value=\"3\">three</option>\n      </select>");
      $('body').append('<br/>');
      return $('body').append('<select multiple="multiple"><option value="1">one of one </option><option value="2">two of two</option></select>');
    });
    return it("should be able to play a Song", function() {
      return $('select').select2({});
    });
  });

}).call(this);
