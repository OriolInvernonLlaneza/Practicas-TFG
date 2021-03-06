let linkV;
let edgepath;
let node;
let edgelabels;
let label;
let svg;
let graph;
let simulation;
let graphOG;
let restarted;
let wGraph;

function createGraph(ngraph) {

    if (ngraph === null || ngraph.links.length === 0 || ngraph.nodes.length === 0) {
        alert("No hay resultados con los filtros actuales");
        return;
    } //No nodes due to filters

    let brush;
    let brushMode = false;
    let brushing = false;
    let shiftKey;

    // jquery search and autocomplete
    let optArray = [];
    for (let i = 0; i < ngraph.nodes.length - 1; i++) {
        optArray.push(ngraph.nodes[i].fname); //all node names
    }
    optArray = optArray.sort();
    $(function () {
        $("#search").autocomplete({
            source: optArray
        });
    });

    svg.attr("width", svg.node().parentNode.clientWidth)
        .attr("height", 500); //create svg

    // take size from svg
    let width = +svg.attr("width"),
        height = +svg.attr("height");

    // color scheme
    let fill = d3.scaleQuantize().domain([1, Math.sqrt(ngraph.links[0].value)]).range(d3.schemeCategory10);

    // remove any previous graphs
    svg.selectAll(".g-main").remove();

    // create main frame
    let gMain = svg.append("g")
        .classed("g-main", true);

    // append white rect to frame
    let rect = gMain.append("rect")
        .attr("width", width)
        .attr("height", height)
        .style("fill", "white");

    // append draw    
    let gDraw = gMain.append("g");

    // force functions
    function dragstarted(d) {
        if (!d3.event.active) { simulation.alphaTarget(0.3).restart(); }

        if (!d.selected && !shiftKey) {
            // if node isnt selected -> unselect every other node
            node.classed("selected", function (p) {
                return p.selected = p.previouslySelected = false;
            });
        }

        d3.select(this).classed("selected", function (p) {
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
                d.fx += d3.event.dx;
                d.fy += d3.event.dy;
            });
    }

    function dragended(d) {
        if (!d3.event.active) { simulation.alphaTarget(0); }
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
        gDraw.attr("transform", d3.event.transform); // transforms drawing with zoom event
    }

    let zoom = d3.zoom() // Creates new zoom behavior (obj and func) https://github.com/d3/d3-zoom
        .on("zoom", zoomed); // add listener

    gMain.call(zoom).on("dblclick.zoom", null); //disable zoom on doubleclick

    // return if no links are found
    if (!("links" in ngraph)) {
        //console.log("No links found");
        return;
    }

    // the brush needs to go before the nodes so that it doesn"t
    // get called when the mouse is over a node
    let gBrushHolder = gDraw.append("g");
    let gBrush = null;

    //define arrows
    gDraw.append("defs").append("marker")
        .attr("id", "arrow")
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 19)
        .attr("refY", -1)
        .attr("markerWidth", 6)
        .attr("markerHeight", 6)
        .attr("orient", "auto")
        .attr("stroke", "#999")
        .style("stroke-width", 0)
        .append("gDraw:path")
        .attr("d", "M0,-5L10,0L0,5")
        .style("stroke-width", 0);

    function showArrow(d, i) {
        let path = d3.select("#edgepath" + i);
        if (d.target.id === 1) { //Jovellanos is always id 1
            path.style("visibility", "visible");
        }
    }

    function hideArrow(d, i) {
        let path = d3.select("#edgepath" + i);
        if (d.target.id === 1) { //Jovellanos is always id 1
            path.style("visibility", "hidden");
        }
    }

    //add curved links, stroke <= number of letters
    linkV = gDraw.selectAll(".link").data(ngraph.links).enter()
        .append("path")
        .attr("id", function (d, i) { return "link" + i; })
        .attr("class", "link")
        .attr("fill-opacity", 0)
        .attr("stroke-width", function (d) { return Math.sqrt(d.value); })
        .attr("stroke", function (d) { return fill(Math.sqrt(d.value)); })
        .on("mouseover", function (d, i) {
            d3.select(this).style("stroke", "red");
            showArrow(d, i);
        }).on("mouseout", function (d, i) {
            d3.select(this).style("stroke", function (d) { return fill(Math.sqrt(d.value)); });
            hideArrow(d, i);
        });

    //invisible path + arrow
    edgepath = gDraw.selectAll(".edgepath").
        data(ngraph.links).enter()
        .append("path")
        .attr("class", "edgepath")
        .attr("id", function (d, i) { return "edgepath" + i; })
        .attr("fill-opacity", 0)
        .attr("marker-end", "url(#arrow)")
        .attr("visibility", function (d) {
            if (d.target === 1) { // id=1 is Jovellanos (avoid reduced visibility)
                return "hidden";
            } else {
                return "visible";
            }
        });

    //add nodes
    node = gDraw.append("g")
        .attr("class", "node")
        .selectAll("circle")
        .data(ngraph.nodes)
        .enter().append("circle")
        .attr("r", 5)
        .attr("fill", function (d) {
            if (d.hasOwnProperty("color") && d.color !== "") {
                return d.color;
            } else {
                return "GoldenRod";
            }
        })
        .call(d3.drag() // drag functions on node
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));

    node.on("click", function (d) { callWikipediaAPI(d.wiki); });

    // tooltip titles
    node.append("title")
        .text(function (d) { return d.fname; });

    //node label
    label = gDraw.append("g")
        .attr("class", "label")
        .selectAll("label")
        .data(ngraph.nodes)
        .enter().append("text")
        .style("pointer-events", "none")
        .text(function (d) {
            if (d.hasOwnProperty("name")) {
                return d.name;
            } else {
                return "";
            }
        })
        .style("text-anchor", "middle")
        .style("fill", "#000")
        .style("font-family", "Arial")
        .style("font-size", 12);

    // path label
    edgelabels = gDraw.selectAll(".edgelabel")
        .data(ngraph.links)
        .enter()
        .append("text")
        .style("pointer-events", "none")
        .attr("class", "edgelabel")
        .attr("id", function (d, i) { return "edgelabel" + i; })
        .style("fill", "#000")
        .style("font-family", "Arial")
        .style("font-size", 12);

    // path label text
    edgelabels.append("textPath")
        .attr("xlink:href", function (d, i) { return "#edgepath" + i; })
        .style("text-anchor", "middle")
        .style("pointer-events", "none")
        .attr("startOffset", "50%")
        .text(function (d) { return ""; }); // too many things on screen rn to use this

    simulation = d3.forceSimulation() // create and start simulation
        .force("link", d3.forceLink().id(function (d) { return d.id; }).distance(100).strength(0.5))
        .force("charge", d3.forceManyBody())
        .force("collide", d3.forceCollide().radius(18).iterations(5))
        .force("center", d3.forceCenter(width / 2, height / 2));

    function linkArc(d) { //curve links
        let dx = d.target.x - d.source.x,
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
            .attr("y", function (d) { return d.y - 5; });

        edgepath.attr("d", linkArc);
        linkV.attr("d", linkArc);

        edgelabels.attr("transform", function (d) {
            if (d.target.x < d.source.x) { // rotate text 
                let bbox = this.getBBox(); // get svg bounding box

                let rx = bbox.x + bbox.width / 2;
                let ry = bbox.y + bbox.height / 2;
                return "rotate(180 " + rx + " " + ry + ")";
            }
            else {
                return "rotate(0)";
            }
        });
    }

    simulation
        .nodes(ngraph.nodes) // add nodes to simulation
        .on("tick", ticked);

    simulation.force("link") // add links to simulation
        .links(ngraph.links);

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
        if (!d3.event.sourceEvent) { return; }
        if (!d3.event.selection) { return; }

        let extent = d3.event.selection; // brushable area

        node.classed("selected", function (d) { // node class selected if inside extent or prev selected.
            return d.selected = d.previouslySelected ^ // XOR
                (extent[0][0] <= d.x && d.x < extent[1][0]
                    && extent[0][1] <= d.y && d.y < extent[1][1]);
        });
    }

    function brushended() {
        if (!d3.event.sourceEvent) { return; }
        if (!d3.event.selection) { return; }
        if (!gBrush) { return; }

        gBrush.call(brush.move, null); // clear brush selection

        if (!brushMode) {
            // the shift key has been release before we ended our brushing
            gBrush.remove();
            gBrush = null;
        }

        brushing = false;
    }

    brush = d3.brush() // brush functions
        .on("start", brushstarted)
        .on("brush", brushed)
        .on("end", brushended);

    function keydown() {
        shiftKey = d3.event.shiftKey; //push shift

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

    d3.select("body").on("keydown", keydown); // event handler that starts the brushing
    d3.select("body").on("keyup", keyup); // event handler that ends the brushing

    //Toggle stores whether the highlighting is on
    let toggle = false;

    //Create an array logging what is connected to what
    let linkedByIndex = {};
    for (let j = 0; j < ngraph.nodes.length; j++) {
        linkedByIndex[j + "," + j] = 1; // nodes are connected to themselves
    }

    ngraph.links.forEach(function (d) {
        linkedByIndex[d.source.index + "," + d.target.index] = 1; // link(a,b) -> connected(a,b)
    });

    //This function looks up whether a pair are neighbours
    function isNeighbouring(a, b) {
        return linkedByIndex[a.index + "," + b.index];
    }

    function connectedNodes() {
        if (!toggle) {
            //Reduce the opacity of every non-neighbour
            let d = d3.select(this).node().__data__;

            node.style("opacity", function (o) {
                return isNeighbouring(d, o) | isNeighbouring(o, d) ? 1 : 0.1;
            });

            linkV.style("opacity", function (o) {
                return d.index === o.source.index | d.index === o.target.index ? 1 : 0.1;
            });

            edgepath.style("opacity", function (o) {
                return d.index === o.source.index | d.index === o.target.index ? 1 : 0.1;
            });

            edgelabels.style("opacity", function (o) {
                return d.index === o.source.index | d.index === o.target.index ? 1 : 0.1;
            });

            toggle = true;
        } else {
            //Restore opacity
            node.style("opacity", 1);
            linkV.style("opacity", 1);
            edgepath.style("opacity", 1);
            edgelabels.style("opacity", 1);
            toggle = false;
        }
    }
    node.on("dblclick", connectedNodes); // dblclick listener (neigh)

    //waits for graph to stop moving
    if (!restarted) {
        while (simulation.alpha() > 0.1) {
            simulation.tick();
        }
    }
    restarted = false;
    return ngraph;
}

