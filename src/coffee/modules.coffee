# configuration manager class
#
class Config

  # construct a new configuration manager
  constructor: ->
    @defaults =
      defaultView: "statements"


  # sets a configuration value
  #
  # @param [String] itemName
  #     the items name
  # @param [String, Number] itemValue
  #     the items value
  #
  set: (itemName, itemValue) ->
    localStorage.setItem itemName, itemValue


  # returns the value of a configuration item
  #
  # @param [String] itemName
  #     the items name
  # @return [String, Number]
  #     the items value
  #
  get: (itemName) ->
    data = localStorage.getItem itemName
    if not data?
      data = @defaults[itemName]
      if data?
        @set itemName, data
    data


  # returns the value of a configuration item as an array
  #
  # @param [String] itemName
  #     the items name
  # @return [Array]
  #     the items value as an array
  #
  getArray: (itemName) ->
    data = @get itemName
    if data?
      data.split ","


  # resets all configuration items
  #
  reset: ->
    localStorage.clear()



# manager for requesting data from the associated learning record store
#
class DataRequest

  # builds a new ajax data request
  #
  # @param [String] name
  #     name of the data set
  #
  constructor: (@name) ->
    @baseUrl = "http://localhost:8080/api/"
    #@baseUrl = "http://cloud.scorm.com/ScormEngineInterface/TCAPI/public/"
    if @name == "statements"
      @params =
        limit: 50
        relatedActivities: false
        relatedAgents: false


  # adds a parameter to the ajax request
  #
  # @param [String] name
  #     parameter name
  # @param [String] value
  #     parameter value
  #
  setParam: (name, value) ->
    @params[name] = value


  # returns a parameter value
  #
  # @param [String] name
  #     parameter name
  # @return [String]
  #     parameter value
  #
  getParam: (name) ->
    @params[name]


  # executes the request and calls the given callback functions if possible
  #
  # @param [Function] success
  #     success callback function
  # @param [Function] error
  #     error callback function
  #
  getData: (success, error) ->
    # build url
    url = @baseUrl + @name
    # prepare request
    first = true
    for param, value of @params
      if first
        url += "?"
        first = false
      else
        url += "&"
      url += "#{param}=#{value}"
    authToken = btoa "test:test" # TODO: customize HTTP-Basic auth
    defaultError = ->
      console.log "#{@name} data request error"
    # execute request
    $.ajax
      url: url,
      method: "GET",
      beforeSend: (req) ->
        req.setRequestHeader "Authorization", authToken
      success: (res) ->
        if success? then success res
      error: ->
        if error? then error() else defaultError()



# base view class
#
class View

  # initializes a new view
  #
  # @param [String] name
  #     view name
  #
  constructor: (@name) ->


  # hides all other views and shows this view
  #
  show: ->
    # hide other views
    $(".view-container").hide()
    # toggle navbar
    $(".navigation-link").removeClass "active"
    $("#navigation-#{@name}").addClass "active"
    # show this view
    @_load()
    $("##{@name}-container").show()


  # load data to be shown in the view
  # subclasses must override this method
  #
  _load: ->
    # load view


