import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.LocalStorage
import QtQuick.Controls
import QtCharts

Window {

    //    width: 640
    //    height: 480
    visible: true
    //    title: qsTr("Hello World")
    readonly property var db: LocalStorage.openDatabaseSync("db_price_comparator", "0.0", "database of price_comparator", 1000000)

    ButtonGroup {
        id: btn_page_group
    }
    ListModel {
        id: model_search_history
    }
    property var current_searches: []
    property var current_search_results: []
    ListModel {
        id: model_search_results
    }

    StackLayout {
        id: stacklayout_hider
        currentIndex: 0
        anchors.fill: parent
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            RowLayout {
                Layout.fillWidth: true
                Button {
                    id: btn_page_searches
                    checkable: true
                    checked: true
                    ButtonGroup.group: btn_page_group
                    text: "searches"
                }
                Button {
                    id: btn_page_search_history
                    checkable: true
                    checked: true
                    ButtonGroup.group: btn_page_group
                    text: "search_history"
                }
                Button {
                    id: btn_page_results
                    checkable: true
                    checked: false
                    ButtonGroup.group: btn_page_group
                    text: "results"
                }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: [btn_page_searches, btn_page_search_history, btn_page_results].indexOf(btn_page_group.checkedButton)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    TextEdit {
                        id: textedit_search
                        font: fixedFont
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        textFormat: Text.PlainText
                    }
                    Button {
                        id: button_search
                        text: {
                            try {
                                JSON.parse(textedit_search.text)
                            } catch (e) {
                                return e.message
                            }
                            return "search"
                        }
                        enabled: {
                            try {
                                JSON.parse(textedit_search.text)
                            } catch (e) {
                                return false
                            }
                            return true
                        }
                        onClicked: () => {
                                       db.transaction(function (tx) {
                                           var rs = tx.executeSql('SELECT * FROM searches_history')
                                           if (rs.rows.length === 0 || textedit_search.text !== rs.rows.item(rs.rows.length - 1).search) {
                                               model_search_history.insert(0, {
                                                                               "search_string": textedit_search.text
                                                                           })
                                               tx.executeSql("insert into searches_history values (?)", [textedit_search.text])
                                               initiate_search()
                                           }
                                       })
                                   }
                    }
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cacheBuffer: 10000
                    boundsBehavior: Flickable.StopAtBounds
                    boundsMovement: Flickable.StopAtBounds
                    model: model_search_history
                    delegate: TextEdit {
                        width: ListView.view.width
                        required property var model
                        text: model.search_string
                        font: fixedFont
                        readOnly: true
                        selectByMouse: true
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        textFormat: Text.PlainText
                    }
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cacheBuffer: 10000
                    boundsBehavior: Flickable.StopAtBounds
                    boundsMovement: Flickable.StopAtBounds
                    model: model_search_results
                    delegate: Item {
                        id: delegate_search_result
                        //                        required property int index
                        required property string name
                        required property var product_data
                        required property real product_price_max
                        required property string text_search_result_text
                        width: delegate_search_result.ListView.view.width
                        height: vlayout_search_result.implicitHeight
                        ColumnLayout {
                            id: vlayout_search_result
                            ChartView {
                                title: name
                                legend.alignment: Qt.AlignBottom
                                antialiasing: true
                                Layout.preferredWidth: delegate_search_result.ListView.view.width
                                Layout.preferredHeight: delegate_search_result.ListView.view.width

                                BarSeries {
                                    id: series_search_result
                                    axisX: BarCategoryAxis {
                                        categories: [""]
                                    }
                                    axisY: ValueAxis {
                                        id: yaxis_search_result
                                        min: 0
                                        max: product_price_max
                                    }
                                }
                            }
                            Text /*TextEdit*/ {
                                id: text_search_result
                                Layout.preferredWidth: delegate_search_result.ListView.view.width
                                //                                readOnly: true
                                //                                selectByMouse: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                textFormat: Text.RichText
                                onLinkActivated: link => {
                                                     Qt.openUrlExternally(link)
                                                 }
                                text: text_search_result_text
                            }
                        }
                        onProduct_dataChanged: {
                            console.log("onProduct_dataChanged" /*, index*/
                                        , product_data)
                            series_search_result.clear()
                            for (var i = 0; i !== product_data.count; ++i) {
                                series_search_result.append(product_data.get(i).product_title, [product_data.get(i).product_price])
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: webview_store_list
        }
    }
    function initiate_search() {
        for (var i = webview_store_list.children.length - 1; i !== -1; --i) {
            webview_store_list.children[i].destroy()
        }
        current_search_results = []
        model_search_results.clear()

        var WebViewStore_component = Qt.createComponent("WebViewStore.qml")
        current_searches = JSON.parse(textedit_search.text)
        for (var search of current_searches) {
            //console.log("search", JSON.stringify(search))
            for (var store of ["countdown", "paknsave"]) {
                for (var search_string of search[store] ?? []) {
                    var webview_store = WebViewStore_component.createObject(webview_store_list, {
                                                                                "store": store,
                                                                                "search_string": search_string
                                                                            })
                    webview_store.parent = webview_store_list
                    webview_store.searchResultsReady.connect(process_search_results)
                }
            }

            current_search_results.push({
                                            "name": search.name,
                                            "product_price_max": 0.0,
                                            "text_search_result_text": "",
                                            "product_data": []
                                        })
            model_search_results.append({
                                            "name": search.name,
                                            "product_price_max": 0.0,
                                            "text_search_result_text": "",
                                            "product_data": []
                                        })
        }
        //console.log(current_search_results.length)
        //console.log(model_search_results.count)
        stacklayout_hider.currentIndex = 1
        stacklayout_hider.currentIndex = 0
    }

    function process_search_results(search_results) {
        for (var search_result of search_results) {
            //console.log("search_result", JSON.stringify(search_result))
            db.transaction(function (tx) {
                var rs = tx.executeSql('SELECT max(scrape_time) as scrape_time_max FROM search_results where store=? AND product_title = ?', [search_result.store, search_result.product_title])
                if (rs.rows.item(0).scrape_time_max === null || (new Date() - new Date(rs.rows.item(0).scrape_time_max.replace(/-/g, '/') + ".000Z")) / 1000 / 3600 > 1) {
                    tx.executeSql("insert into search_results values (?,?,?,?,?,?,?,?,?)", [search_result.store, search_result.product_title, search_result.product_subtitle, search_result.product_price, search_result.product_unit, search_result.product_rho, search_result.product_picture, search_result.product_url, new Date().toISOString().slice(0, 19).replace('T', ' ')])
                }
            })
            for (var current_search_result_index = 0; current_search_result_index !== current_search_results.length; ++current_search_result_index) {
                if ((current_searches[current_search_result_index][search_result.store] ?? []).some(function (search_string) {
                    return search_result.product_title.toUpperCase().includes(search_string.toUpperCase())
                })) {
                    if (!current_search_results[current_search_result_index].product_data.some(function (product_datum) {
                        return product_datum.store === search_result.store && product_datum.product_title === search_result.product_title
                    })) {
                        current_search_results[current_search_result_index].product_data.push(search_result)
                        current_search_results[current_search_result_index].product_data.sort(function (lhs, rhs) {
                            return parseFloat(lhs.product_price) - parseFloat(rhs.product_price)
                        })

                        var product_data = current_search_results[current_search_result_index].product_data
                        var product_price_max = 1
                        var text_search_result_text = ""
                        text_search_result_text += `<table style="border-collapse:collapse;border-width:1px;border-style:solid;border-color:black;"><tbody>`
                        for (var i = 0; i !== product_data.length; ++i) {
                            product_price_max = Math.max(product_price_max, product_data[i].product_price)
                            text_search_result_text += `<tr>
                            <td>
                            <img src="${product_data[i].product_picture}" width="60" height="60">
                            </td>
                            <td style="padding:5px;">
                            <p style="margin-top:1px;margin-bottom:1px;">[${product_data[i].store}]&nbsp;${product_data[i].product_title}${product_data[i].product_subtitle.length === 0 ? "" : ` <span style="color:darkgrey;">(</span>${product_data[i].product_subtitle}<span style="color:darkgrey;">)</span>`}</p>
                            <p style="margin-top:0px;margin-bottom:0px;">$${product_data[i].product_price}${product_data[i].product_unit.length === 0 ? "" : ` <span style="color:blue;">/</span> ${product_data[i].product_unit}`}${product_data[i].product_rho.length === 0 ? "" : ` <span style="color:blue;">==></span> ${product_data[i].product_rho}`}&nbsp;&nbsp;&nbsp;<a href="${product_data[i].product_url}" style="text-decoration:none;">🔗</a></p>
                            </td>
                            </tr>`
                        }
                        text_search_result_text += "</tbody></table>"

                        current_search_results[current_search_result_index].product_price_max = product_price_max
                        current_search_results[current_search_result_index].text_search_result_text = text_search_result_text

                        console.log("current_search_result_index", current_search_result_index)
                        console.log("product_data", JSON.stringify(current_search_results[current_search_result_index].product_data))
                        model_search_results.set(current_search_result_index, current_search_results[current_search_result_index])
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        db.transaction(function (tx) {
            //            tx.executeSql('DROP TABLE IF EXISTS searches_history')
            //            tx.executeSql('DROP TABLE IF EXISTS search_results')
            tx.executeSql('CREATE TABLE IF NOT EXISTS searches_history(search_string TEXT)')
            tx.executeSql('CREATE TABLE IF NOT EXISTS search_results(store TEXT,product_title TEXT, product_subtitle TEXT, product_price TEXT, product_unit TEXT, product_rho TEXT, product_picture TEXT, product_url TEXT, scrape_time DATETIME)')
        })
        db.transaction(function (tx) {
            var rs = tx.executeSql('SELECT * FROM searches_history')
            for (var i = 0; i !== rs.rows.length; ++i) {
                model_search_history.insert(0, {
                                                "search_string": rs.rows.item(rs.rows.length - 1).search_string
                                            })
            }
            if (rs.rows.length !== 0) {
                textedit_search.text = rs.rows.item(rs.rows.length - 1).search_string
            } else {
                textedit_search.text = search_string_default
            }
        })
        initiate_search()
    }
}
