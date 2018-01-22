var svg = d3.select("svg"),
    width = +svg.attr("width"),
    height = +svg.attr("height");

var force = d3.forceSimulation()
    .force("link", d3.forceLink().id(function (d) { return d.name; }))
    .force("charge", d3.forceManyBody())
    .force("center", d3.forceCenter(width / 2, height / 2));

d3.json("resources/jovellanos.json", function (error, json) {
    if (error) throw error;

    force
        .nodes(json.nodes)
        .on("tick", ticked);

    force.force("link")
        .links(json.links);

    var link = svg.append("g")
        .attr("class", "links")
        .selectAll("line")
        .data(json.links)
        .enter().append("line")
        .attr("stroke-width", function (d) { return d.value; });

    /*var node = svg.append("g")
        .attr("class", "nodes")
        .selectAll("node")
        .data(json.nodes)
        .call(d3.drag()
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));

    node.append("circle")
        .attr("r", 5);

    node.append("text")
        .attr("dx", 12)
        .attr("dy", ".35em")
        .text(function (d) { return d.name });*/
    var node = svg.selectAll(".node")
        .data(json.nodes)
        .enter().append("g")
        .attr("class", "node")
        .call(d3.drag()
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));

    node.append("circle")
        .attr("r", 4.5);

    node.append("text")
        .attr("dx", 12)
        .attr("dy", ".35em")
        .text(function (d) { return d.name });

    function ticked() {
        link
            .attr("x1", function (d) { return d.source.x; })
            .attr("y1", function (d) { return d.source.y; })
            .attr("x2", function (d) { return d.target.x; })
            .attr("y2", function (d) { return d.target.y; });

        node
            .attr("cx", function (d) { return d.x; })
            .attr("cy", function (d) { return d.y; });
    }
});

function dragstarted(d) {
    if (!d3.event.active) force.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
}

function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
}

function dragended(d) {
    if (!d3.event.active) force.alphaTarget(0);
    d.fx = null;
    d.fy = null;
}