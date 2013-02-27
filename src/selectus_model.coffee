(($) ->
  class Observable
    constructor: (@attrs) ->

  class SelectModel extends Observable
    constructor: (@data)->
      i = -1
      @items = ( {data: item, _id: (i = i + 1)} for item in @data )
      @selected_item_index = 0

    activate: ->
      @_active = true
      $(@).trigger('activated')
      @open()
      @filter()

    open: ->
      $(@).trigger('open')

    inactivate: ->
      @_active = false
      $(@).trigger('inactivated')
      @close()

    filter: (term) ->
      @filtered_items = @items
      @filtered_items = @items.filter((i)-> i.data.indexOf(term) > -1) if term
      $(@).trigger('results', [@filtered_items])

    close: ->
      $(@).trigger('close')

    setValue: (id)->
      @value = @items[id]
      $(@).trigger('valueChanged', [@value])
      @close()

    next: ->
      @selected_item_index += 1
      $(@).trigger('highlight', [@filtered_items[@selected_item_index]])

    prev: ->
      @selected_item_index -= 1
      $(@).trigger('highlight', [@filtered_items[@selected_item_index]])

   window.SelectModel = SelectModel

) jQuery
