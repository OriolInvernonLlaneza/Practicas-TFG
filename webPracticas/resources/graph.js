//color scheme
var colors = d3.scaleOrdinal(d3.schemeCategory10);

//Create svg
var svg = d3.select("svg"),
    width = +svg.attr("width"),
    height = +svg.attr("height"),
    node,
    link;

//Create force layout
var simulation = d3.forceSimulation()
    .force("link", d3.forceLink().id(function (d) { return d.id; }).distance(100).strength(1))
    .force("charge", d3.forceManyBody())
    .force("center", d3.forceCenter(width / 2, height / 2));

//force functions
function dragstarted(d) {
    if (!d3.event.active) {
        simulation.alphaTarget(0.3).restart()
    }
    d.fx = d.x;
    d.fy = d.y;
}

function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
}

function dragended(d) {
    if (!d3.event.active) {
        simulation.alphaTarget(0);
    }
    d.fx = undefined;
    d.fy = undefined;
}

//Read from json
d3.json("resources/jovellanos.json", function (error, graph) {
    if (error) {
        throw error;
    }
    update(graph.links, graph.nodes);
});

//
function update(links, nodes) {
    //create link line, width increases with number of letters
    link = svg.selectAll(".link")
        .data(links)
        .enter()
        .append("line")
        .attr("class", "link")
        .attr('stroke-width', function (d) { return d.value; });

    link.append("title")
        .text(function (d) { return d.mood; });

    //path obj
    edgepaths = svg.selectAll(".edgepath")
        .data(links)
        .enter()
        .append("path")
        .attr("class", "edgepath")
        .attr("id", function (d, i) { return "edgepath" + i; })
        .attr("fill-opacity", 0)
        .attr("stroke-opacity", 0)
        .style("pointer-events", "none");

    //link label obj
    edgelabels = svg.selectAll(".edgelabel")
        .data(links)
        .enter()
        .append("text")
        .style("pointer-events", "none")
        .attr("class", "edgelabel")
        .attr("id", function (d, i) { return 'edgelabel' + i })
        .attr("font-size", 15)
        .attr("fill", "#000");

    //link label text
    edgelabels.append('textPath')
        .attr('xlink:href', function (d, i) { return '#edgepath' + i })
        .style("text-anchor", "middle")
        .style("pointer-events", "none")
        .attr("startOffset", "50%")
        .text(function (d) { return d.mood });

    //node obj
    node = svg.selectAll(".node")
        .data(nodes)
        .enter()
        .append("g")
        .attr("class", "node")
        .call(d3.drag()
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended)
        );

    //node drawing
    node.append("circle")
        .attr("r", 10)
        .style("fill", function (d, i) { return colors(i); });

    //node title
    node.append("title")
        .text(function (d) { return d.id; });

    //node name
    node.append("text")
        .attr("dy", -10)
        .text(function (d) { return d.name; });

    simulation
        .nodes(nodes)
        .on("tick", ticked);

    simulation.force("link")
        .links(links);
}

//tick behaviour
function ticked() {
    link
        .attr("x1", function (d) { return d.source.x; })
        .attr("y1", function (d) { return d.source.y; })
        .attr("x2", function (d) { return d.target.x; })
        .attr("y2", function (d) { return d.target.y; });

    node
        .attr("transform", function (d) { return "translate(" + d.x + ", " + d.y + ")"; });

    edgepaths.attr("d", function (d) {
        return "M " + d.source.x + " " + d.source.y + " L " + d.target.x + " " + d.target.y;
    });

    edgelabels.attr("transform", function (d) {
        if (d.target.x < d.source.x) {
            var bbox = this.getBBox();

            rx = bbox.x + bbox.width / 2;
            ry = bbox.y + bbox.height / 2;
            return "rotate(180 " + rx + " " + ry + ")";
        }
        else {
            return "rotate(0)";
        }
    });
}