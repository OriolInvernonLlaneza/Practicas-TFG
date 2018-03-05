let linkSom;
let nodeSom;
let labelSom;
let somozaSVG;
let somozaSim;
let somRest;

function selectName(n) {
    return n.nombre + " " + n.apellidos;
}

/*function searchSomoza(nodeList) {
    // jquery search and autocomplete
    let optArray = [];
    for (let i = 0; i < nodeList.length - 1; i++) {
        let str = selectName(nodeList[i]);
        if (str !== "") {
            optArray.push(str); //all node names
        }
    }
    optArray = optArray.sort();
    $(function () {
        $("#search").autocomplete({
            source: optArray
        });
    });
}*/

function somozaGraph(ngraph) {
    //searchSomoza(ngraph.nodes);

    somozaSVG = d3.select("#somoza");

    somozaSVG.attr("width", somozaSVG.node().parentNode.clientWidth)
        .attr("height", 500);

    // take size from somozaSVG
    let width = +somozaSVG.attr("width"),
        height = +somozaSVG.attr("height");

    // color scheme
    let fill = d3.scaleOrdinal(d3.schemeCategory20);

    // remove any previous graphs
    somozaSVG.selectAll(".g-main").remove();

    // create main frame
    let somozaMain = somozaSVG.append("g")
        .classed("g-main", true);

    // append draw    
    let somozaDraw = somozaMain.append("g");

    // force functions
    function dragstarted(d) {
        if (!d3.event.active) { somozaSim.alphaTarget(0.3).restart(); }

        if (!d.selected && !shiftKeySom) {
            // if this node isn"t selected, then we have to unselect every other node
            nodeSom.classed("selected", function (p) {
                return p.selected = p.previouslySelected = false;
            });
        }

        d3.select(this).classed("selected", function (p) {
            d.previouslySelected = d.selected;
            return d.selected = true; // selection
        });

        nodeSom.filter(function (d) { return d.selected; })
            .each(function (d) { // move the selected
                d.fx = d.x;
                d.fy = d.y;
            });

    }

    function dragged(d) {
        nodeSom.filter(function (d) { return d.selected; })
            .each(function (d) {
                d.fx += d3.event.dx;
                d.fy += d3.event.dy;
            });
    }

    function dragended(d) {
        if (!d3.event.active) { somozaSim.alphaTarget(0); }
        d.fx = null;
        d.fy = null;
        nodeSom.filter(function (d) { return d.selected; })
            .each(function (d) {
                d.fx = null;
                d.fy = null;
            });
    }

    // zoom list
    function zoomed() {
        somozaDraw.attr("transform", d3.event.transform); // transforms drawing with zoom event
    }

    let zoom = d3.zoom() // Creates new zoom behavior (obj and func) https://github.com/d3/d3-zoom
        .on("zoom", zoomed); // add listener

    somozaMain.call(zoom).on("dblclick.zoom", null); //disable zoom on doubleclick


    ngraph.nodes.unshift({nombre:"G.M. Jovellanos", id: 1});
    let links = [];
    // create links
    if (!("links" in ngraph)) {
        for(let i = 1; i < ngraph.nodes.length; i++) {
            ngraph.nodes[i].id = i+1;
            let link = {source:ngraph.nodes[0], target:ngraph.nodes[i], relation: ngraph.nodes.relationJove};
            links.push(link);
        }
    }

    // the brush needs to go before the nodes so that it doesn"t
    // get called when the mouse is over a node
    let gBrushHolder = somozaDraw.append("g");
    let gBrush = null;

    //add curved links, stroke <= number of letters
    linkSom = somozaDraw.selectAll(".link").data(links).enter()
        .append("path")
        .attr("id", function (d, i) { return "link" + i; })
        .attr("source", function (d) {
            return d.source;
        }).attr("target", function (d) {
            return d.target;
        }).attr("class", "link")
        .attr("fill-opacity", 0)
        .attr("stroke-width", function (d) { return 1; })
        .attr("stroke", function (d) { return "#999"; })
        .on("mouseover", function (d, i) {
            d3.select(this).style("stroke", "red");
        }).on("mouseout", function (d, i) {
            d3.select(this).style("stroke", function (d) { return "#999"; });
        });

    //add nodes
    nodeSom = somozaDraw.append("g")
        .attr("class", "node")
        .selectAll("circle")
        .data(ngraph.nodes)
        .enter().append("circle")
        .attr("r", 5)
        .attr("fill", function (d) {
            return "GoldenRod";
        })
        .call(d3.drag() // drag functions on node
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));

    // tooltip titles
    nodeSom.append("title")
        .text(function (d) { return selectName(d); });

    //node labelSom
    labelSom = somozaDraw.append("g")
        .attr("class", "labelSom")
        .selectAll("labelSom")
        .data(ngraph.nodes)
        .enter().append("text")
        .style("pointer-events", "none")
        .text(function (d) {
            return d.nombre;
        })
        .style("text-anchor", "middle")
        .style("fill", "#000")
        .style("font-family", "Arial")
        .style("font-size", 12);

    somozaSim = d3.forceSimulation() // create and start somozaSim
        .force("link", d3.forceLink().id(function (d) { return d.id; }).distance(100).strength(0.5))
        .force("charge", d3.forceManyBody())
        .force("collide", d3.forceCollide().radius(18).iterations(5))
        .force("center", d3.forceCenter(width / 2, height / 2));

    function linkArc(d) {
        let dx = d.target.x - d.source.x,
            dy = d.target.y - d.source.y,
            dr = Math.sqrt(dx * dx + dy * dy);
        return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " +
            d.target.x + "," + d.target.y;
    }

    function ticked() {
        // update node, labelSom and path positions
        // at every step of the somozaSim

        nodeSom.attr("cx", function (d) { return d.x; })
            .attr("cy", function (d) { return d.y; });

        labelSom.attr("x", function (d) { return d.x; })
            .attr("y", function (d) { return d.y - 5; });

        linkSom.attr("d", linkArc);
    }

    somozaSim
        .nodes(ngraph.nodes) // add nodes to somozaSim
        .on("tick", ticked);

    somozaSim.force("link") // add links to somozaSim
        .links(links);

    //Toggle stores whether the highlighting is on
    let toggle = false;

    //Create an array logging what is connected to what
    let linkedByIndex = {};
    for (let j = 0; j < ngraph.nodes.length; j++) {
        linkedByIndex[j + "," + j] = 1; // nodes are connected to themselves
    }

    links.forEach(function (d) {
        linkedByIndex[d.source.index + "," + d.target.index] = 1; // link(a,b) -> connected(a,b)
    });

    //This function looks up whether a pair are neighbours
    function isNeighbouring(a, b) {
        return linkedByIndex[a.index + "," + b.index];
    }

    function connectedNodes() {
        if (!toggle) {
            //Reduce the opacity of all the non-neighbours
            let d = d3.select(this).node().__data__;

            nodeSom.style("opacity", function (o) {
                return isNeighbouring(d, o) | isNeighbouring(o, d) ? 1 : 0.1;
            });

            linkSom.style("opacity", function (o) {
                return d.index === o.source.index | d.index === o.target.index ? 1 : 0.1;
            });

            toggle = true;
        } else {
            //Restore opacity
            nodeSom.style("opacity", 1);
            linkSom.style("opacity", 1);
            toggle = false;
        }
    }
    nodeSom.on("dblclick", connectedNodes); // dblclick listener (neigh)

    if (!somRest) {
        while (somozaSim.alpha() > 0.1) {
            somozaSim.tick();
        }
    }
    somRest = false;
    return ngraph;
}

//search function
/*function searchNode() {
    //find the node
    let selectedVal = document.getElementById("search").value;
    if (selectedVal !== "" && selectedVal !== "none") {
        let selected = nodeSom.filter(function (d, i) {
            return d.fname !== selectedVal;
        });
        //Reduce the opacity of the non searched
        selected.style("opacity", 0);
        linkSom.style("opacity", 0);
        d3.selectAll("circle, .link").transition()
            .duration(5000) // restore opacity
            .style("opacity", 1);
    }
    document.getElementById("search").value = "";
}*/

function addSomozaGraph(resource) {
    d3.json(resource, function (error, json) {
        if (!error) {
            somozaGraph(json);
        }
    });
}