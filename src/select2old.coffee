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
(($, undefined_) ->

  #global document, window, jQuery, console
  indexOf = (value, array) ->
    i = 0
    l = array.length
    v = undefined
    return -1  if typeof value is "undefined"
    if value.constructor is String
      while i < l
        return i  if value.localeCompare(array[i]) is 0
        i = i + 1
    else
      while i < l
        v = array[i]
        if v.constructor is String
          return i  if v.localeCompare(value) is 0
        else
          return i  if v is value
        i = i + 1
    -1

  ###
  Compares equality of a and b taking into account that a and b may be strings, in which case localCompare is used
  @param a
  @param b
  ###
  equal = (a, b) ->
    return true  if a is b
    return false  if a is `undefined` or b is `undefined`
    return false  if a is null or b is null
    return a.localeCompare(b) is 0  if a.constructor is String
    return b.localeCompare(a) is 0  if b.constructor is String
    false

  ###
  Splits the string into an array of values, trimming each value. An empty array is returned for nulls or empty
  strings
  @param string
  @param separator
  ###
  splitVal = (string, separator) ->
    return [] unless string
    $.trim(val) for val in string.split(separator)
    # val = undefined
    # i = undefined
    # l = undefined
    # return []  if string is null or string.length < 1
    # val = string.split(separator)
    # i = 0
    # l = val.length

    # while i < l
    #   val[i] = $.trim(val[i])
    #   i = i + 1
    # val

  getSideBorderPadding = (element) ->
    element.outerWidth() - element.width()

  installKeyUpChangeEvent = (element) ->
    element.bind "keydown", ->
      element.data "keyup-change-value", element.val()

    element.bind "keyup", ->
      element.trigger "keyup-change"  if element.val() isnt element.data("keyup-change-value")


  ###
  filters mouse events so an event is fired only if the mouse moved.

  filters out mouse events that occur when mouse is stationary but
  the elements under the pointer are scrolled.
  ###
  installFilteredMouseMove = (element) ->
    element.bind "mousemove", (e) ->
      lastpos = $(document).data("select2-lastpos")
      $(e.target).trigger "mousemove-filtered", e  if lastpos is `undefined` or lastpos.x isnt e.pageX or lastpos.y isnt e.pageY


  ###
  Debounces a function. Returns a function that calls the original fn function only if no invocations have been made
  within the last quietMillis milliseconds.

  @param quietMillis number of milliseconds to wait before invoking fn
  @param fn function to be debounced
  @return debounced version of fn
  ###
  debounce = (quietMillis, fn) ->
    timeout = undefined
    ->
      window.clearTimeout timeout
      timeout = window.setTimeout(fn, quietMillis)
  installDebouncedScroll = (threshold, element) ->
    notify = debounce(threshold, (e) ->
      element.trigger "scroll-debounced", e
    )
    element.bind "scroll", (e) ->
      notify e  if indexOf(e.target, element.get()) >= 0

  killEvent = (event) ->
    event.preventDefault()
    event.stopPropagation()

  measureTextWidth = (e) ->
    sizer = undefined
    width = undefined
    sizer = $("<div></div>").css(
      position: "absolute"
      left: "-1000px"
      top: "-1000px"
      display: "none"
      fontSize: e.css("fontSize")
      fontFamily: e.css("fontFamily")
      fontStyle: e.css("fontStyle")
      fontWeight: e.css("fontWeight")
      letterSpacing: e.css("letterSpacing")
      textTransform: e.css("textTransform")
      whiteSpace: "nowrap"
    )
    sizer.text e.val()
    $("body").append sizer
    width = sizer.width()
    sizer.remove()
    width

  ###
  Produces an ajax-based query function

  @param options object containing configuration paramters
  @param options.transport function that will be used to execute the ajax request. must be compatible with parameters supported by $.ajax
  @param options.url url for the data
  @param options.data a function(searchTerm, pageNumber) that should return an object containing query string parameters for the above url.
  @param options.dataType request data type: ajax, jsonp, other datatatypes supported by jQuery's $.ajax function or the transport function if specified
  @param options.quietMillis (optional) milliseconds to wait before making the ajaxRequest, helps debounce the ajax function if invoked too often
  @param options.results a function(remoteData, pageNumber) that converts data returned form the remote request to the format expected by Select2.
  The expected format is an object containing the following keys:
  results array of objects that will be used as choices
  more (optional) boolean indicating whether there are more results available
  Example: {results:[{id:1, text:'Red'},{id:2, text:'Blue'}], more:true}
  ###
  ajax = (options) ->
    timeout = undefined # current scheduled but not yet executed request
    requestSequence = 0 # sequence used to drop out-of-order responses
    handler = null
    quietMillis = options.quietMillis or 100
    (query) ->
      window.clearTimeout timeout
      timeout = window.setTimeout(->
        requestSequence += 1 # increment the sequence
        requestNumber = requestSequence # this request's sequence number
        data = options.data # ajax data function
        transport = options.transport or $.ajax
        data = data.call(this, query.term, query.page)
        handler.abort()  if null isnt handler
        handler = transport.call(null,
          url: options.url
          dataType: options.dataType
          data: data
          success: (data) ->
            return  if requestNumber < requestSequence

            # TODO 3.0 - replace query.page with query so users have access to term, page, etc.
            query.callback options.results(data, query.page)
        )
      , quietMillis)

  ###
  Produces a query function that works with a local array

  @param options object containing configuration parameters. The options parameter can either be an array or an
  object.

  If the array form is used it is assumed that it contains objects with 'id' and 'text' keys.

  If the object form is used ti is assumed that it contains 'data' and 'text' keys. The 'data' key should contain
  an array of objects that will be used as choices. These objects must contain at least an 'id' key. The 'text'
  key can either be a String in which case it is expected that each element in the 'data' array has a key with the
  value of 'text' which will be used to match choices. Alternatively, text can be a function(item) that can extract
  the text.
  ###
  local = (options) ->
    data = options # data elements
    text = (item) -> # function used to retrieve the text portion of a data item that is matched against the search
      "" + item.text

    unless $.isArray(data)
      text = data.text

      # if text is not a function we assume it to be a key name
      unless $.isFunction(text)
        text = (item) ->
          item[data.text]
      data = data.results
    (query) ->
      t = query.term.toUpperCase()
      filtered = {}
      if t is ""
        query.callback results: data
        return
      filtered.results = $(data).filter(->
        text(this).toUpperCase().indexOf(t) >= 0
      ).get()
      query.callback filtered

  # TODO javadoc
  tags = (data) ->

    # TODO even for a function we should probably return a wrapper that does the same object/string check as
    # the function for arrays. otherwise only functions that return objects are supported.
    return data  if $.isFunction(data)

    # if not a function we assume it to be an array
    (query) ->
      t = query.term.toUpperCase()
      filtered = results: []
      $(data).each ->
        isObject = @text isnt `undefined`
        text = (if isObject then @text else this)
        if t is "" or text.toUpperCase().indexOf(t) >= 0
          filtered.results.push (if isObject then this else
            id: this
            text: this
          )

      query.callback filtered

  ###
  blurs any Select2 container that has focus when an element outside them was clicked or received focus
  ###

  ###
  Creates a new class

  @param superClass
  @param methods
  ###
  # clazz = (SuperClass, methods) ->
  #   constructor = ->

  #   constructor:: = new SuperClass
  #   constructor::constructor = constructor
  #   constructor::parent = SuperClass::
  #   constructor:: = $.extend(constructor::, methods)
  #   constructor

  "use strict"

  return  if window.Select2 isnt `undefined`
  KEY = undefined
  AbstractSelect2 = undefined
  SingleSelect2 = undefined
  MultiSelect2 = undefined

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
    isArrow: (k) ->
      k = (if k.which then k.which else k)
      switch k
        when KEY.LEFT, KEY.RIGHT , KEY.UP , KEY.DOWN
          return true
      false

    isControl: (k) ->
      k = (if k.which then k.which else k)
      switch k
        when KEY.SHIFT, KEY.CTRL , KEY.ALT
          return true
      false

    isFunctionKey: (k) ->
      k = (if k.which then k.which else k)
      k >= 112 and k <= 123

  $(document).delegate "*", "mousemove", (e) ->
    $(document).data "select2-lastpos",
      x: e.pageX
      y: e.pageY


  $(document).ready ->
    $(document).delegate "*", "mousedown focusin", (e) ->
      target = $(e.target).closest("div.select2-container").get(0)
      $(document).find("div.select2-container-active").each ->
        $(this).data("select2").blur()  if this isnt target



  class AbstractSelect2
    bind: (func) ->
      self = this
      ->
        func.apply self, arguments

    init: (opts) ->
      results = undefined
      search = undefined
      resultsSelector = ".select2-results"

      # prepare options
      @opts = opts = @prepareOpts(opts)
      @id = opts.id

      # destroy if called on an existing component
      @destroy()  if opts.element.data("select2") isnt `undefined` and opts.element.data("select2") isnt null
      @container = @createContainer()
      @container.addClass opts.element.attr("class")  if opts.element.attr("class") isnt `undefined`

      # swap container for the element
      @opts.element.data("select2", this).hide().after @container
      @container.data "select2", this
      @dropdown = @container.find(".select2-drop")
      @results = results = @container.find(resultsSelector)
      @search = search = @container.find("input[type=text]")
      @resultsPage = 0

      # initialize the container
      @initContainer()
      installFilteredMouseMove @results
      @container.delegate resultsSelector, "mousemove-filtered", @bind(@highlightUnderEvent)
      installDebouncedScroll 80, @results
      @container.delegate resultsSelector, "scroll-debounced", @bind(@loadMoreIfNeeded)

      # if jquery.mousewheel plugin is installed we can prevent out-of-bounds scrolling of results via mousewheel
      if $.fn.mousewheel
        results.mousewheel (e, delta, deltaX, deltaY) ->
          top = results.scrollTop()
          height = undefined
          if deltaY > 0 and top - deltaY <= 0
            results.scrollTop 0
            killEvent e
          else if deltaY < 0 and results.get(0).scrollHeight - results.scrollTop() + deltaY <= results.height()
            results.scrollTop results.get(0).scrollHeight - results.height()
            killEvent e

      installKeyUpChangeEvent search
      search.bind "keyup-change", @bind(@updateResults)
      search.bind "focus", ->
        search.addClass "select2-focused"

      search.bind "blur", ->
        search.removeClass "select2-focused"

      @container.delegate resultsSelector, "click", @bind((e) ->
        if $(e.target).closest(".select2-result:not(.select2-disabled)").length > 0
          @highlightUnderEvent e
          @selectHighlighted e
        else
          killEvent e
          @focusSearch()
      )
      if $.isFunction(@opts.initSelection)

        # initialize selection based on the current value of the source element
        @initSelection()

        # if the user has provided a function that can set selection based on the value of the source element
        # we monitor the change event on the element and trigger it, allowing for two way synchronization
        @monitorSource()

    destroy: ->
      select2 = @opts.element.data("select2")
      if select2 isnt `undefined`
        select2.container.remove()
        select2.opts.element.removeData("select2").unbind(".select2").show()

    prepareOpts: (opts) ->
      element = undefined
      select = undefined
      idKey = undefined
      element = opts.element
      @select = select = opts.element  if element.get(0).tagName.toLowerCase() is "select"
      if select

        # these options are not allowed when attached to a select because they are picked up off the element itself
        $.each ["id", "multiple", "ajax", "query", "createSearchChoice", "initSelection", "data", "tags"], ->
          throw new Error("Option '" + this + "' is not allowed for Select2 when attached to a <select> element.")  if this of opts

      opts = $.extend({},
        formatResult: (data) ->
          data.text

        formatSelection: (data) ->
          data.text

        formatNoMatches: ->
          "No matches found"

        formatInputTooShort: (input, min) ->
          "Please enter " + (min - input.length) + " more characters"

        minimumResultsForSearch: 0
        minimumInputLength: 0
        id: (e) ->
          e.id
      , opts)

      if typeof (opts.id) isnt "function"
        idKey = opts.id
        opts.id = (e) ->
          e[idKey]
      if select
        opts.query = @bind((query) ->
          data =
            results: []
            more: false

          term = query.term.toUpperCase()
          placeholder = @getPlaceholder()
          element.find("option").each (i) ->
            e = $(this)
            text = e.text()
            return true  if i is 0 and placeholder isnt `undefined` and text is ""
            if text.toUpperCase().indexOf(term) >= 0
              data.results.push
                id: e.attr("value")
                text: text


          query.callback data
        )

        # this is needed because inside val() we construct choices from options and there id is hardcoded
        opts.id = (e) ->
          e.id
      else
        unless "query" of opts
          if "ajax" of opts
            opts.query = ajax(opts.ajax)
          else if "data" of opts
            opts.query = local(opts.data)
          else if "tags" of opts
            opts.query = tags(opts.tags)
            opts.createSearchChoice = (term) ->
              id: term
              text: term

            opts.initSelection = (element) ->
              data = []
              $(splitVal(element.val(), ",")).each ->
                data.push
                  id: this
                  text: this


              data
      throw "query function not defined for Select2 " + opts.element.attr("id")  if typeof (opts.query) isnt "function"
      opts


    ###
    Monitor the original element for changes and update select2 accordingly
    ###
    monitorSource: ->
      @opts.element.bind "change.select2", @bind((e) ->
        @initSelection()  if @opts.element.data("select2-change-triggered") isnt true
      )


    ###
    Triggers the change event on the source element
    ###
    triggerChange: ->

      # Prevents recursive triggering
      @opts.element.data "select2-change-triggered", true
      @opts.element.trigger "change"
      @opts.element.data "select2-change-triggered", false

    opened: ->
      @container.hasClass "select2-dropdown-open"

    open: ->
      return  if @opened()
      @container.addClass("select2-dropdown-open").addClass "select2-container-active"
      @updateResults true
      @dropdown.show()
      @ensureHighlightVisible()
      @focusSearch()

    close: ->
      return  unless @opened()
      @dropdown.hide()
      @container.removeClass "select2-dropdown-open"
      @results.empty()
      @clearSearch()

    clearSearch: ->

    ensureHighlightVisible: ->
      results = @results
      children = undefined
      index = undefined
      child = undefined
      hb = undefined
      rb = undefined
      y = undefined
      more = undefined
      children = results.children(".select2-result")
      index = @highlight()
      return  if index < 0
      child = $(children[index])
      hb = child.offset().top + child.outerHeight()

      # if this is the last child lets also make sure select2-more-results is visible
      if index is children.length - 1
        more = results.find("li.select2-more-results")
        hb = more.offset().top + more.outerHeight()  if more.length > 0
      rb = results.offset().top + results.outerHeight()
      results.scrollTop results.scrollTop() + (hb - rb)  if hb > rb
      y = child.offset().top - results.offset().top

      # make sure the top of the element is visible
      results.scrollTop results.scrollTop() + y  if y < 0 # y is negative

    moveHighlight: (delta) ->
      choices = @results.children(".select2-result")
      index = @highlight()
      while index > -1 and index < choices.length
        index += delta
        unless $(choices[index]).hasClass("select2-disabled")
          @highlight index
          break

    highlight: (index) ->
      choices = @results.children(".select2-result")
      return indexOf(choices.filter(".select2-highlighted")[0], choices.get())  if arguments.length is 0
      choices.removeClass "select2-highlighted"
      index = choices.length - 1  if index >= choices.length
      index = 0  if index < 0
      $(choices[index]).addClass "select2-highlighted"
      @ensureHighlightVisible()
      @focusSearch()  if @opened()

    highlightUnderEvent: (event) ->
      el = $(event.target).closest(".select2-result")
      @highlight el.index()  if el.length > 0

    loadMoreIfNeeded: ->
      results = @results
      more = results.find("li.select2-more-results")
      below = undefined
      # pixels the element is below the scroll fold, below==0 is when the element is starting to be visible
      offset = -1 # index of first element without data
      page = @resultsPage + 1
      return  if more.length is 0
      below = more.offset().top - results.offset().top - results.height()
      if below <= 0
        more.addClass "select2-active"
        @opts.query
          term: @search.val()
          page: page
          callback: @bind((data) ->
            parts = []
            self = this
            $(data.results).each ->
              parts.push "<li class='select2-result'>"
              parts.push self.opts.formatResult(this)
              parts.push "</li>"

            more.before parts.join("")
            results.find(".select2-result").each (i) ->
              e = $(this)
              if e.data("select2-data") isnt `undefined`
                offset = i
              else
                e.data "select2-data", data.results[i - offset - 1]

            if data.more
              more.removeClass "select2-active"
            else
              more.remove()
            @resultsPage = page
          )



    ###
    @param initial whether or not this is the call to this method right after the dropdown has been opened
    ###
    updateResults: (initial) ->
      render = (html) ->
        results.html html
        results.scrollTop 0
        search.removeClass "select2-active"
      search = @search
      results = @results
      opts = @opts
      self = this
      search.addClass "select2-active"
      if search.val().length < opts.minimumInputLength
        render "<li class='select2-no-results'>" + opts.formatInputTooShort(search.val(), opts.minimumInputLength) + "</li>"
        return
      @resultsPage = 1
      opts.query
        term: search.val()
        page: @resultsPage
        callback: @bind((data) ->
          parts = [] # html parts
          def = undefined
          # default choice

          # create a default choice and prepend it to the list
          if @opts.createSearchChoice and search.val() isnt ""
            def = @opts.createSearchChoice.call(null, search.val(), data.results)
            if def isnt `undefined` and def isnt null and self.id(def) isnt `undefined` and self.id(def) isnt null
              data.results.unshift def  if $(data.results).filter(->
                equal self.id(this), self.id(def)
              ).length is 0
          if data.results.length is 0
            render "<li class='select2-no-results'>" + opts.formatNoMatches(search.val()) + "</li>"
            return
          $(data.results).each ->
            parts.push "<li class='select2-result'>"
            parts.push opts.formatResult(this)
            parts.push "</li>"

          parts.push "<li class='select2-more-results'>Loading more results...</li>"  if data.more is true
          render parts.join("")
          results.children(".select2-result").each (i) ->
            d = data.results[i]
            $(this).data "select2-data", d

          @postprocessResults data, initial
        )


    cancel: ->
      @close()

    blur: ->

      # we do this in a timeout so that current event processing can complete before this code is executed.
      #             this allows tab index to be preserved even if this code blurs the textfield
      window.setTimeout @bind(->
        @close()
        @container.removeClass "select2-container-active"
        @clearSearch()
        @selection.find(".select2-search-choice-focus").removeClass "select2-search-choice-focus"
        @search.blur()
      ), 10

    focusSearch: ->

      # we do this in a timeout so that current event processing can complete before this code is executed.
      #             this makes sure the search field is focussed even if the current event would blur it
      window.setTimeout @bind(->
        @search.focus()
      ), 10

    selectHighlighted: ->
      data = @results.find(".select2-highlighted:not(.select2-disabled)").data("select2-data")
      @onSelect data  if data

    getPlaceholder: ->
      @opts.element.attr("placeholder") or @opts.element.data("placeholder") or @opts.placeholder


    ###
    Get the desired width for the container element.  This is
    derived first from option `width` passed to select2, then
    the inline 'style' on the original element, and finally
    falls back to the jQuery calculated element width.

    @returns The width string (with units) for the container.
    ###
    getContainerWidth: ->
      style = undefined
      attrs = undefined
      matches = undefined
      i = undefined
      l = undefined
      return @opts.width  if @opts.width isnt `undefined`
      style = @opts.element.attr("style")
      if style isnt `undefined`
        attrs = style.split(";")
        i = 0
        l = attrs.length

        while i < l
          matches = attrs[i].replace(/\s/g, "").match(/width:(([-+]?([0-9]*\.)?[0-9]+)(px|em|ex|%|in|cm|mm|pt|pc))/)
          return matches[1]  if matches isnt null and matches.length >= 1
          i = i + 1
      @opts.element.width() + "px"

  class SingleSelect2 extends AbstractSelect2
    createContainer: ->
      $("<div></div>",
        class: "select2-container"
        style: "width: " + @getContainerWidth()
      ).html """
      <a href='javascript:void(0)' class='select2-choice'>
	<span></span><abbr class='select2-search-choice-close' style='display:none;'></abbr>
	<div><b></b></div>
      </a>
      <div class='select2-drop' style='display:none;'>
	<div class='select2-search'>
	  <input type='text' autocomplete='off'/>
	</div>
	<ul class='select2-results'>
	</ul>
      </div>
      """

    open: ->
      return  if @opened()
      super

    close: ->
      return  unless @opened()
      super

    focus: ->
      @close()
      @selection.focus()

    isFocused: ->
      @selection.is ":focus"

    cancel: ->
      super
      @selection.focus()

    initContainer: ->
      selection = undefined
      container = @container
      clickingInside = false
      selector = ".select2-choice"
      @selection = selection = container.find(selector)
      @search.bind "keydown", @bind((e) ->
        switch e.which
          when KEY.UP, KEY.DOWN
            @moveHighlight (if (e.which is KEY.UP) then -1 else 1)
            killEvent e
            return
          when KEY.TAB, KEY.ENTER
            @selectHighlighted()
            killEvent e
            return
          when KEY.ESC
            @cancel e
            e.preventDefault()
            return
      )
      container.delegate selector, "click", @bind((e) ->
        clickingInside = true
        if @opened()
          @close()
          selection.focus()
        else
          @open()
        e.preventDefault()
        clickingInside = false
      )
      container.delegate selector, "keydown", @bind((e) ->
        return  if e.which is KEY.TAB or KEY.isControl(e) or KEY.isFunctionKey(e) or e.which is KEY.ESC
        @open()

        # prevent the page from scrolling
        killEvent e  if e.which is KEY.PAGE_UP or e.which is KEY.PAGE_DOWN or e.which is KEY.SPACE

        # do not propagate the event otherwise we open, and propagate enter which closes
        killEvent e  if e.which is KEY.ENTER
      )
      container.delegate selector, "focus", ->
        container.addClass "select2-container-active"

      container.delegate selector, "blur", @bind(->
        return  if clickingInside
        @blur()  unless @opened()
      )
      selection.delegate "abbr", "click", @bind((e) ->
        @val ""
        killEvent e
        @close()
        @triggerChange()
      )
      @setPlaceholder()


    ###
    Sets selection based on source element's value
    ###
    initSelection: ->
      selected = undefined
      if @opts.element.val() is ""
        @updateSelection
          id: ""
          text: ""

      else
        selected = @opts.initSelection.call(null, @opts.element)
        @updateSelection selected  if selected isnt `undefined` and selected isnt null
      @close()
      @setPlaceholder()

    prepareOpts: ->
      opts = super arguments...
      if opts.element.get(0).tagName.toLowerCase() is "select"

        # install sthe selection initializer
        opts.initSelection = (element) ->
          selected = element.find(":selected")

          # a single select box always has a value, no need to null check 'selected'
          id: selected.attr("value")
          text: selected.text()
      opts

    setPlaceholder: ->
      placeholder = @getPlaceholder()
      if @opts.element.val() is "" and placeholder isnt `undefined`

        # check for a first blank option if attached to a select
        return  if @select and @select.find("option:first").text() isnt ""
        if typeof (placeholder) is "object"
          @updateSelection placeholder
        else
          @selection.find("span").html placeholder
        @selection.addClass "select2-default"
        @selection.find("abbr").hide()

    postprocessResults: (data, initial) ->
      selected = 0
      self = this
      showSearchInput = true

      # find the selected element in the result list
      @results.find(".select2-result").each (i) ->
        if equal(self.id($(this).data("select2-data")), self.opts.element.val())
          selected = i
          false


      # and highlight it
      @highlight selected

      # hide the search box if this is the first we got the results and there are a few of them
      if initial is true
        showSearchInput = data.results.length >= @opts.minimumResultsForSearch
        @search.parent().toggle showSearchInput

        #add "select2-with-searchbox" to the container if search box is shown
        @container[(if showSearchInput then "addClass" else "removeClass")] "select2-with-searchbox"

    onSelect: (data) ->
      old = @opts.element.val()
      @opts.element.val @id(data)
      @updateSelection data
      @close()
      @selection.focus()
      @triggerChange()  unless equal(old, @id(data))

    updateSelection: (data) ->
      @selection.find("span").html @opts.formatSelection(data)
      @selection.removeClass "select2-default"
      @selection.find("abbr").show()  if @opts.allowClear and @getPlaceholder() isnt `undefined`

    val: ->
      val = undefined
      data = null
      return @opts.element.val()  if arguments.length is 0
      val = arguments[0]
      if @select

        # val is an id
        @select.val(val).find(":selected").each ->
          data =
            id: $(this).attr("value")
            text: $(this).text()

          false

        @updateSelection data
      else

        # val is an object. !val is true for [undefined,null,'']
        @opts.element.val (if not val then "" else @id(val))
        @updateSelection val
      @setPlaceholder()

    clearSearch: ->
      @search.val ""

  class MultiSelect2 extends AbstractSelect2
    createContainer: ->
      $("<div></div>",
        class: "select2-container select2-container-multi"
        style: "width: " + @getContainerWidth()

      #"<li class='select2-search-choice'><span>California</span><a href="javascript:void(0)" class="select2-search-choice-close"></a></li>" ,
      ).html ["    <ul class='select2-choices'>", "  <li class='select2-search-field'>", "    <input type='text' autocomplete='off' style='width: 25px;'>", "  </li>", "</ul>", "<div class='select2-drop' style='display:none;'>", "   <ul class='select2-results'>", "   </ul>", "</div>"].join("")

    prepareOpts: ->
      opts = super arguments...
      opts = $.extend({},
        closeOnSelect: true
      , opts)

      # TODO validate placeholder is a string if specified
      if opts.element.get(0).tagName.toLowerCase() is "select"

        # install sthe selection initializer
        opts.initSelection = (element) ->
          data = []
          element.find(":selected").each ->
            data.push
              id: $(this).attr("value")
              text: $(this).text()


          data
      opts

    initContainer: ->
      selector = ".select2-choices"
      selection = undefined
      @searchContainer = @container.find(".select2-search-field")
      @selection = selection = @container.find(selector)
      @search.bind "keydown", @bind((e) ->
        if e.which is KEY.BACKSPACE and @search.val() is ""
          @close()
          choices = undefined
          selected = selection.find(".select2-search-choice-focus")
          if selected.length > 0
            @unselect selected.first()
            @search.width 10
            killEvent e
            return
          choices = selection.find(".select2-search-choice")
          choices.last().addClass "select2-search-choice-focus"  if choices.length > 0
        else
          selection.find(".select2-search-choice-focus").removeClass "select2-search-choice-focus"
        if @opened()
          switch e.which
            when KEY.UP, KEY.DOWN
              @moveHighlight (if (e.which is KEY.UP) then -1 else 1)
              killEvent e
              return
            when KEY.ENTER, KEY.TAB
              @selectHighlighted()
              killEvent e
              return
            when KEY.ESC
              @cancel e
              e.preventDefault()
              return
        return  if e.which is KEY.TAB or KEY.isControl(e) or KEY.isFunctionKey(e) or e.which is KEY.BACKSPACE or e.which is KEY.ESC
        @open()

        # prevent the page from scrolling
        killEvent e  if e.which is KEY.PAGE_UP or e.which is KEY.PAGE_DOWN
      )
      @search.bind "keyup", @bind(@resizeSearch)
      @container.delegate selector, "click", @bind((e) ->
        @open()
        @focusSearch()
        e.preventDefault()
      )
      @container.delegate selector, "focus", @bind(->
        @container.addClass "select2-container-active"
        @clearPlaceholder()
      )

      # set the placeholder if necessary
      @clearSearch()

    initSelection: ->
      data = undefined
      @updateSelection []  if @opts.element.val() is ""
      if @select or @opts.element.val() isnt ""
        data = @opts.initSelection.call(null, @opts.element)
        @updateSelection data  if data isnt `undefined` and data isnt null
      @close()

      # set the placeholder if necessary
      @clearSearch()

    clearSearch: ->
      placeholder = @getPlaceholder()
      if placeholder isnt `undefined` and @getVal().length is 0 and @search.hasClass("select2-focused") is false
        @search.val(placeholder).addClass "select2-default"

        # stretch the search box to full width of the container so as much of the placeholder is visible as possible
        @search.width @getContainerWidth()
      else
        @search.val("").width 10

    clearPlaceholder: ->
      @search.val("").removeClass "select2-default"  if @search.hasClass("select2-default")

    open: ->
      return  if @opened()
      super
      @resizeSearch()
      @focusSearch()

    close: ->
      return  unless @opened()
      super

    focus: ->
      @close()
      @search.focus()

    isFocused: ->
      @search.hasClass "select2-focused"

    updateSelection: (data) ->
      ids = []
      filtered = []
      self = this

      # filter out duplicates
      $(data).each ->
        if indexOf(self.id(this), ids) < 0
          ids.push self.id(this)
          filtered.push this

      data = filtered
      @selection.find(".select2-search-choice").remove()
      $(data).each ->
        self.addSelectedChoice this

      self.postprocessResults()

    onSelect: (data) ->
      @addSelectedChoice data
      @postprocessResults()  if @select
      if @opts.closeOnSelect
        @close()
        @search.width 10
      else
        @search.width 10
        @resizeSearch()

      # since its not possible to select an element that has already been
      # added we do not need to check if this is a new element before firing change
      @triggerChange()
      @focusSearch()

    cancel: ->
      @close()
      @focusSearch()

    addSelectedChoice: (data) ->
      choice = undefined
      id = @id(data)
      parts = undefined
      val = @getVal()
      parts = ["<li class='select2-search-choice'>", @opts.formatSelection(data), "<a href='javascript:void(0)' class='select2-search-choice-close' tabindex='-1'></a>", "</li>"]
      choice = $(parts.join(""))
      choice.find("a").bind("click dblclick", @bind((e) ->
        @unselect $(e.target)
        @selection.find(".select2-search-choice-focus").removeClass "select2-search-choice-focus"
        killEvent e
        @close()
        @focusSearch()
      )).bind "focus", @bind(->
        @container.addClass "select2-container-active"
      )
      choice.data "select2-data", data
      choice.insertBefore @searchContainer
      val.push id
      @setVal val

    unselect: (selected) ->
      val = @getVal()
      index = undefined
      selected = selected.closest(".select2-search-choice")
      throw "Invalid argument: " + selected + ". Must be .select2-search-choice"  if selected.length is 0
      index = indexOf(@id(selected.data("select2-data")), val)
      if index >= 0
        val.splice index, 1
        @setVal val
        @postprocessResults()  if @select
      selected.remove()
      @triggerChange()

    postprocessResults: ->
      val = @getVal()
      choices = @results.find(".select2-result")
      self = this
      choices.each ->
        choice = $(this)
        id = self.id(choice.data("select2-data"))
        if indexOf(id, val) >= 0
          choice.addClass "select2-disabled"
        else
          choice.removeClass "select2-disabled"

      choices.each (i) ->
        unless $(this).hasClass("select2-disabled")
          self.highlight i
          false


    resizeSearch: ->
      minimumWidth = undefined
      left = undefined
      maxWidth = undefined
      containerLeft = undefined
      searchWidth = undefined
      minimumWidth = measureTextWidth(@search) + 10
      left = @search.offset().left
      maxWidth = @selection.width()
      containerLeft = @selection.offset().left
      searchWidth = maxWidth - (left - containerLeft) - getSideBorderPadding(@search)
      searchWidth = maxWidth - getSideBorderPadding(@search)  if searchWidth < minimumWidth
      searchWidth = maxWidth - getSideBorderPadding(@search)  if searchWidth < 40
      @search.width searchWidth

    getVal: ->
      val = undefined
      if @select
        val = @select.val()
        (if val is null then [] else val)
      else
        val = @opts.element.val()
        splitVal val, ","

    setVal: (val) ->
      unique = []
      if @select
        @select.val val
      else

        # filter out duplicates
        $(val).each ->
          unique.push this  if indexOf(this, unique) < 0

        @opts.element.val (if unique.length is 0 then "" else unique.join(","))

    val: ->
      val = undefined
      data = []
      self = this
      return @getVal()  if arguments.length is 0
      val = arguments[0]
      if @select

        # val is a list of ids
        @setVal val
        @select.find(":selected").each ->
          data.push
            id: $(this).attr("value")
            text: $(this).text()


        @updateSelection data
      else
        val = (if (val is null) then [] else val)
        @setVal val

        # val is a list of objects
        $(val).each ->
          data.push self.id(this)

        @setVal data
        @updateSelection val
      @clearSearch()
  $.fn.select2 = ->
    args = Array::slice.call(arguments, 0)
    opts = undefined
    select2 = undefined
    value = undefined
    multiple = undefined
    allowedMethods = ["val", "destroy", "open", "close", "focus", "isFocused"]
    @each ->
      if args.length is 0 or typeof (args[0]) is "object"
        opts = (if args.length is 0 then {} else $.extend({}, args[0]))
        opts.element = $(this)
        if opts.element.get(0).tagName.toLowerCase() is "select"
          multiple = opts.element.attr("multiple")
        else
          multiple = opts.multiple or false
          opts.multiple = multiple = true  if "tags" of opts
        select2 = (if multiple then new MultiSelect2() else new SingleSelect2())
        select2.init opts
      else if typeof (args[0]) is "string"
        throw "Unknown method: " + args[0]  if indexOf(args[0], allowedMethods) < 0
        value = `undefined`
        select2 = $(this).data("select2")
        return  if select2 is `undefined`
        value = select2[args[0]].apply(select2, args.slice(1))
        false  if value isnt `undefined`
      else
        throw "Invalid arguments to select2 plugin: " + args

    (if (value is `undefined`) then this else value)


  # exports
  window.Select2 =
    query:
      ajax: ajax
      local: local
      tags: tags

    util:
      debounce: debounce

    class:
      abstract: AbstractSelect2
      single: SingleSelect2
      multi: MultiSelect2
) jQuery
