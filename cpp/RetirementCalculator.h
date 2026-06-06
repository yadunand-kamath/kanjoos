#ifndef RETIREMENTCALCULATOR_H
#define RETIREMENTCALCULATOR_H

#include <QObject>
#include <cmath>

class RetirementCalculator : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentAge READ currentAge WRITE setCurrentAge NOTIFY dataChanged)
    Q_PROPERTY(int retireAge READ retireAge WRITE setRetireAge NOTIFY dataChanged)
    Q_PROPERTY(int lifeExpectancy READ lifeExpectancy WRITE setLifeExpectancy NOTIFY dataChanged)
    Q_PROPERTY(double monthlyExpense READ monthlyExpense WRITE setMonthlyExpense NOTIFY dataChanged)
    Q_PROPERTY(double inflation READ inflation WRITE setInflation NOTIFY dataChanged)
    Q_PROPERTY(double postReturn READ postReturn WRITE setPostReturn NOTIFY dataChanged)
    Q_PROPERTY(double corpusNeeded READ corpusNeeded NOTIFY corpusCalculated)
    Q_PROPERTY(double lifestyleMultiplier READ lifestyleMultiplier WRITE setLifestyleMultiplier NOTIFY dataChanged)
    Q_PROPERTY(double lockedRatio READ lockedRatio WRITE setLockedRatio NOTIFY dataChanged)
    Q_PROPERTY(QString verdictText READ verdictText NOTIFY verdictChanged)

public:
    explicit RetirementCalculator(QObject *parent = nullptr) : QObject(parent),
        m_currentAge(30), m_retireAge(50), m_lifeExpectancy(85), m_monthlyExpense(50000),
        m_inflation(7.5), m_postReturn(8.0), m_lifestyleMultiplier(1.0) {}

    // Getters
    int currentAge() const { return m_currentAge; }
    int retireAge() const { return m_retireAge; }
    int lifeExpectancy() const { return m_lifeExpectancy; }
    double monthlyExpense() const { return m_monthlyExpense; }
    double inflation() const { return m_inflation; }
    double postReturn() const { return m_postReturn; }
    double lifestyleMultiplier() const { return m_lifestyleMultiplier; }
    double lockedRatio() const { return m_lockedRatio; }
    QString verdictText() const { return m_verdictText; }
    double corpusNeeded();

public slots:
    void setCurrentAge(int val) {
        if(m_currentAge != val) {
            m_currentAge = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setRetireAge(int val) {
        if(m_retireAge != val) {
            m_retireAge = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setLifeExpectancy(int val) {
        if(m_lifeExpectancy != val) {
            m_lifeExpectancy = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setMonthlyExpense(double val) {
        if(m_monthlyExpense != val) {
            m_monthlyExpense = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setInflation(double val) {
        if(m_inflation != val) {
            m_inflation = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setPostReturn(double val) {
        if(m_postReturn != val) {
            m_postReturn = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setLifestyleMultiplier(double val) {
        if(m_lifestyleMultiplier != val) {
            m_lifestyleMultiplier = val;
            emit dataChanged();
            emit corpusCalculated();
        }
    }
    void setLockedRatio(double val) {
        if(!qFuzzyCompare(m_lockedRatio, val)) {
            m_lockedRatio = val;
            updateVerdict();
            emit dataChanged();
        }
    }

signals:
    void dataChanged();
    void corpusCalculated();
    void verdictChanged();

private:
    int m_currentAge, m_retireAge, m_lifeExpectancy;
    double m_monthlyExpense, m_inflation, m_postReturn, m_lifestyleMultiplier;
    void updateVerdict(); // Logic implementation
    double m_lockedRatio = 0.4; // Default 40% locked (EPF/PPF)
    QString m_verdictText;
};

#endif