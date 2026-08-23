#ifndef INSURANCECALCULATOR_H
#define INSURANCECALCULATOR_H

#include <QObject>
#include <QString>

class InsuranceCalculator : public QObject {
    Q_OBJECT
    // Calculator Inputs
    Q_PROPERTY(bool hasDependents READ hasDependents WRITE setHasDependents NOTIFY calculatorChanged)
    Q_PROPERTY(double annualExpenses READ annualExpenses WRITE setAnnualExpenses NOTIFY calculatorChanged)
    Q_PROPERTY(double totalLoans READ totalLoans WRITE setTotalLoans NOTIFY calculatorChanged)
    Q_PROPERTY(double futureMilestones READ futureMilestones WRITE setFutureMilestones NOTIFY calculatorChanged)
    Q_PROPERTY(double currentLiquidAssets READ currentLiquidAssets WRITE setCurrentLiquidAssets NOTIFY calculatorChanged)
    Q_PROPERTY(int multiplier READ multiplier WRITE setMultiplier NOTIFY calculatorChanged) // life multiplier
    Q_PROPERTY(double healthMultiplier READ healthMultiplier WRITE setHealthMultiplier NOTIFY calculatorChanged)

    // Life cover outputs
    Q_PROPERTY(double recommendedLifeCover READ recommendedLifeCover NOTIFY resultsChanged)
    Q_PROPERTY(QString lifeCoverDirective READ lifeCoverDirective NOTIFY resultsChanged)
    Q_PROPERTY(int lifeVerdictLevel READ lifeVerdictLevel NOTIFY resultsChanged)

    // Health cover outputs (default 12.5x annual expenses = midpoint of 10-15x rule)
    Q_PROPERTY(double recommendedHealthCover READ recommendedHealthCover NOTIFY resultsChanged)
    Q_PROPERTY(bool isHealthCoverAdequate READ isHealthCoverAdequate NOTIFY resultsChanged)
    Q_PROPERTY(int healthVerdictLevel READ healthVerdictLevel NOTIFY resultsChanged)

public:
    explicit InsuranceCalculator(QObject *parent = nullptr) : QObject(parent),
        m_hasDependents(true), m_annualExpenses(600000), m_totalLoans(0),
        m_futureMilestones(0), m_currentLiquidAssets(0), m_multiplier(15), m_healthMultiplier(12.5) {
        calculate();
    }

    // Getters
    bool hasDependents() const { return m_hasDependents; }
    double annualExpenses() const { return m_annualExpenses; }
    double totalLoans() const { return m_totalLoans; }
    double futureMilestones() const { return m_futureMilestones; }
    double currentLiquidAssets() const { return m_currentLiquidAssets; }
    int multiplier() const { return m_multiplier; }
    double healthMultiplier() const { return m_healthMultiplier; }
    double recommendedLifeCover() const { return m_recommendedLifeCover; }
    QString lifeCoverDirective() const { return m_lifeCoverDirective; }
    int lifeVerdictLevel() const { return m_lifeVerdictLevel; }
    double recommendedHealthCover() const { return m_recommendedHealthCover; }
    bool isHealthCoverAdequate() const { return m_isHealthCoverAdequate; }
    int healthVerdictLevel() const { return m_healthVerdictLevel; }

    // Called from QML when global monthly expenses change
    Q_INVOKABLE void setHealthCover(double currentCover) {
        m_currentHealthCover = currentCover;
        calculate();
    }

public slots:
    void setHasDependents(bool v) { if(m_hasDependents != v) { m_hasDependents = v; calculate(); emit calculatorChanged(); } }
    void setAnnualExpenses(double v) { if(m_annualExpenses != v) { m_annualExpenses = v; calculate(); emit calculatorChanged(); } }
    void setTotalLoans(double v) { if(m_totalLoans != v) { m_totalLoans = v; calculate(); emit calculatorChanged(); } }
    void setFutureMilestones(double v) { if(m_futureMilestones != v) { m_futureMilestones = v; calculate(); emit calculatorChanged(); } }
    void setCurrentLiquidAssets(double v) { if(m_currentLiquidAssets != v) { m_currentLiquidAssets = v; calculate(); emit calculatorChanged(); } }
    void setMultiplier(int v) { if(m_multiplier != v) { m_multiplier = v; calculate(); emit calculatorChanged(); } }
    void setHealthMultiplier(double v) { if(m_healthMultiplier != v) { m_healthMultiplier = v; calculate(); emit calculatorChanged(); } }

signals:
    void calculatorChanged();
    void resultsChanged();

private:
    void calculate();
    bool m_hasDependents;
    double m_annualExpenses, m_totalLoans, m_futureMilestones, m_currentLiquidAssets;
    int m_multiplier;
    double m_healthMultiplier;
    double m_recommendedLifeCover = 0;
    QString m_lifeCoverDirective;
    int m_lifeVerdictLevel = 0; // 0=noData 1=critical 2=warn 3=ok
    double m_recommendedHealthCover = 0;
    bool m_isHealthCoverAdequate = false;
    int m_healthVerdictLevel = 0; // 0=noData 1=critical 2=warn 3=ok
    double m_currentHealthCover = 0;
};

#endif