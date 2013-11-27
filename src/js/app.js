var navigation = {
    init:function() {
        navigation.registerBrandLink();
        navigation.registerViewLinks();
    },
    registerBrandLink:function() {
        $("#navigation-brand").on("click", function(e) {
            view.show();
        });
    },
    registerViewLinks:function() {
        // get all view objects with a load function
        var viewList = [];
        for (var viewName in view) {
            if (typeof view[viewName].load == "function") {
                viewList.push(viewName);
            }
        }

        // register navigation click event for each view
        viewList.map(function(viewName) {
            $("#navigation-"+viewName).on("click", function(e) {
                view.show(viewName);
            });
        });
    }
}

var view = {
    show:function(viewName) {
        // default case
        if (viewName == null) viewName = "statements";

        // hide old view
        $(".navigation-link").removeClass("active");
        $(".view-container").hide();

        // load view
        view[viewName].load();

        // show new view
        $("#navigation-"+viewName).addClass("active");
        $("#"+viewName+"-container").show();
    },
    statements: {
        load:function() {
            view.statements.fillTable();
        },
        fillTable:function() {
            // TODO: AJAX-Request für Statements
            // get statements
            var statements = [
                { id: "1", actor: "I", verb: "wrote", activity: "code", timestamp: "yesterday" },
                { id: "2", actor: "I", verb: "write", activity: "code", timestamp: "today" },
                { id: "3", actor: "I", verb: "write", activity: "code", timestamp: "all the time" }
            ];

            // fill statements list
            var template = Handlebars.compile($("#view-template-statements-list").html());
            var statementsListHtml = "";
            statements.map(function(context) {
                var entryHtml = template(context);
                statementsListHtml += entryHtml;
            });
            $("#statements-list").html(statementsListHtml);


            // register element click event
            $(".statements-list-item").on("click", function(e) {
                // show details
                var detailContainer = "#"+$(this).attr("id")+" > .statements-list-item-details";
                var hidden = $(detailContainer).data("hidden");
                hidden ? $(detailContainer).show("fast") : $(detailContainer).hide("fast");
                $(detailContainer).data("hidden", !hidden);
            });
        }
    },
    charts: {
        load:function() {

        }
    },
    settings: {
        load:function() {

        }
    }
}

$(document).ready(function() {
    navigation.init();
    view.show();
});