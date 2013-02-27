(($) ->
  KEY =
    TAB: 9
    ENTER: 13
    ESC: 27
    SPACE: 32
    LEFT: 37
    UP: 38
    RIGHT: 39
    DOWN: 40
    SHIFT: 16
    CTRL: 17
    ALT: 18
    PAGE_UP: 33
    PAGE_DOWN: 34
    HOME: 36
    END: 35
    BACKSPACE: 8
    DELETE: 46

  class SelectView
    constructor: (node) ->
      @node = $(node)
      @createDom()

    createDom: ->
      @node.hide()
      @createContainer()
      @createFocusNode()
      @createDropdown()
      @createHidden()

    createContainer: ->
      @containerNode = $('<div></div>', "class": 'selectus-container').insertAfter(@node)

    createFocusNode: ->
      @focusNode = $("<input></input>", "type": 'text').appendTo(@containerNode)

      @focusNode.on('focus', => $(@).trigger('focus'))
      # @focusNode.on('blur', => $(@).trigger('blur'))
      @focusNode.on('keydown', @dispatchKeypress)
      @focusNode.on('input', (ev)=> $(@).trigger('input', [@focusNode.val()]))

    dispatchKeypress: (e)=>
      switch e.which
        when KEY.UP
         $(@).trigger('prev')
        when KEY.DOWN
         $(@).trigger('next')

    createDropdown: ->
      @dropdownNode = $('<ul></ul>',"class": 'dropdown-menu').appendTo(@containerNode)
      @hideDropdown()
      self = this
      @dropdownNode.delegate 'a','click', ->
        $(self).trigger('selection', [$(@).data('id')])

    createHidden: ->
      @hiddenNode = $('<span></span>', html: 'ups').appendTo(@containerNode)

    setValue: (val)->
      @hiddenNode.text("Value: #{JSON.stringify(val)}")

    active: ->
      @dropdownNode.addClass('active')

    inactive: ->
      @dropdownNode.removeClass('active')

    showResults: (ev, items)=>
      @dropdownNode.html ( @itemLine(item) for item in items ).join('')

    itemLine: (item)->
      "<li data-id='#{item._id}'><a data-id='#{item._id}' href='#'>#{item.data}</a></li>"

    showDropdown: ->
      @dropdownNode.show()

    hideDropdown: ->
      @dropdownNode.hide()

    highlight: (item)->
      return unless item
      node = @dropdownNode.find("li[data-id='#{item._id}']")
      @dropdownNode.find('li.active').removeClass('active')
      node.addClass('active')
      console.log(node)

    window.SelectView = SelectView
) jQuery
