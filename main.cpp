#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "cpp/GoalModel.h"
#include "cpp/InsuranceCalculator.h"
#include "cpp/RetirementAssetModel.h"
#include "cpp/RetirementCalculator.h"
#include "cpp/SipFilterProxy.h"
#include "cpp/UnifiedSipModel.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

    InsuranceCalculator *insuranceCalc = new InsuranceCalculator(&app);
    engine.rootContext()->setContextProperty("insuranceCalc", insuranceCalc);

    RetirementCalculator *retirementCalc = new RetirementCalculator(&app);
    engine.rootContext()->setContextProperty("retirementCalc", retirementCalc);

    RetirementAssetModel *retirementAssetModel = new RetirementAssetModel(&app);
    engine.rootContext()->setContextProperty("retirementAssetModel", retirementAssetModel);

    UnifiedSipModel *unifiedSipModel = new UnifiedSipModel(&app);
    GoalModel *goalModel = new GoalModel(&app);

    // Give GoalModel the pointer to the SIP data
    goalModel->setSipModel(unifiedSipModel);
    // Connect the signal so GoalModel refreshes whenever SIP data changes
    QObject::connect(unifiedSipModel, &UnifiedSipModel::sipUpdated, goalModel, &GoalModel::handleSipUpdate);

    engine.rootContext()->setContextProperty("unifiedSipModel", unifiedSipModel);
    engine.rootContext()->setContextProperty("goalModel", goalModel);

    // Arguments: (Plugin Name, Major Version, Minor Version, QML Type Name)
    qmlRegisterType<SipFilterProxy>("FinancialComponents", 1, 0, "SipFilterProxy");

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("kanjoos", "Main");

    return QCoreApplication::exec();
}
