#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "cpp/InsuranceCalculator.h"
#include "cpp/RetirementAssetModel.h"
#include "cpp/RetirementCalculator.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

    InsuranceCalculator insuranceCalc;
    engine.rootContext()->setContextProperty("insuranceCalc", &insuranceCalc);

    RetirementCalculator retirementCalc;
    RetirementAssetModel retirementAssetModel;

    engine.rootContext()->setContextProperty("retirementCalc", &retirementCalc);
    engine.rootContext()->setContextProperty("retirementAssetModel", &retirementAssetModel);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("kanjoos", "Main");

    return QCoreApplication::exec();
}
