### model classes ###

class Config
  constructor: ->
    @defaults =
      defaultView: "statements"


  set: (itemName, itemValue) ->
    localStorage.setItem itemName, itemValue


  get: (itemName) ->
    data = localStorage.getItem itemName
    if not data?
      data = @defaults[itemName]
      if data?
        @set itemName, data
    data


  getArray: (itemName) ->
    data = @get itemName
    if data?
      data.split "," # TODO


  reset: ->
    # TODO: only delete items used by this app
    localStorage.clear()


class DataRequest
  # TODO: use custom LRS

  constructor: (@name) ->
    @baseUrl = "http://cloud.scorm.com/ScormEngineInterface/TCAPI/public/"
    @_setDefaultParams()


  _setDefaultParams: ->
    if @name == "statements"
      @params =
        limit: 50
        relatedActivities: false
        relatedAgents: false


  setParam: (name, value) ->
    @params[name] = value


  getParam: (name) ->
    @params[name]


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

    defaultError = ->
      console.log "#{@name} data request error"

    $.ajax
      url: url,
      method: "GET",
      beforeSend: (req) ->
        req.setRequestHeader "Authorization", authToken
      success: (res) ->
        success res if success?
      error: ->
        error() if error? else dedaultError() # TODO


### view classes ###

class View
  constructor: (@name) ->


  show: ->
    # hide other views
    $(".view-container").hide()
    # toggle navbar
    $(".navigation-link").removeClass "active"
    $("#navigation-#{@name}").addClass "active"
    # show this view
    @_load()
    $("##{@name}-container").show()


  _load: ->
    # load view (subclasses must override this method)


class StatementsView extends View
  constructor: ->
    super "statements"
    @_list = []
    @_more = ""


  # override
  _load: ->
    @_showStatements()


  _showStatements: ->
    # create request
    req = new DataRequest "statements"
    req.setParam "limit", 25
    $("#statements-list").html "Loading #{req.getParam "limit"} statements ..."
    successCallback = (res) ->
      @_list = res.statements
      @_more = res.more

      # evil workaround for some coffeescript bullshit
      list = @_list
      more = @_more

      # define how the list of statements shall be created
      createList = (list, more) ->
        console.log "creating the list"
        console.log list.length
        if more?
          moreToken = more
        # create statements list for templating
        nextOid = 0
        statementsList = []
        for s in list
          rawData = (JSON.stringify s, null, 4).replace /\n/g, "<br />"
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
          statementsListHtml += "<a >more</a>"
        $("#statements-list").html statementsListHtml
        # register statement click event
        $(".statements-list-item").on "click", (e) ->
          e.preventDefault()
          details = "##{$(this).attr("id")} > .statements-list-item-raw"
          $(details).toggle "fast"

      # initialize the list
      createList @_list, @_more

      # configure filters
      $("#statements-filter-general").on "keyup", (e) ->
        # general purpose filter: show all statements that contain the keyword
        e.preventDefault()
        value = e.target.value.toLowerCase()
        console.log value
        result = []
        for s in list
          actor = (if s.actor.name? then s.actor.name[0] else s.actor.mbox[0])
          verb = s.verb
          activity = (if s.object.id != "" then s.object.id else "something")
          timestamp = s.timestamp
          short = "#{actor} #{verb} #{activity} #{timestamp}".toLowerCase()
          if (new RegExp value).test(short) then result.push s

        $("#statements-list").html ""
        createList result

      $("#statements-filter-reset").on "click", (e) ->
        e.preventDefault()
        $("#statements-filter > input.filter").val ""
        $("#statements-list").html ""
        createList list, more

    # fire requets, show statements
    req.getData successCallback


class ChartsView extends View
  constructor: ->
    super "charts"


  #override
  _load: ->
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


  _drawChart: ->
    resolution = $("input[name=charts-resolution]:checked").val()
    limit = $("input[name=charts-limit]").val()

    req = new DataRequest "statements"
    req.setParam "limit", limit
    $("#charts-statements").html "Loading #{limit} statements ..."
    successCallback = (res) ->
      pointsOfTime = []
      data = []
      map = {}

      for s in res.statements
        parts = s.timestamp.split "-"
        if resolution == "daily"
          key = (parts[2].substr 0, 2) + "." + parts[1] + "." + parts[0]
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
          text: "statements"
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
    req.getData successCallback


class SettingsView extends View
  constructor: ->
    super "settings"


  #override
  _load: ->
    $("#settings").html ""

    #@_createDefaultViewSelectBox()
    @_createSettingsResetButton()


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
      console.log "neue default view: #{e.target.value}"
      config.set "defaultView", e.target.value


  _createSettingsResetButton: ->
    # create reset button for all settings
    $("#settings").append "<button id='settings-reset'>reset</button>"
    $("#settings-reset").on "click", (e) ->
      config.reset()


class NavBar
  constructor: (views) ->
    # register navbar click events
    for name, view of views
      @_registerViewLink view


  _registerViewLink: (view) ->
    # navbar click event
    $("#navigation-#{view.name}").on "click", (e) ->
      view.show()


### controller classes ###

class Application
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