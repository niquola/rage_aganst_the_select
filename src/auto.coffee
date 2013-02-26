class SelectModel
  constructor: (@attrs) ->
    @_callbacks = {}

  on: (event_name, cb) ->
    @_callbacks[event_name] = cb

  filter: (term) ->
    @_callbacks['filtered'].call(null, [term])

  selection: (value)->
    @selection = value
    @_callbacks['selected'].call(null, value)

data = ['one','two','three']

sm = new SelectModel(data: data)

sm.on 'filtered', (items)->
  res = $.map items, (i)-> "<li>#{i}</li>"
  $('#result').html(res.join(''))

sm.on 'selected', (value)->
  $('#selection').html(value)


sm.filter('term')

jQuery ->
  $('.autocomplete').keyup ->
    sm.filter($(@).val())
  $('.autocomplete').blur ->
    sm.selection($(@).val())

