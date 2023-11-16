#include <QApplication>
#include <QQmlApplicationEngine>
//#include <QSslSocket>
#include <QQmlContext>
#include <QtWebView>

int main(int argc, char *argv[])
{
    //    qDebug() << "Device supports OpenSSL: " << QSslSocket::supportsSsl();

    QtWebView::initialize();
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QFont const fixedFont = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    engine.rootContext()->setContextProperty("fixedFont", fixedFont);
    engine.rootContext()->setContextProperty("search_string_default", R"([
    {
        "name": "potato",
        "countdown": ["potato"],
        "paknsave": ["potato"]
    },
    {
        "name": "tomato",
        "countdown": ["tomato"],
        "paknsave": ["tomato"]
    },
    {
        "name": "egg",
        "countdown": ["egg"],
        "paknsave": ["egg"]
    }
]
)");
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection
    );
    engine.loadFromModule("price_comparator", "Main");

    qDebug() << engine.offlineStoragePath();

    return app.exec();
}