# statements view class
#
class StatementsView extends View

  # initializes a new statements view
  # register search & filter interfaces
  #
  constructor: ->
    # initialize view
    super "statements"
    @_list = [] # contains the statement data in raw form
    @_more = "" # contains the more-token

    # register click events for the search & filter interface
    $("#statements-search-toggle").on "click", (e) ->
      $("#statements-search-area").toggle "slow"
      # default: show
      if $("#statements-search-toggle").text() == "show"
        newText = "hide"
      else
        newText = "show"
      $("#statements-search-toggle").text newText

    $("#statements-filter-toggle").on "click", (e) ->
      $("#statements-filter-form").toggle "slow"
      # default: hide
      if $("#statements-filter-toggle").text() == "hide"
        newText = "show"
      else
        newText = "hide"
      $("#statements-filter-toggle").text newText

    # register search mask
    show = @_showStatements
    fSearch = (e) -> # search function for later use
      # reset filter
      $("#statements-filter > input.filter").val ""
      $('input[type=checkbox].filter').prop('checked', false);
      $("#statements-filter").val ""
      $("#statements-list").html ""
      # request statements
      req = new DataRequest "statements"
      searchSelector = $("input[name=statements-search-selector]:checked").val()
      searchValue = $("#statements-search").val()
      switch searchSelector
        # TODO: implement agent and timestamp search
        # the selected search option must be added to the request url.
        # the search input will most likely be URI (e.g. verb, activity)
        # and must therefore be encoded/escaped
        when "verb"
          searchValue = encodeURIComponent(searchValue)
        when "activity"
          searchValue = encodeURIComponent(searchValue)
        else
          alert "#{searchSelector} search not implemented yet (CLICK ok)"
      if searchSelector != "all" # searchSelector = all => show all statements, no specific search
        req.setParam searchSelector, searchValue
      # request is prepared, now execute it
      show req
      #return false
    # end of: fSearch

    # search mask radio change event
    $("input[name=statements-search-selector]").on "change", (e) ->
      $("#statements-search").prop "disabled", (if e.target.value == "all" then true else false)
    # search mask key event
    $("#statements-search").on "keyup", (e) -> #
      e.preventDefault()
      if e.keyCode == 13 then fSearch e
    # search mask click event
    $("#statements-search-button").on "click", (e) ->
      fSearch e
    # disable form auto submit
    $("#statements-search").on "keypress", (e) ->
      if e.which == 13 then return false


  # loads the initial list data
  # this method is called when the statements view constructor is called
  #
  _load: -> # override
    req = new DataRequest "statements"
    req.setParam "limit", 25
    @_showStatements req


  # get statements from LRS and create a list
  # create event listeners for buttons and filters
  #
  # @param [DataRequest] req
  #     prepated date request
  #
  _showStatements: (req) ->
    $("#statements-list").html "Loading #{req.getParam "limit"} statements ..."
    # execute request
    req.getData (res) ->
      validReponse = false
      if $.isArray res
        validResponse = true
        @_list = res
      if res.statements? and $.isArray res.statements
        validResponse = true
        @_list = res.statements
        @_more = res.more

      if validResponse
        # the ajax response is valid, now build the list
        # define how the list of statements shall be created
        # this function will be used later
        createList = (list, more) ->
          # hide the old list
          $("#statements-list").hide()
          # if there are 1 or more statement to be shown:
          if list? and list.length != 0
            if more?
              moreToken = more
            # create statements list for templating
            nextOid = 0
            statementsList = []
            for s in list
              rawData = (JSON.stringify s, null, 2).replace /\n/g, "<br />"
              statement = Utility.formatStatement s
              statement.oid = nextOid++
              statement.raw = rawData
              statementsList.push statement
            # generate html
            listSelector = "#view-template-statements-list"
            template = Handlebars.compile $(listSelector).html()
            statementsListHtml = ""
            for statementData in statementsList
              statementsListHtml += template statementData
            if more?
              # TODO: more-token implementieren
              statementsListHtml += "<h5 align='center'><a>more ...</a><hr /></h5>"
            $("#statements-list").html statementsListHtml
            # register statement click event
            $(".statements-list-item").on "click", (e) ->
              e.preventDefault()
              details = "##{$(this).attr("id")} > .statements-list-item-raw"
              $(details).toggle "fast"
          # no statements found, show error message
          else
            $("#statements-list").html("No statements found.")
          # show statements list
          $("#statements-list").fadeIn 400
        # end of: createList

        # the list creation function is defined, now: create the initial list
        createList @_list, @_more

        # evil workaround
        list = @_list
        more = @_more

        # the handleFilterEvent is called when the filter input changes
        # @_list contains the raw statement list data from the lrs
        # the filter event function now scans this list for occurences of the filter input
        handleFilterEvent = (input) ->
          # general purpose filter: show all statements that contain the keyword
          input = input.toLowerCase()
          result = []
          # scan the list
          for s in list
            # first extract data from the raw statement
            statement = Utility.formatStatement s
            # find out which filters are checked
            filter =
              actor: $("#statements-filter-selector-actor").prop "checked"
              verb: $("#statements-filter-selector-verb").prop "checked"
              activity: $("#statements-filter-selector-activity").prop "checked"
              timestamp: $("#statements-filter-selector-timestamp").prop "checked"
            # build the search string (think of it as statement.toString() )
            # the search string will be scanned for occurences of the filter input
            searchString = ""
            allSelected = filter.actor and filter.verb and filter.activity and filter.timestamp
            noneSelected = !filter.actor and !filter.verb and !filter.activity and !filter.timestamp
            if allSelected or noneSelected
              searchString = "#{statement.actor} #{statement.verb} #{statement.activity} #{statement.timestamp}"
            else
              if filter.actor then searchString += "#{statement.actor} "
              if filter.verb then searchString += "#{statement.verb} "
              if filter.activity then searchString += "#{statement.activity} "
              if filter.timestamp then searchString += "#{statement.timestamp} "
            searchString = searchString.toLowerCase()
            # scan search string for every word in the input string
            inputWords = input.split " "
            inputFound = true
            for word in inputWords
              if (new RegExp word).test(searchString) == false
                inputFound = false
            # if words of the input were found in the search string, the statement will be added to the result list
            if inputFound then result.push s
          # every statement of the current statement list has been scanned,
          # now create the new statements list with the result of the filter event
          createList result
        # end of: handleFilterEvent

        # now the user input events are registered:
        # if the text input changes:
        $("#statements-filter").on "keyup", (e) ->
          # apply filter
          e.preventDefault()
          handleFilterEvent e.target.value
        # if the user clicks a checkbox:
        $("input[type=checkbox].filter").on "change", (e) ->
          # apply filter
          handleFilterEvent $("#statements-filter").val()
        # if the user resets the filter: apply filter
        $("#statements-filter-reset").on "click", (e) ->
          # reset filter
          e.preventDefault()
          $("#statements-filter > input.filter").val ""
          $('input[type=checkbox].filter').prop('checked', false);
          $("#statements-filter").val ""
          $("#statements-list").html ""
          # apply filter
          handleFilterEvent ""
        # disable auto form submit
        $("#statements-filter").on "keypress", (e) ->
          if e.which == 13 then return false
      else
        # invalid response from lrs
        console.log "invalid response from LRS"