//search function
function searchNode() {
    //find the node
    let selectedVal = document.getElementById("search").value;
    if (selectedVal !== "" && selectedVal !== "none") {
        let selected = node.filter(function (d, i) {
            return d.fname !== selectedVal;
        });
        //Reduce the opacity of the non searched
        selected.style("opacity", 0);
        linkV.style("opacity", 0);
        edgepath.style("opacity", 0);
        edgelabels.style("opacity", 0);
        d3.selectAll("circle, .link, .edgepath, .edgelabel").transition()
            .duration(5000) // restore opacity
            .style("opacity", 1);
    }
}

//Restart the visualisation after any node and link changes
function restart() {
    simulation.stop();
    d3.selectAll("#d3 > *").remove();
    restarted = true;
    createGraph(graph);
}

let currentThreshValue = 0;
function linksByValue(links) {//push link by value (n of cards)
    graph.links = [];
    for (let i = 0; i < links.length; i++) {
        if (links[i].value > currentThreshValue) {
            graph.links.push({ ...links[i] });
        }
    }
}


function linksByTopic() {//filter links by topics selected on filters
    let topicsSelected = $("#dropFilters").val();
    if (topicsSelected.length === 1 && topicsSelected.includes("womanCheck")) {
        graph = { ...wGraph }; //if only woman filter, copy women data
        linksByValue(wGraph.links);
    } else {
        graph.links = [];
        let aux = topicsSelected.includes("womanCheck") ? wGraph.links : graphOG.links;

        for (let i = 0; i < aux.length; i++) {
            if (aux[i].value > currentThreshValue) {
                let linkTopic = aux[i].topics;
                if(linkTopic === "") {
                    linkTopic = "Perdida";
                }
                let array = linkTopic.split(",");
                for (let j = 0; j < array.length; j++) {
                    if (topicsSelected.includes(array[j])) {
                        graph.links.push({ ...aux[i] });
                    }
                }
            }
        }
    }
}

