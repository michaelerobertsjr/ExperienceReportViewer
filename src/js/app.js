var navigation = {
    init:function() {
        navigation.registerStatements();
    },
    registerStatements:function() {
        $("#navigation-statements").on('click', function(e) {
            view.statements.init();
        });
        $("#navigation-charts").on('click', function(e) {
            view.charts.init();
        });
    }
}

var view = {
    default: "statements",
    init:function() {
        view.loadDefault();
    },
    loadDefault:function() {
        if (view.default == "statements") {
            view.statements.init();
        } else if (view.default == "charts") {
            view.charts.init();
        } else { // error case
            view.statements.init();
        }
    },
    statements: {
        init:function() {
            // hide views
            $(".view-container").hide();

            // fill table
            view.statements.fillTable();

            // load statements table
            $("#statements-container").show();
        },
        fillTable:function() {
            var source = $("#view-template-statements-list").html();
            var template = Handlebars.compile(source);

            // TODO: AJAX-Request für Statements
            var statements = [
                { actor: "I", verb: "wrote", activity: "code", time: "yesterday" },
                { actor: "I", verb: "write", activity: "code", time: "today" },
                { actor: "I", verb: "will write", activity: "code", time: "tomorrow" },
                { actor: "I", verb: "write", activity: "code", time: "all the time" }
            ];
            // TODO: Handlebars Block Expression
            var statementsListHtml = "";
            for (var i = 0; i < statements.length; i++) {
                var context = statements[i];
                var entryHtml = template(context);
                statementsListHtml += entryHtml;
            }

            $("#statements-list").html(statementsListHtml);

            $(".statements-list-item").on('click', function(e) {
                alert(e);
            });
        }
    },
    charts: {
        init:function() {
            // hide views
            $(".view-container").hide();

            // load statements table
            $("#charts-container").show();
        }
    }
}

var app = {
    init:function() {
        navigation.init();
        view.init();
    }
}

$(document).ready(function() {
    app.init();
});