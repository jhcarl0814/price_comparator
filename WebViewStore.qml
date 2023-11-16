import QtQuick

import QtWebView

WebView {
    id: webview_store
    property string store
    property string search_string
    property var search_results
    url: webview_store.store === "countdown" ? "https://www.countdown.co.nz/shop/searchproducts?search=" + encodeURIComponent(webview_store.search_string) : webview_store.store === "paknsave" ? "https://www.paknsave.co.nz/shop/Search?q=" + encodeURIComponent(webview_store.search_string) : ""
    signal searchResultsReady(var search_results)
    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        onTriggered: () => //c
                     {
                         //                         webview_store.runJavaScript(
                         //                             "document.documentElement.outerHTML",
                         //                             function (result) {
                         //                                 console.log(result)
                         //                             })
                         webview_store.runJavaScript(webview_store.store === "countdown" ? `
                                                                                           JSON.stringify(
                                                                                           Array.from(document.querySelectorAll("cdx-card.ng-star-inserted"),(e)=>
                                                                                           {
                                                                                           var result={
                                                                                           store: "countdown",
                                                                                           product_title:(e.querySelector("h3")?.innerText ?? "").trim(),
                                                                                           product_subtitle:"",
                                                                                           product_rho:(e.querySelector(".cupPrice")?.innerText ?? e.querySelector(".price-single-unit-text")?.innerText ?? "").trim(),
                                                                                           product_picture:e.querySelector("img").src,
                                                                                           product_url:e.querySelector("a").href.replace("w=200&h=200","w=50&h=50"),
                                                                                           };
                                                                                           if(e.querySelector(".size")===null)
                                                                                           {
                                                                                           result["product_price"]=(e.querySelector("h3>em")?.innerText ?? "").trim()+"."+(e.querySelector("h3>span")?.childNodes[0].data ?? "").trim();
                                                                                           result["product_unit"]=(e.querySelector("h3>span")?.childNodes[2].data ?? "").trim();
                                                                                           }
                                                                                           else
                                                                                           {
                                                                                           result["product_price"]=(e.querySelector("h3>em")?.innerText ?? "").trim()+"."+(e.querySelector("h3>span")?.innerText ?? "").trim();
                                                                                           result["product_unit"]=(e.querySelector(".size")?.innerText ?? "").trim();
                                                                                           }
                                                                                           return result;
                                                                                           }).slice(0,5)
                                                                                           )
                                                                                           ` : webview_store.store === "paknsave" ? `
                                                                                                                                    JSON.stringify(
                                                                                                                                    Array.from(document.querySelectorAll("[data-testid^=\\\"product-\\\"]:not([data-testid=\\\"product-title\\\"]):not([data-testid=\\\"product-subtitle\\\"])"),(e)=>
                                                                                                                                    {
                                                                                                                                    return {
                                                                                                                                    store: "paknsave",
                                                                                                                                    product_title:(e.querySelector("[data-testid=\\\"product-title\\\"]")?.innerText ?? "").trim(),
                                                                                                                                    product_subtitle:(e.querySelector("[data-testid=\\\"product-subtitle\\\"]")?.innerText ?? "").trim(),
                                                                                                                                    product_price:(e.querySelector("[data-testid=\\\"price-dollars\\\"]")?.innerText ?? "").trim()+"."+(e.querySelector("[data-testid=\\\"price-cents\\\"]")?.innerText ?? "").trim(),
                                                                                                                                    product_unit:(e.querySelector("[data-testid=\\\"price-per\\\"]")?.innerText ?? "").trim(),
                                                                                                                                    product_rho:(e.querySelector("p:not([data-testid])")?.innerText ?? "").trim(),
                                                                                                                                    product_picture:e.querySelector("img").src,
                                                                                                                                    product_url:e.querySelector("a").href.replace("200x200","100x100"),
                                                                                                                                    };
                                                                                                                                    }).slice(0,5)
                                                                                                                                    )
                                                                                                                                    ` : "", function (result) {
    //    console.log(JSON.parse(result).length)
    //    console.log(JSON.stringify(JSON.parse(result)))
    webview_store.search_results = JSON.parse(result)
    if (JSON.parse(result).length > 0) {
        timer.running = false
        webview_store.searchResultsReady(webview_store.search_results)
        webview_store.destroy()
    }
})
                     }
    }
}