# charts view class
#
class ChartsView extends View

  # initializes the new view
  #
  constructor: ->
    super "charts"


  # loads the chart data
  # this function is called when the constructor is called
  _load: -> #override
    draw = @_drawChart
    # initial draw
    draw()
    # draw again on chart settings change events:
    $("input[name=charts-resolution]").on "change", ->
      draw()
    $("input[name=charts-limit]").on "keydown", (e) ->
      if e.keyCode == 13
        e.preventDefault()
        draw()
    $("input[name=charts-limit]").on "change", ->
      draw()
    # show and hide settings
    $("#charts-settings-toggle").on "click", (e) ->
      if $("#charts-settings-toggle").text() == "hide"
        newText = "show"
      else
        newText = "hide"
      $("#charts-settings-toggle").text newText
      $("#charts-settings").toggle "slow"


  # get statement data from LRS and create chart
  #
  _drawChart: ->
    resolution = $("input[name=charts-resolution]:checked").val()
    limit = $("input[name=charts-limit]").val()

    req = new DataRequest "statements"
    req.setParam "limit", limit
    $("#charts-statements").html "Loading #{limit} statements ..."
    req.getData (res) ->
      $("#charts-statements").hide()
      map = {} # Key/Value = Date/Number of statements

      list = (if $.isArray res then res else res.statements)
      # if there is at least one statement to be displayed:
      if list.length > 0
        # first: collect data in map
        for s in list
          if s.timestamp?
            parts = s.timestamp.split "-"
            if resolution == "daily"
              key = "#{parts[2].substr 0, 2}. #{parts[1]}. #{parts[0]}"
            else if resolution == "monthly"
              key = parts[1] + "." + parts[0]
            else if resolution == "yearly"
              key = parts[0]
            if map[key]? then map[key]++ else map[key] = 1

        pointsOfTime = [] # contains all dates
        data = [] # contains numbers of statements on each day
        # get number of statements
        for k, v of map
          pointsOfTime.push k
          data.push v

        if resolution != "yearly"
          # i'm not sure why, but this is necessary
          pointsOfTime.reverse()
          data.reverse()

        if data.length > 0
          $("#charts-statements").highcharts
            title:
              text: "Statements"
              x: -20
            subtitle:
              text: resolution
              x: -20
            xAxis:
              categories: pointsOfTime
              labels:
                enabled: true
                overflow: true
                rotation: 90
            yAxis:
              min: 0
              title:
                text: ""
              plotLines: [
                { value: 0, width: 1, color: "#808080" }
              ]
            series: [{
              name: "number of statements"
              data: data
            }]
            plotOptions:
              series:
                dataLabels:
                  enabled: true
                  padding: 10
                  x: 0
                  y: -6
                  zIndex: 6
            credits:
              enabled: false
        else
          $("#charts-statements").html "No statements with timestamp found."
        $("#charts-statements").fadeIn 400



