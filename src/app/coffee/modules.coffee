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
      @set itemName, data
    data


  getArray: (itemName) ->
    data = @get itemName
    data.split(",")




class View
  constructor: (@name) ->


  show: ->
    # hide other views
    $(".view-container").hide()
    # toggle navbar
    $(".navigation-link").removeClass "active"
    $("#navigation-" + @name).addClass "active"
    # show this view
    @_load()
    $("#" + @name + "-container").show()


  _load: ->
    # load view (subclasses must override this method)




class StatementsView extends View
  constructor: ->
    super "statements"


  # override
  _load: ->
    @_showStatements()


  _showStatements: ->
    # TODO: get statements from LRS
    statementsList = [
      {id: "1", actor: "I", verb: "wrote", activity: "code", timestamp: "yesterday"},
      {id: "2", actor: "I", verb: "write", activity: "code", timestamp: "today" },
      {id: "3", actor: "I", verb: "write", activity: "code", timestamp: "all the time"}
    ]
    # fill statements list
    template = Handlebars.compile $("#view-template-statements-list").html()
    statementsListHtml = ""
    for statementData in statementsList
      statementsListHtml += template statementData
    $("#statements-list").html statementsListHtml
    # register statement click event
    $(".statements-list-item").on "click", (e) ->
      $("#" + $(this).attr("id") + " > .statements-list-item-details").toggle "fast"




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
    @_createDefaultViewSelectBox()
    @_createSettingsResetButton()


  _createDefaultViewSelectBox: ->
    id = "defaultView"
    # load select box template
    template = Handlebars.compile $("#view-template-settings-selectbox").html()
    # load template data
    context =
      id:   id
      list: []
    viewList = config.getArray "views"
    for view in viewList
      viewName = (view.charAt 0).toUpperCase() + (view.slice 1)
      context.list.push {value: view , name: viewName}
    # apply context
    html = template context
    # add html to settings view
    $("#settings").append html
    # register change event
    $("#settings-defaultView").on "change", (e) ->
      config.set "defaultView", e.target.value
    # TODO select current default view on select box


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
    $("#navigation-" + view.name).on "click", (e) ->
      view.show()




class Application
  constructor: ->
    # create views
    @views =
      statements: new StatementsView
      charts:     new ChartsView
      settings:   new SettingsView
    # create navbar
    @navBar = new NavBar @views
    # show default view
    @views[config.get "defaultView"].show()