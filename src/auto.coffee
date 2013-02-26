class Observable
  constructor: (@attrs) ->
    @_callbacks = {}

  on: (event_name, cb) ->
    @_callbacks[event_name] = cb

  cl: (event_name, args)->
    @_callbacks[event_name].call(null, args)

class SelectModel extends Observable
  filter: (term) ->
    @cl('filtered',[term])

  selection: (value)->
    @selection = value
    @cl('selected', value)

class SelectView
  constructor: (@node) ->
  render: (items)->
    res = $.map items, (i)-> "<li>#{i}</li>"
    @node.html(res.join(''))


jQuery ->
  data = ['one','two','three']
  model = new SelectModel(data: data)
  view = new SelectView($('#result'))

  model.on 'filtered', (items)->
    view.render(items)

  model.on 'selected', (value)->
    $('#selection').html(value)

  $('#autocomplete').keyup ->
    model.filter($(@).val())

  $('#autocomplete').blur ->
    model.selection($(@).val())