# settings view class
#
# the settings view is a big TODO
#
class SettingsView extends View

  # initializes the new view
  #
  constructor: ->
    super "settings"


  # loads the settings menu
  #
  _load: -> #override
    $("#settings").html ""
    #@_createDefaultViewSelectBox()
    @_createSettingsResetButton()


  # creates a select box to change the default view
  #
  _createDefaultViewSelectBox: ->
    id = "defaultView"
    # load select box template
    template = Handlebars.compile $("#view-template-settings-selectbox").html()
    # load template data
    context =
      id: id
      list: []
    viewList = config.getArray "views"
    for view in viewList
      viewName = (view.charAt 0).toUpperCase() + (view.slice 1)
      context.list.push {value: view, name: viewName}
    # apply context to template
    html = template context
    # add html to settings view
    $("#settings").append html
    # register select box change event
    $("#settings-defaultView").on "change", (e) ->
      config.set "defaultView", e.target.value


  # creates a button that resets the config
  #
  _createSettingsResetButton: ->
    # create reset button for all settings
    $("#settings").append "<button id='settings-reset'>reset</button>"
    $("#settings-reset").on "click", (e) ->
      config.reset()



# navigation bar class
#
class NavBar

  # create event listeners for the view links
  #
  # @param [Object] views
  #     views
  #
  constructor: (views) ->
    # register navbar click events
    for name, view of views
      @_registerViewLink view


  # registers a view link
  #
  _registerViewLink: (view) ->
    # navbar click event
    $("#navigation-#{view.name}").on "click", (e) ->
      view.show()


# contains utility methods
#
class Utility

  # returns a statement to be shown in the statements list
  #
  # @param [Object] s
  #
  #
  @formatStatement: (s) ->
    statement = {}
    # read actor
    actor = "Someone"
    if s.actor.name?
      if $.isArray s.actor.name
        actor = s.actor.name[0]
      else
        actor = s.actor.name
    else if s.actor.account?
      actor = s.actor.account.name
    else if s.actor.mbox?
      if $.isArray s.actor.mbox
        actor = s.actor.mbox[0]
      else
        actor = s.actor.mbox
    statement.actor = actor

    # read verb
    verb = "experienced"
    if s.verb.display?
      if s.verb.display['en-US']?
        verb = s.verb.display['en-US']
      else if s.verb.display['und']
        verb = s.verb.display['und']
    else
      if s.verb.id?
        verb = s.verb.id
      else
        verb = s.verb
    statement.verb = verb

    # read activity
    activity = "something"
    if s.object.id?
      if s.object.id != ""
        activity = s.object.id
    statement.activity = activity

    #read timestamp
    statement.timestamp = s.timestamp
    return statement



# application main class
#
class Application

  # creates a new report viewer
  #
  constructor: ->
    # create views
    @views =
      statements: new StatementsView
      charts: new ChartsView
      settings: new SettingsView
    # create navbar
    @navBar = new NavBar @views
    # show default view
    @views[config.get "defaultView"].show()
    $(document).on "keyup", (e) ->
      e.preventDefault()
