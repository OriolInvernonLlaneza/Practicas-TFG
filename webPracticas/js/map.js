function createMap() {
    let map = d3.select("#map");

    // take size from map
    let width = map.attr("width"),
        height = map.attr("height");

    // remove any previous graphs
    map.selectAll(".g-main").remove();

    // create main frame
    let mapMain = map.append("g")
        .classed("g-main", true);

    // append draw    
    let mapDraw = mapMain.append("g");

    //color scheme
    var color = d3.scaleOrdinal(d3.schemeCategory20);

    //define arrows
    mapDraw.append("defs").append("marker")
        .attr("id", "mArrow")
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 20)
        .attr("refY", 0)
        .attr("markerWidth", 1)
        .attr("markerHeight", 1)
        .attr("orient", "auto")
        .style("stroke-width", 0)
        .append("mapDraw:path")
        .attr("d", "M0,-5L10,0L0,5")
        .style("stroke-width", 0);

    // zoom list
    function mZoomed() {
        mapMain.attr("transform", d3.event.transform); // transforms drawing with zoom event
    }

    let mZoom = d3.zoom() // Creates new zoom behavior (obj and func) https://github.com/_d3/_d3-zoom
        .on("zoom", mZoomed); // add listener

    mapMain.call(mZoom);

    let projection = d3.geoEquirectangular() //d3 projection type
        .center([8, 48]) //center around GER
        .scale(width); //zoom on europe

    let path = d3.geoPath().projection(projection);

    let graticule = d3.geoGraticule();

    let div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0);

    d3.json("resources/world-50m.json", function (error, world) { //load map

        mapDraw.append("g")
            .attr("class", "land")
            .selectAll("path")
            .data([topojson.feature(world, world.objects.land)])
            .enter().append("path")
            .attr("d", path);

        mapDraw.append("g")
            .attr("class", "boundary")
            .selectAll("boundary")
            .data([topojson.feature(world, world.objects.countries)])
            .enter().append("path")
            .attr("d", path);

        mapDraw.append("g")
            .attr("class", "graticule")
            .selectAll("path")
            .data(graticule.lines)
            .enter().append("path")
            .attr("d", path);

        d3.json("resources/j.1.json", function (error, json) { //load data json
            let mNodes = json.nodes;
            let mLinks = json.links;

            mLinks.forEach(function (l) {
                l.source = mNodes[l.source - 1];
                l.destination = mNodes[l.destination - 1];
            });

            let accLinks = [];
            mLinks.forEach(function (l) {
                let isNew = true;
                for (i = 0; i < accLinks.length; i++) {
                    let aux = accLinks[i];
                    if (aux.destination.name === l.destination.name && aux.source.name === l.source.name) {
                        aux.value++;
                        isNew = false;
                    }
                }

                if (isNew) {
                    let newLink = { source: l.source, destination: l.destination, value: 1 };
                    accLinks.push(newLink);
                }
            });

            function arc(d) {
                let coordDe = projection([d.destination.long, d.destination.lat]),
                    coordOr = projection([d.source.long, d.source.lat]);
                let dx = coordDe[0] - coordOr[0],
                    dy = coordDe[1] - coordOr[1],
                    dr = Math.sqrt(dx * dx + dy * dy);
                return "M" + coordOr[0] + "," + coordOr[1] + "A" + dr + "," + dr + " 0 0,1 " +
                    coordDe[0] + "," + coordDe[1];
            }

            function popUp(d) {
                div.transition()
                    .duration(200)
                    .style("opacity", .9);
                /*div.html("Origen: " + d.author + "<br/>Destino: " + d.correspondent)
                    .style("left", (d3.event.pageX) + "px")
                    .style("top", (d3.event.pageY - 28) + "px");*/
                div.html("Cartas: " + d.value)
                    .style("left", (d3.event.pageX) + "px")
                    .style("top", (d3.event.pageY - 28) + "px")
            }

            function popOff() {
                div.transition()
                    .duration(500)
                    .style("opacity", 0);
            }

            //add curved links, stroke <= number of letters
            /*let link = mapDraw.selectAll(".link").data(mLinks).enter()
                .append("path")
                .attr("source", function (d) {
                    return d.source;
                }).attr("target", function (d) {
                    return d.destination;
                }).attr("class", "link")
                .attr("fill-opacity", 0)
                .attr("stroke-width", 1)
                .attr("stroke", "cyan")
                .attr("marker-end", "url(#mArrow)")
                .attr("d", function (d) { return arc(d); })
                .on("mouseover", function (d, i) {
                    d3.select(this).style("stroke", "red");
                    popUp(d);
                }).on("mouseout", function (d, i) {
                    d3.select(this).style("stroke", "cyan");
                    popOff();
                });*/

            let link = mapDraw.selectAll(".link").data(accLinks).enter()
                .append("path")
                .attr("source", function (d) {
                    return d.source;
                }).attr("target", function (d) {
                    return d.destination;
                }).attr("class", "link")
                .attr("fill-opacity", 0)
                .attr("stroke-width", function (d) {
                    return Math.sqrt(d.value);
                })
                .attr("stroke", function (d) {
                    return color(d.value);
                })
                .attr("marker-end", "url(#mArrow)")
                .attr("d", function (d) { return arc(d); })
                .on("mouseover", function (d, i) {
                    d3.select(this).style("stroke", "red");
                    popUp(d);
                }).on("mouseout", function (d, i) {
                    d3.select(this).style("stroke", color(d.value));
                    popOff();
                });

            //add nodes
            let mNode = mapDraw.append("g")
                .selectAll(".node")
                .data(d3.values(mNodes))
                .attr("class", "node")
                .enter().append("circle")
                .attr("r", 1)
                .attr("cx", function (d) {
                    let aux = [d.long, d.lat];
                    return projection(aux)[0];
                })
                .attr("cy", function (d) {
                    let aux = [d.long, d.lat];
                    return projection(aux)[1];
                })
                .attr("fill", "GoldenRod");

            // tooltip titles
            mNode.append("title").text(function (d) { return d.name; });

            // path label
            let mapLabels = mapDraw.selectAll(".mlabel")
                .data(mLinks)
                .enter()
                .append("text")
                .style("pointer-events", "none")
                .attr("class", "mlabel")
                .attr("id", function (d, i) { return "mlabel" + i; })
                .style("fill", "#fff")
                .style("font-family", "Arial")
                .style("font-size", 12);

            // path label text
            mapLabels.append("textPath")
                .attr("xlink:href", function (d, i) { return "#mpath" + i; })
                .style("text-anchor", "middle")
                .style("pointer-events", "none")
                .attr("startOffset", "50%")
                .text(function (d) { return d.mood; });
        });
    });
}