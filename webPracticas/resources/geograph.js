function createGraph(ngraph) {
    var overlay = new google.maps.OverlayView();

    // Add the container when the overlay is added to the map.
    overlay.onAdd = function () {

        //Google Map
        var map = new google.maps.Map(document.getElementById("d3"), {
            zoom: 9,
            mapTypeId: google.maps.MapTypeId.ROADMAP,
            center: new google.maps.LatLng(36.53, 139.06),
        });

        //OverLay
        var overlay = new google.maps.OverlayView();

        // Bind our overlay to the map…
        overlay.setMap(map);
    }
}

//Restart the visualisation after any node and link changes
function restart() {
    simulation.stop();
    _d3.selectAll("svg > *").remove();
    createGraph(graph);
}

//adjust threshold
function threshold(thresh) {
    graph.links.splice(0, graph.links.length);
    for (var i = 0; i < graphOG.links.length; i++) {
        if (graphOG.links[i].value > thresh) {
            graph.links.push(graphOG.links[i]);
        }
    }
    restart();
}

function addGeoGraph(resource, evt) {
    svg = _d3.select("#d3");
    _d3.json(resource, function (error, json) {
        if (!error) {
            graph = json;
            graphOG = JSON.parse(JSON.stringify(graph));
            createGraph(graph);
        }
    });
    // Declare all variables
    let i, tabcontent, tablinks;

    // Get all elements with class="tabcontent" and hide them
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }

    // Get all elements with class="tablinks" and remove the class "active"
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }

    document.getElementById("graph").style.visibility = "visible";
    evt.currentTarget.className += " active";
}