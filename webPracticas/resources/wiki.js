var wikiImage;

function callWikipediaAPI(wikiPage) {
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
      var content = data.query.pages[0].extract;
      content = content.replace(/^\d+$/, " ");
      $("#wiki").append("<p>" + content + "</p>)");
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
};