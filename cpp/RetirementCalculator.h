#ifndef RETIREMENTCALCULATOR_H
#define RETIREMENTCALCULATOR_H

#include <QObject>
#include <cmath>

class RetirementCalculator : public QObject {
    Q_OBJECT

    // All input properties notify via dataChanged; derived properties have their own signals.
    Q_PROPERTY(int    currentAge          READ currentAge          WRITE setCurrentAge          NOTIFY dataChanged)
    Q_PROPERTY(int    retireAge           READ retireAge           WRITE setRetireAge           NOTIFY dataChanged)
    Q_PROPERTY(int    lifeExpectancy      READ lifeExpectancy      WRITE setLifeExpectancy      NOTIFY dataChanged)
    Q_PROPERTY(int    lockedFundOpenAge   READ lockedFundOpenAge   WRITE setLockedFundOpenAge   NOTIFY dataChanged)
    Q_PROPERTY(double monthlyExpense      READ monthlyExpense      WRITE setMonthlyExpense      NOTIFY dataChanged)
    Q_PROPERTY(double inflation           READ inflation           WRITE setInflation           NOTIFY dataChanged)
    Q_PROPERTY(double postReturn          READ postReturn          WRITE setPostReturn          NOTIFY dataChanged)
    Q_PROPERTY(double lifestyleMultiplier READ lifestyleMultiplier WRITE setLifestyleMultiplier NOTIFY dataChanged)
    Q_PROPERTY(double lockedRatio         READ lockedRatio         WRITE setLockedRatio         NOTIFY dataChanged)

    // Accumulated-asset inputs — written only from main.cpp (batched from
    // RetirementAssetModel::assetsChanged), never from QML. See setAccumulated().
    Q_PROPERTY(double corpusAccumulated   READ corpusAccumulated   NOTIFY dataChanged)
    Q_PROPERTY(double liquidAccumulated   READ liquidAccumulated   NOTIFY dataChanged)

    // Derived — recomputed in recalculate(), notify via dataChanged
    Q_PROPERTY(double  corpusNeeded         READ corpusNeeded         NOTIFY dataChanged)
    Q_PROPERTY(double  futureMonthlyExpense READ futureMonthlyExpense NOTIFY dataChanged)
    Q_PROPERTY(double  shortfall            READ shortfall            NOTIFY dataChanged)
    Q_PROPERTY(double  fundedRatio          READ fundedRatio          NOTIFY dataChanged)
    Q_PROPERTY(int     verdictLevel         READ verdictLevel         NOTIFY dataChanged)
    Q_PROPERTY(int     liquidRunwayYears    READ liquidRunwayYears    NOTIFY dataChanged)
    Q_PROPERTY(QString verdictText          READ verdictText          NOTIFY dataChanged)
    Q_PROPERTY(bool    hasWarning           READ hasWarning           NOTIFY dataChanged)

public:
    explicit RetirementCalculator(QObject *parent = nullptr)
        : QObject(parent),
          m_currentAge(30), m_retireAge(60), m_lifeExpectancy(85),
          m_lockedFundOpenAge(60),
          m_monthlyExpense(50000.0), m_inflation(7.5), m_postReturn(8.0),
          m_lifestyleMultiplier(1.0), m_lockedRatio(0.4)
    {
        recalculate();
    }

