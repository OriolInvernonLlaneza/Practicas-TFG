function createGraph(svg, graph) {

    var brush;
    var brushMode = false;
    var brushing = false;
    var shiftKey;
    var simulation;
    var node;
    var _d3 = d3;

    // take size from svg
    var width = +svg.attr("width"),
        height = +svg.attr("height");

    // color scheme
    var fill = _d3.scaleOrdinal(_d3.schemeCategory20);

    // remove any previous graphs
    svg.selectAll(".g-main").remove();

    // create main frame
    var gMain = svg.append("g")
        .classed("g-main", true);

    // append white rect to frame
    var rect = gMain.append("rect")
        .attr("width", width)
        .attr("height", height)
        .style("fill", "white");

    // append other g to frame    
    var gDraw = gMain.append("g");

    // force functions
    function dragstarted(d) {
        if (!_d3.event.active) { simulation.alphaTarget(0.3).restart(); }

        if (!d.selected && !shiftKey) {
            // if this node isn"t selected, then we have to unselect every other node
            node.classed("selected", function (p) {
                return p.selected = p.previouslySelected = false;
            });
        }

        _d3.select(this).classed("selected", function (p) {
            d.previouslySelected = d.selected;
            return d.selected = true; // selection
        });

        node.filter(function (d) { return d.selected; })
            .each(function (d) { // move the selected
                d.fx = d.x;
                d.fy = d.y;
            });

    }

    function dragged(d) {
        node.filter(function (d) { return d.selected; })
            .each(function (d) {
                d.fx += _d3.event.dx;
                d.fy += _d3.event.dy;
            });
    }

    function dragended(d) {
        if (!_d3.event.active) { simulation.alphaTarget(0); }
        d.fx = null;
        d.fy = null;
        node.filter(function (d) { return d.selected; })
            .each(function (d) {
                d.fx = null;
                d.fy = null;
            });
    }

    // zoom list
    function zoomed() {
        gDraw.attr("transform", _d3.event.transform); // transforms drawing with zoom event
    }

    var zoom = _d3.zoom() // Creates new zoom behavior (obj and func) https://github.com/_d3/_d3-zoom
        .on("zoom", zoomed); // add listener

    gMain.call(zoom);

    // return if no links are found
    if (!("links" in graph)) {
        //console.log("No links found");
        return;
    }

    // the brush needs to go before the nodes so that it doesn"t
    // get called when the mouse is over a node
    var gBrushHolder = gDraw.append("g");
    var gBrush = null;

    //define arrows
    gDraw.append("defs").append("marker")
        .attr("id", "arrow")
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 27.5)
        .attr("refY", -1)
        .attr("markerWidth", 6)
        .attr("markerHeight", 6)
        .attr("orient", "auto")
        .attr("stroke", "#999")
        .style("stroke-width", 0)
        .append("gDraw:path")
        .attr("d", "M0,-5L10,0L0,5")
        .style("stroke-width", 0);

    //add curved links, stroke <= number of letters
    var linkV = gDraw.selectAll(".link").data(graph.links).enter()
        .append("path").attr("source", function (d) {
            return d.source.id;
        }).attr("target", function (d) {
            return d.target.id;
        }).attr("class", "link")
        .attr("fill-opacity", 0)
        .attr("stroke-width", function (d) { return Math.sqrt(d.value); });

    //invisible path + arrow
    var edgepath = gDraw.selectAll(".edgepath").
        data(graph.links).enter()
        .append("path")
        .attr("class", "edgepath")
        .attr("id", function (d, i) { return "edgepath" + i; })
        .attr("source", function (d) {
            return d.source.id;
        }).attr("target", function (d) {
            return d.target.id;
        }).attr("fill-opacity", 0)
        .attr('marker-end', 'url(#arrow)');

    //add nodes
    node = gDraw.append("g")
        .attr("class", "node")
        .selectAll("circle")
        .data(graph.nodes)
        .enter().append("circle")
        .attr("r", 10)
        .attr("fill", function (d) { return d.color; })
        .call(_d3.drag() // drag functions on node
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));

    node.on("click", function (d) { callWikipediaAPI(d.wiki); });
    // tooltip titles
    node.append("title")
        .text(function (d) { return d.name; });

    //node label
    var label = gDraw.append("g")
        .attr("class", "label")
        .selectAll("label")
        .data(graph.nodes)
        .enter().append("text")
        .style("pointer-events", "none")
        .text(function (d) { return d.name; })
        .style("text-anchor", "middle")
        .style("fill", "#555")
        .style("font-family", "Arial")
        .style("font-size", 12);

    // path label
    var edgelabels = gDraw.selectAll(".edgelabel")
        .data(graph.links)
        .enter()
        .append("text")
        .style("pointer-events", "none")
        .attr("class", "edgelabel")
        .attr("id", function (d, i) { return "edgelabel" + i; })
        .style("fill", "#555")
        .style("font-family", "Arial")
        .style("font-size", 12);

    // path label text
    edgelabels.append("textPath")
        .attr("xlink:href", function (d, i) { return "#edgepath" + i; })
        .style("text-anchor", "middle")
        .style("pointer-events", "none")
        .attr("startOffset", "50%")
        .text(function (d) { return d.mood; });

    simulation = _d3.forceSimulation() // create and start simulation
        .force("link", _d3.forceLink().id(function (d) { return d.id; }).distance(100).strength(1))
        .force("charge", _d3.forceManyBody())
        .force("center", _d3.forceCenter(width / 2, height / 2));

    function linkArc(d) {
        var dx = d.target.x - d.source.x,
            dy = d.target.y - d.source.y,
            dr = Math.sqrt(dx * dx + dy * dy);
        return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " +
            d.target.x + "," + d.target.y;
    }

    function ticked() {
        // update node, label and path positions
        // at every step of the simulation

        node.attr("cx", function (d) { return d.x; })
            .attr("cy", function (d) { return d.y; });

        label.attr("x", function (d) { return d.x; })
            .attr("y", function (d) { return d.y - 10; });

        edgepath.attr("d", linkArc); 
        linkV.attr("d", linkArc);

        edgelabels.attr("transform", function (d) {
            if (d.target.x < d.source.x) { // rotate text 
                var bbox = this.getBBox(); // get svg bounding box

                var rx = bbox.x + bbox.width / 2;
                var ry = bbox.y + bbox.height / 2;
                return "rotate(180 " + rx + " " + ry + ")";
            }
            else {
                return "rotate(0)";
            }
        });
    }

    simulation
        .nodes(graph.nodes) // add nodes to simulation
        .on("tick", ticked);

    simulation.force("link") // add links to simulation
        .links(graph.links);

    //click on frame -> delete selection
    rect.on("click", () => {
        node.each(function (d) {
            d.selected = false;
            d.previouslySelected = false;
        });
        node.classed("selected", false); // Remove CSS class from the selection
    });

    function brushstarted() {
        // keep track of whether we"re actively brushing so that we
        // don"t remove the brush on keyup in the middle of a selection
        brushing = true;

        node.each(function (d) {
            d.previouslySelected = shiftKey && d.selected;
        });
    }

    function brushed() {
        if (!_d3.event.sourceEvent) { return; }
        if (!_d3.event.selection) { return; }

        var extent = _d3.event.selection; // brushable area

        node.classed("selected", function (d) { // node class selected if inside extent or prev selected.
            return d.selected = d.previouslySelected ^ // XOR
                (extent[0][0] <= d.x && d.x < extent[1][0]
                    && extent[0][1] <= d.y && d.y < extent[1][1]);
        });
    }

    function brushended() {
        if (!_d3.event.sourceEvent) { return; }
        if (!_d3.event.selection) { return; }
        if (!gBrush) { return; }

        gBrush.call(brush.move, null); // clear brush selection

        if (!brushMode) {
            // the shift key has been release before we ended our brushing
            gBrush.remove();
            gBrush = null;
        }

        brushing = false;
    }

    brush = _d3.brush() // brush functions
        .on("start", brushstarted)
        .on("brush", brushed)
        .on("end", brushended);

    function keydown() {
        shiftKey = _d3.event.shiftKey; //push shift

        if (shiftKey) { //if true shift was pressed
            // if brush on, do nothing
            if (gBrush) { return; }

            brushMode = true; // modo brush (mouse as cross)
            if (!gBrush) {
                gBrush = gBrushHolder.append("g");
                gBrush.call(brush);
            }
        }
    }

    function keyup() {
        shiftKey = false;
        brushMode = false;

        if (!gBrush) { return; }

        if (!brushing) {
            // only remove the brush if we"re not actively brushing
            // otherwise it"ll be removed when the brushing ends
            gBrush.remove();
            gBrush = null;
        }
    }

    _d3.select("body").on("keydown", keydown); // event handler that starts the brushing
    _d3.select("body").on("keyup", keyup); // event handler that ends the brushing

    return graph;
}