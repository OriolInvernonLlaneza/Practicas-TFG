function changeCSS(cssFile, cssLinkIndex) {

    let oldCSS = document.getElementsByTagName("link").item(cssLinkIndex);

    let newCSS = document.createElement("link");
    newCSS.setAttribute("rel", "stylesheet");
    newCSS.setAttribute("type", "text/css");
    newCSS.setAttribute("href", cssFile);

    document.getElementsByTagName("head").item(0).replaceChild(newCSS, oldCSS);
}