//adjust threshold
function threshold(thresh) {
    currentThreshValue = thresh;
    if ($("#dropFilters").val().length === 0) {
        linksByValue(graphOG.links);
    } else {
        linksByTopic();
    }
    restart();
}

function resetSlider() {
    $("#slider").bootstrapSlider("refresh");
    currentThreshValue = 0;
}

function resetFilters() {
    $("#dropFilters").multiselect("deselectAll", false).multiselect("refresh");
}

//Checkbox
function checkbox(value, check) {
    if (value === "womanCheck") {
        if (!check) {//if woman not checked -> full graph
            graph = { ...graphOG };
            resetFilters();
        } else {//if woman checked -> women graph
            graph = { ...wGraph };
            resetFilters();
            $("#dropFilters").multiselect('select', value);
        }
        resetSlider();
    } else if (check === false && $("#dropFilters").val().length === 0) {
        graph = { ...graphOG }; //none selected
        linksByValue(graphOG.links);
    } else {
        linksByTopic();
    }
    restart();
}

//Prepares a small copy of the graph consisting only of women, there wasn't a copy before but Threshold wouldnt work (js references maaan)
function prepWomen() {
    wGraph = { ...graphOG };
    wGraph.nodes = [];
    wGraph.links = [];
    wGraph.nodes.push(graphOG.nodes[0]);
    for (let i = 1; i < graphOG.nodes.length; i++) {
        let aux = { ...graphOG.nodes[i] };
        if (aux.hasOwnProperty("woman")) {
            wGraph.nodes.push(aux);
            wGraph.nodes[wGraph.nodes.length - 1].id = wGraph.nodes.length;

            let link = { ...graphOG.links.find((l) => l.source === i + 1) };
            let link2 = { ...graphOG.links.find((l) => l.target === i + 1) };
            if (link.hasOwnProperty("source")) {
                link.source = wGraph.nodes.length;
                wGraph.links.push(link);
            }
            if (link2.hasOwnProperty("target")) {
                link2.target = wGraph.nodes.length;
                wGraph.links.push(link2);
            }
        }
    }
}

function changeTab(evt) {
    svg = d3.select("#d3");
    // Declare all letiables
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
    resetSlider();
    resetFilters();
}

function addGraph(resource, evt) {
    changeTab(evt);
    d3.json(resource, function (error, json) {
        if (!error) {
            graph = json;
            graphOG = JSON.parse(JSON.stringify(graph));
            prepWomen();
            createGraph(graph);
        }
    });
}