    // Getters
    int    currentAge()          const { return m_currentAge; }
    int    retireAge()           const { return m_retireAge; }
    int    lifeExpectancy()      const { return m_lifeExpectancy; }
    int    lockedFundOpenAge()   const { return m_lockedFundOpenAge; }
    double monthlyExpense()      const { return m_monthlyExpense; }
    double inflation()           const { return m_inflation; }
    double postReturn()          const { return m_postReturn; }
    double lifestyleMultiplier() const { return m_lifestyleMultiplier; }
    double lockedRatio()         const { return m_lockedRatio; }
    double corpusAccumulated()   const { return m_corpusAccumulated; }
    double liquidAccumulated()   const { return m_liquidAccumulated; }
    double corpusNeeded()        const { return m_corpusNeeded; }
    double futureMonthlyExpense() const { return m_futureMonthlyExpense; }
    double shortfall()           const { return m_shortfall; }
    double fundedRatio()         const { return m_fundedRatio; }
    int    verdictLevel()        const { return m_verdictLevel; }
    int    liquidRunwayYears()   const { return m_liquidRunwayYears; }
    QString verdictText()        const { return m_verdictText; }
    bool    hasWarning()         const { return m_verdictLevel <= 2; }

public slots:
    void setCurrentAge(int val) {
        if (m_currentAge == val) return;
        m_currentAge = val;
        recalculate();
    }
    void setRetireAge(int val) {
        if (m_retireAge == val) return;
        m_retireAge = val;
        recalculate();
    }
    void setLifeExpectancy(int val) {
        if (m_lifeExpectancy == val) return;
        m_lifeExpectancy = val;
        recalculate();
    }
    void setLockedFundOpenAge(int val) {
        if (m_lockedFundOpenAge == val) return;
        m_lockedFundOpenAge = val;
        recalculate();
    }
    void setMonthlyExpense(double val) {
        if (qFuzzyCompare(m_monthlyExpense + 1.0, val + 1.0)) return;
        m_monthlyExpense = val;
        recalculate();
    }
    void setInflation(double val) {
        if (qFuzzyCompare(m_inflation + 1.0, val + 1.0)) return;
        m_inflation = val;
        recalculate();
    }
    void setPostReturn(double val) {
        if (qFuzzyCompare(m_postReturn + 1.0, val + 1.0)) return;
        m_postReturn = val;
        recalculate();
    }
    void setLifestyleMultiplier(double val) {
        if (qFuzzyCompare(m_lifestyleMultiplier + 1.0, val + 1.0)) return;
        m_lifestyleMultiplier = val;
        recalculate();
    }
    void setLockedRatio(double val) {
        if (qFuzzyCompare(m_lockedRatio + 1.0, val + 1.0)) return;
        m_lockedRatio = val;
        recalculate();
    }

    // Batched push from main.cpp whenever RetirementAssetModel::assetsChanged
    // fires — avoids three separate recalculate() passes and the intermediate
    // inconsistent state where total is fresh but liquid is stale.
    void setAccumulated(double total, double liquid, double lockedRatioVal) {
        bool changed = false;
        if (!qFuzzyCompare(m_corpusAccumulated + 1.0, total + 1.0)) {
            m_corpusAccumulated = total;
            changed = true;
        }
        if (!qFuzzyCompare(m_liquidAccumulated + 1.0, liquid + 1.0)) {
            m_liquidAccumulated = liquid;
            changed = true;
        }
        if (!qFuzzyCompare(m_lockedRatio + 1.0, lockedRatioVal + 1.0)) {
            m_lockedRatio = lockedRatioVal;
            changed = true;
        }
        if (changed) recalculate();
    }

signals:
    void dataChanged();

private:
    int    m_currentAge, m_retireAge, m_lifeExpectancy, m_lockedFundOpenAge;
    double m_monthlyExpense, m_inflation, m_postReturn, m_lifestyleMultiplier, m_lockedRatio;

    double m_corpusAccumulated = 0.0;
    double m_liquidAccumulated = 0.0;

    // Cached derived values — recomputed together in recalculate()
    double  m_corpusNeeded         = 0.0;
    double  m_futureMonthlyExpense = 0.0;
    double  m_shortfall            = 0.0;
    double  m_fundedRatio          = 0.0;
    int     m_verdictLevel         = 0; // 0=noData 1=critical 2=warn 3=ok
    int     m_liquidRunwayYears    = 0;
    QString m_verdictText;

