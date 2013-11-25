var navigation = {
    init:function() {
        navigation.registerViewLinks();
    },
    registerViewLinks:function() {
        // show active view in nav var
        $("#navigation-statements").on("click", function(e) {
            view.statements.load();

            $(".navigation-link").removeClass("active");
            $("#navigation-statements").addClass("active");
        });
        $("#navigation-charts").on("click", function(e) {
            view.charts.load();

            $(".navigation-link").removeClass("active");
            $("#navigation-charts").addClass("active");
        });
        $("#navigation-settings").on("click", function(e) {
            view.settings.load();

            $(".navigation-link").removeClass("active");
            $("#navigation-settings").addClass("active");
        });
    }
}

var view = {
    init:function() {
        // TODO: Start-View laden
        view.statements.load();
        $("#navigation-statements").addClass("active");
    },
    load:function(viewName) {
        view[viewName].load();
    },
    statements: {
        load:function() {
            // hide views
            $(".view-container").hide();

            // fill table
            view.statements.fillTable();

            // load statements
            $("#statements-container").show();
        },
        fillTable:function() {
            var source = $("#view-template-statements-list").html();
            var template = Handlebars.compile(source);

            // TODO: AJAX-Request für Statements
            var statements = [
                { id: "1", actor: "I", verb: "wrote", activity: "code", timestamp: "yesterday" },
                { id: "2", actor: "I", verb: "write", activity: "code", timestamp: "today" },
                { id: "3", actor: "I", verb: "will write", activity: "code", timestamp: "tomorrow" },
                { id: "4", actor: "I", verb: "write", activity: "code", timestamp: "all the time" }
            ];
            // TODO: Handlebars Block Expression
            var statementsListHtml = "";
            for (var i = 0; i < statements.length; i++) {
                var context = statements[i];
                var entryHtml = template(context);
                statementsListHtml += entryHtml;
            }

            $("#statements-list").html(statementsListHtml);

            $(".statements-list-item").on("click", function(e) {
                // TODO
            });
        }
    },
    charts: {
        load:function() {
            // hide views
            $(".view-container").hide();

            // load charts
            $("#charts-container").show();
        }
    },
    settings: {
        load:function() {
            // hide views
            $(".view-container").hide();

            // load settings
            $("#settings-container").show();
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