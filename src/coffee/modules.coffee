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
    data.split ","


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


  # override
  _load: ->
    @_showStatements()


  _showStatements: ->
    # create request
    url = "http://cloud.scorm.com/ScormEngineInterface/TCAPI/public/statements"
    requestParams =
      limit: 25
      relatedActivities: false
      relatedAgents: false
    first = true
    for param, value of requestParams
      if first
        url += "?"
        first = false
      else
        url += "&"
      url += "#{param}=#{value}"
    authToken = btoa "test:test"

    # get statements
    $.ajax({
      url: url,
      method: "GET",
      beforeSend: (req) ->
        req.setRequestHeader "Authorization", authToken
      success: (res) ->
        # create statements list for templating
        nextOid = 0
        statementsList = []
        for s in res.statements
          console.log s
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
        $("#statements-list").html statementsListHtml
        # register statement click event
        $(".statements-list-item").on "click", (e) ->
          e.preventDefault()
          details = "##{$(this).attr("id")} > .statements-list-item-raw"
          $(details).toggle "fast"
    });


class ChartsView extends View
  constructor: ->
    super "charts"


  #override
  _load: ->


class SettingsView extends View
  constructor: ->
    super "settings"


  #override
  _load: ->
    $("#settings").html ""

    @_createDefaultViewSelectBox()
    @_createSettingsResetButton()


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
    # TODO select current default view on select box
    # register select box change event
    $("#settings-defaultView").on "change", (e) ->
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