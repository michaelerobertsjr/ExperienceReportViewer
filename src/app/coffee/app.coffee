class View
  constructor: (@name) ->

  show: ->
    # hide other views
    $(".view-container").hide()

    # toggle navbar
    $(".navigation-link").removeClass "active"
    $("#navigation-"+@name).addClass "active"

    # show this view
    @_load()
    $("#"+@name+"-container").show()

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
      $("#"+$(this).attr("id")+" > .statements-list-item-details").toggle "fast"



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



class NavBar
  constructor: (views) ->
    for name, view of views
      @_registerViewLink view

  _registerViewLink: (view) ->
    $("#navigation-" + view.name).on "click", (e) ->
      view.show()


class Controller
  constructor: ->
    @views =
      statements: new StatementsView
      charts:     new ChartsView
      settings:   new SettingsView

    @navBar = new NavBar(@views)

    # default view
    @views.statements.show()




#################################################

$(document).ready () ->
  controller = new Controller
