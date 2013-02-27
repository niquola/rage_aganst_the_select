#
# Copyright 2012 Igor Vaynberg
#
# Version: @@ver@@ Timestamp: @@timestamp@@
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in
# compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#
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

  class Observable
    constructor: (@attrs) ->


  class SelectModel extends Observable
    constructor: (@data)->
      @_hg = 0
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
      @filtered_data = @data
      @filtered_data = @data.filter((i)-> i.indexOf(term) > -1) if term
      $(@).trigger('results', [@filtered_data])
    close: ->
      $(@).trigger('close')
    setValue: (val)->
      @_val = val
      $(@).trigger('valueChanged', [@_val])
      @close()
    next: ->
      @_hg += 1
      $(@).trigger('highlight', [@data[@_hg]])
    prev: ->
      @_hg -= 1
      $(@).trigger('highlight', [@data[@_hg]])


  class SelectView
    constructor: (node) ->
      @node = $(node)
      @render()
    containerClass: (-> 'select2-container')
    containerWidth: (-> 300)
    render: ->
      @createDom()
    createDom: ->
      @_container = $('<div></div>', "class": 'select2-container').insertAfter(@node)
      @createFocusNode()
      @createDropdown()
      @createHidden()


    createFocusNode: ->
      @_focusNode = $("<input></input>", "type": 'text').appendTo(@_container)
      @_focusNode.on('focus', => $(@).trigger('focus'))
      # @_focusNode.on('blur', => $(@).trigger('blur'))
      @_focusNode.on('keydown', @onKeypress)
      @_focusNode.on('input', (ev)=> $(@).trigger('input', [@_focusNode.val()]))

    onKeypress: (e)=>
      switch e.which
        when KEY.UP
         $(@).trigger('prev')
        when KEY.DOWN
         $(@).trigger('next')
    createDropdown: ->
      @dropdownNode = $('<ul></ul>',"class": 'dropdown-menu').appendTo(@_container)
      @hidePopup()
      self = this
      @dropdownNode.delegate 'a','click', ->
        $(self).trigger('selection', [$(@).text()])

    createHidden: ->
      @hiddenNode = $('<span></span>', html: 'ups').appendTo(@_container)

    setValue: (val)->
      @hiddenNode.text("Value: #{val}")

    active: ->
      @dropdownNode.addClass('active')

    inactive: ->
      @dropdownNode.removeClass('active')

    showResults: (ev, items)=>
      html = ( @itemLine(item) for item in items )
      @dropdownNode.html(html.join(''))

    showPopup: ->
      @dropdownNode.show()

    hidePopup: ->
      @dropdownNode.hide()

    itemLine: (item)->
      "<li><a href='#'>#{item}</a></li>"

    highlight: (item)->
      @dropdownNode.find('a.active').removeClass('active')
      console.log("a[text='#{item}']")
      console.log @dropdownNode.find("a[text='#{item}']").addClass('active')

  class SelectController
    constructor: (@node)->
      data = ['one','two','three']
      @model = new SelectModel(data)
      @view = new SelectView(@node)

      $(@view).on 'focus', (=> @model.activate())
      $(@view).on 'blur', (=> @model.inactivate())
      $(@view).on('input', @dispatchKeypress)
      $(@view).on('selection', (ev, val)=> @model.setValue(val))
      $(@view).on('prev', (ev, val)=> @model.prev())
      $(@view).on('next', (ev, val)=> @model.next())

      $(@model).on 'activated', (=> @view.active())
      $(@model).on 'inactivated', (=> @view.inactive())
      $(@model).on 'open', (=> @view.showPopup())
      $(@model).on 'close', (=> @view.hidePopup())
      $(@model).on 'results', @view.showResults
      $(@model).on 'valueChanged', ((ev, val)=> @view.setValue(val))
      $(@model).on 'highlight', ((ev, item) => @view.highlight(item))

    dispatchKeypress: (_, val)=>
      @model.filter(val)

  $.fn.select2 = ->
    $(@).each ->
      cnt = new SelectController(@)

) jQuery
