(($) ->
  class SelectController
    constructor: (@node)->
      data = ['one','two','three']
      @model = new window.SelectModel(data)
      @view = new window.SelectView(@node)

      $(@view).on 'focus', (=> @model.activate())
      $(@view).on 'blur', (=> @model.inactivate())
      $(@view).on('input', @dispatchKeypress)
      $(@view).on('selection', (ev, val)=> @model.setValue(val))
      $(@view).on('prev', (ev, val)=> @model.prev())
      $(@view).on('next', (ev, val)=> @model.next())

      $(@model).on 'activated', (=> @view.active())
      $(@model).on 'inactivated', (=> @view.inactive())
      $(@model).on 'open', (=> @view.showDropdown())
      $(@model).on 'close', (=> @view.hideDropdown())
      $(@model).on 'results', @view.showResults
      $(@model).on 'valueChanged', ((ev, val)=> @view.setValue(val))
      $(@model).on 'highlight', ((ev, item) => @view.highlight(item))

    dispatchKeypress: (_, val)=>
      @model.filter(val)

  window.SelectController = SelectController

) jQuery
