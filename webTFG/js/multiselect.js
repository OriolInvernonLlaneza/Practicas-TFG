$(document).ready(function () {
    $("#dropFilters").multiselect({
        nonSelectedText: "Filtros tema",
        numberDisplayed: 2,
        nSelectedText: "Seleccionados",
        allSelectedText: "Todos",
        buttonWidth: "164px",
        onChange: function (element, checked) {
            checkbox(element["0"].value, checked);
        }
    });
});

$(document).ready(function () {
    d3.json("resources/topics.json", function (error, json) {
        for (let i = 0; i < json.length; i++) {
            $("#dropFilters").append("<option class='checks' title='" + json[i].name + "' value=" + json[i].name + ">" + json[i].name + "</option>");
        }
        $("#dropFilters").multiselect("rebuild");
    });
});

$(document).ready(function () {document.getElementById('tabC').click();});