var wikiImage;
var lastWikiPage;
var content;

function callWikipediaAPI(wikiPage) {
  if(wikiPage === lastWikiPage) { // using three equals to avoid errors if json.link is blank
    return; // if the selected node is the same as last time -> do nothing
  }

  lastWikiPage = wikiPage;
  $("#wiki").empty(); //delete previous content

  // http://www.mediawiki.org/wiki/API:Parsing_wikitext#parse
  $.getJSON("http://es.wikipedia.org/w/api.php?action=parse&format=json&callback=?",
    {
      page: wikiPage,
      prop: "text|images",
    }, wikiImage);
  $.getJSON("https://es.wikipedia.org/w/api.php?format=json&formatversion=2&action=query&prop=extracts&exintro=&explaintext=",
    {// new API json format, easier to handle
      redirect: 1,
      titles: wikiPage,
      origin: "*" // required by CORS, API includes allow credentials header
    }, function (data) {
      var raw = data.query.pages[0].extract; // take the content
      content = raw.replace(/\[\d+\]/g, " "); // replace references
    });
}

wikiImage = function (data) {
  var readData = $("<div>" + data.parse.text["*"] + "</div>");
  // handle redirects
  var redirect = readData.find('li:contains("REDIRECT") a').text();
  if (redirect !== "") {
    callWikipediaAPI(redirect);
    return;
  }

  var box = readData.find(".infobox"); // right column wikipedia box
  var imageURL = null;
  // Check if page has images
  if (data.parse.images.length >= 1) { //get the one on the box
    imageURL = box.find("img").first().attr("src");
  }

  $("#wiki").append('<div><img src="' + imageURL + '"/>');
  $("#wiki").append("<p>" + content + "</p>");
};