    static QString fmtRupee(double v) {
        if (v >= 10000000.0) return QString::number(v / 10000000.0, 'f', 2) + " Cr";
        if (v >= 100000.0)   return QString::number(v / 100000.0, 'f', 2) + " L";
        return QString::number(v, 'f', 0);
    }

    void recalculate() {
        int yearsToRetire = m_retireAge - m_currentAge;
        int yearsInRetire = m_lifeExpectancy - m_retireAge;

        // Guard against nonsensical age combinations
        if (yearsToRetire <= 0 || yearsInRetire <= 0) {
            m_corpusNeeded         = 0.0;
            m_futureMonthlyExpense = 0.0;
            m_shortfall            = 0.0;
            m_fundedRatio          = 0.0;
            m_liquidRunwayYears    = 0;
            m_verdictLevel         = 0;
            m_verdictText          = "⚠️ Check ages: Retire Age must be greater than Current Age, and less than Life Expectancy.";
            emit dataChanged();
            return;
        }

        // Future monthly expense at retirement (inflation-adjusted, lifestyle-scaled)
        double growthFactor    = std::pow(1.0 + m_inflation / 100.0, yearsToRetire);
        m_futureMonthlyExpense = m_monthlyExpense * m_lifestyleMultiplier * growthFactor;
        double annualExpFuture = m_futureMonthlyExpense * 12.0;

        // Real rate of return (inflation-adjusted)
        double r_real = ((1.0 + m_postReturn / 100.0) / (1.0 + m_inflation / 100.0)) - 1.0;

        if (std::abs(r_real) < 0.0001)
            m_corpusNeeded = annualExpFuture * yearsInRetire;
        else
            m_corpusNeeded = annualExpFuture * ((1.0 - std::pow(1.0 + r_real, -yearsInRetire)) / r_real);

        m_shortfall   = std::max(0.0, m_corpusNeeded - m_corpusAccumulated);
        m_fundedRatio = m_corpusNeeded > 0 ? (m_corpusAccumulated / m_corpusNeeded) : 0.0;

        // Liquidity-gap check: does the OWNED liquid amount (grown to retirement)
        // cover expenses during the gap before locked funds open?
        double liquidAtRetire   = m_liquidAccumulated * std::pow(1.0 + m_postReturn / 100.0, yearsToRetire);
        int    gapYears         = std::max(0, m_lockedFundOpenAge - m_retireAge);
        double cashNeededForGap = annualExpFuture * gapYears;
        m_liquidRunwayYears     = annualExpFuture > 0 ? static_cast<int>(liquidAtRetire / annualExpFuture) : 0;

        // Verdict — first match wins.
        if (m_corpusAccumulated <= 0.0) {
            m_verdictLevel = 0;
            m_verdictText  = "No retirement assets linked yet. Add assets below, or link "
                              "portfolio holdings to the Retirement goal, to see your real progress.";
        } else if (m_fundedRatio < 1.0) {
            m_verdictLevel = (m_fundedRatio < 0.5) ? 1 : 2;
            m_verdictText  = QString(
                "You're %1% funded toward your ₹%2 target corpus — a shortfall of ₹%3.")
                .arg(static_cast<int>(m_fundedRatio * 100))
                .arg(fmtRupee(m_corpusNeeded))
                .arg(fmtRupee(m_shortfall));
        } else if (gapYears > 0 && liquidAtRetire < cashNeededForGap) {
            int exhaustionAge = m_retireAge + m_liquidRunwayYears;
            m_verdictLevel = 2;
            m_verdictText  = QString(
                "Corpus target met, but your liquid assets alone run out by age %1 — "
                "before your locked funds open at age %2.")
                .arg(exhaustionAge).arg(m_lockedFundOpenAge);
        } else {
            m_verdictLevel = 3;
            m_verdictText  = QString(
                "On track. Your corpus meets the target and liquid assets safely cover "
                "the gap until locked funds open at age %1.").arg(m_lockedFundOpenAge);
        }

        emit dataChanged();
    }
};

#endif
