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
      data.split "," # TODO


  # resets all configuration items
  #
  reset: ->
    localStorage.clear() # TODO: dont delete everything



# manager for requesting data from the associated learning record store
#
class DataRequest

  # builds a new ajax data request
  #
  # @param [String] name
  #     name of the data set
  #
  constructor: (@name) ->
    #@baseUrl = "http://cloud.scorm.com/ScormEngineInterface/TCAPI/public/"
    @baseUrl = "http://localhost:8080/api/"

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
    authToken = btoa "test:test" # TODO
    console.log url
    defaultError = ->
      console.log "#{@name} data request error"

    $.ajax
      url: url,
      method: "GET",
      beforeSend: (req) ->
        req.setRequestHeader "Authorization", authToken
      success: (res) ->
        console.log res
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
  #
  constructor: ->
    # initialize view
    super "statements"
    @_list = []
    @_more = ""

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
        when "agent"
          # TODO
        when "verb"
          searchvalue = encodeURIComponent("http://adlnet.gov/expapi/verbs/"+searchValue)
        when "activity"
          # TODO
        when "time"
          # TODO
        when "all"
          # TODO
      req.setParam searchSelector, searchValue
      console.log req
      show req
      return false

    $("#statements-search").on "keyup", (e) ->
      e.preventDefault()
      if e.keyCode == 13
        fSearch e

    $("#statements-search-button").on "click", (e) ->
      fSearch e


  # loads the list data
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
    # execute request
    $("#statements-list").html "Loading #{req.getParam "limit"} statements ..."
    req.getData (res) ->
      if res.statements != []
        @_list = res.statements
        @_more = res.more

        # define how the list of statements shall be created
        createList = (list, more) ->
          $("#statements-list").hide()
          if list? and list.length != 0
            if more?
              moreToken = more
            # create statements list for templating
            nextOid = 0
            statementsList = []
            for s in list
              rawData = (JSON.stringify s, null, 2).replace /\n/g, "<br />"
              statement =
                oid: nextOid++
                actor: (if s.actor.name? then s.actor.name[0] else s.actor.mbox[0])
                verb: s.verb
                activity: (if s.object.id != "" then s.object.id else "something")
                timestamp: s.timestamp
                raw: rawData
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
          else
            $("#statements-list").html("No statements found.")
          $("#statements-list").fadeIn 400


        # initialize the list
        createList @_list, @_more

        # evil workaround
        list = @_list
        more = @_more

        # configure filters
        handleFilterEvent = (input) ->
          # general purpose filter: show all statements that contain the keyword
          input = input.toLowerCase()
          result = []
          for s in list
            actor = (if s.actor.name? then s.actor.name[0] else s.actor.mbox[0])
            verb = s.verb
            activity = (if s.object.id != "" then s.object.id else "something")
            timestamp = s.timestamp

            filter =
              actor: $("#statements-filter-selector-actor").prop "checked"
              verb: $("#statements-filter-selector-verb").prop "checked"
              activity: $("#statements-filter-selector-activity").prop "checked"
              timestamp: $("#statements-filter-selector-timestamp").prop "checked"

            searchString = ""
            allSelected = filter.actor and filter.verb and filter.activity and filter.timestamp
            noneSelected = !filter.actor and !filter.verb and !filter.activity and !filter.timestamp
            if allSelected or noneSelected
              searchString = "#{actor} #{verb} #{activity} #{timestamp}"
            else
              if filter.actor then searchString += "#{actor} "
              if filter.verb then searchString += "#{verb} "
              if filter.activity then searchString += "#{activity} "
              if filter.timestamp then searchString += "#{timestamp} "
            searchString = searchString.toLowerCase()

            # scan search string for every word in the input string
            inputWords = input.split " "
            inputFound = true
            for word in inputWords
              if (new RegExp word).test(searchString) == false
                inputFound = false
            if inputFound then result.push s

          createList result

        $("#statements-filter").on "keyup", (e) ->
          e.preventDefault()
          handleFilterEvent e.target.value

        $("input[type=checkbox].filter").on "change", (e) ->
          handleFilterEvent $("#statements-filter").val()

        $("#statements-filter-reset").on "click", (e) ->
          e.preventDefault()
          $("#statements-filter > input.filter").val ""
          $('input[type=checkbox].filter').prop('checked', false);
          $("#statements-filter").val ""
          $("#statements-list").html ""
          handleFilterEvent ""


# charts view class
#
class ChartsView extends View

  # initializes the new view
  #
  constructor: ->
    super "charts"


  # loads the chart data
  #
  _load: -> #override
    draw = @_drawChart
    # draw again on settings change events
    draw()
    $("input[name=charts-resolution]").on "change", ->
      draw()
    $("input[name=charts-limit]").on "keydown", (e) ->
      if e.keyCode == 13
        e.preventDefault()
        draw()
    $("input[name=charts-limit]").on "change", ->
      draw()

    $("#charts-settings-toggle").on "click", (e) ->
      if $("#charts-settings-toggle").text() == "hide"
        newText = "show"
      else
        newText = "hide"
      $("#charts-settings-toggle").text newText
      $("#charts-settings").toggle "slow"


  # get statement data from LRS and create chart(s)
  #
  _drawChart: ->
    resolution = $("input[name=charts-resolution]:checked").val()
    limit = $("input[name=charts-limit]").val()

    req = new DataRequest "statements"
    req.setParam "limit", limit
    $("#charts-statements").html "Loading #{limit} statements ..."
    req.getData (res) ->
      pointsOfTime = []
      data = []
      map = {}

      if res.statements != []
        for s in res.statements
          parts = s.timestamp.split "-"
          if resolution == "daily"
            key = "#{parts[2].substr 0, 2}. #{parts[1]}. #{parts[0]}"
          else if resolution == "monthly"
            key = parts[1] + "." + parts[0]
          else if resolution == "yearly"
            key = parts[0]
          if map[key]? then map[key]++ else map[key] = 1

        # get number of statements
        for k, v of map
          pointsOfTime.push k
          data.push v

        if resolution != "yearly"
          pointsOfTime.reverse()
          data.reverse()

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




# settings view class
#
class SettingsView extends View

  # initializes the new view
  #
  constructor: ->
    super "settings"


  # loads the settings menu
  _load: -> #override
    $("#settings").html ""
    #@_createDefaultViewSelectBox()
    @_createSettingsResetButton()


  # creates a select box to change the default view
  #
  _createDefaultViewSelectBox: ->
    # TODO
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
    # TODO: select current default view on select box
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