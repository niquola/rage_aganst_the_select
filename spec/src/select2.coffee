describe "Select2",  ->
  beforeEach ->
    console.log('beforeEach')
    $('body').append """
      <select>
	<option value="1">one of one </option>
	<option value="2">two of two</option>
	<option value="3">three</option>
      </select>
      """
    $('body').append('<br/>')
    $('body').append('<select multiple="multiple"><option value="1">one of one </option><option value="2">two of two</option></select>')

  it "should be able to play a Song", ->
    $('select').select2({})

