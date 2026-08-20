#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "cpp/GoalModel.h"
#include "cpp/InsuranceCalculator.h"
#include "cpp/RetirementAssetModel.h"
#include "cpp/RetirementCalculator.h"
#include "cpp/SipFilterProxy.h"
#include "cpp/SipModel.h"
#include "cpp/PortfolioModel.h"

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

    // Keep the calculator's accumulated totals in sync with the asset model.
    // Batched into one push per assetsChanged so total/liquid/lockedRatio are
    // never briefly inconsistent with each other mid-recalculation.
    auto pushAccumulated = [retirementCalc, retirementAssetModel]() {
        retirementCalc->setAccumulated(retirementAssetModel->totalValue(),
                                        retirementAssetModel->liquidValue(),
                                        retirementAssetModel->lockedRatio());
    };
    QObject::connect(retirementAssetModel, &RetirementAssetModel::assetsChanged,
                      retirementCalc, pushAccumulated);
    pushAccumulated(); // seed initial state (ctor default would otherwise sit at 0 until the page loads)

    SipModel *sipModel = new SipModel(&app);
    GoalModel *goalModel = new GoalModel(&app);

    // Give GoalModel the pointer to the SIP data
    goalModel->setSipModel(sipModel);
    // Connect the signal so GoalModel refreshes whenever SIP data changes
    QObject::connect(sipModel, &SipModel::sipUpdated, goalModel, &GoalModel::handleSipUpdate);

    PortfolioModel *portfolioModel = new PortfolioModel(&app);
    // Link it to GoalModel so goals can see their funded amounts
    goalModel->setPortfolioModel(portfolioModel);
    // Connect signal for refresh
    QObject::connect(portfolioModel, &PortfolioModel::portfolioUpdated, goalModel, &GoalModel::handleSipUpdate);

    engine.rootContext()->setContextProperty("sipModel", sipModel);
    engine.rootContext()->setContextProperty("goalModel", goalModel);
    engine.rootContext()->setContextProperty("portfolioModel", portfolioModel);

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
