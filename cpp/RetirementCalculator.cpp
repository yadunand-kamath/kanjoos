#include "RetirementCalculator.h"

double RetirementCalculator::corpusNeeded() {
    double yearsToRetire = m_retireAge - m_currentAge;
    double yearsInRetire = m_lifeExpectancy - m_retireAge;

    // 1. Future Value of Monthly Expense at Retirement
    double annualExpFuture = (m_monthlyExpense * 12 * m_lifestyleMultiplier) * std::pow(1 + (m_inflation/100.0), yearsToRetire);

    // 2. Real Rate of Return (Inflation Adjusted)
    double r_real = ((1.0 + (m_postReturn/100.0)) / (1.0 + (m_inflation/100.0))) - 1.0;

    if (std::abs(r_real) < 0.0001) return annualExpFuture * yearsInRetire;

    // 3. Present Value of Annuity Formula
    double corpus = annualExpFuture * ((1.0 - std::pow(1.0 + r_real, -yearsInRetire)) / r_real);
    return corpus;
}

void RetirementCalculator::updateVerdict() {
    double total = corpusNeeded();
    double liquidAvailable = total * (1.0 - m_lockedRatio);

    // Monthly expense inflated to retirement year
    double monthlyAtRetire = (m_monthlyExpense * m_lifestyleMultiplier) *
                             std::pow(1 + (m_inflation/100.0), m_retireAge - m_currentAge);
    double annualAtRetire = monthlyAtRetire * 12;

    int gapYears = std::max(0, 60 - m_retireAge);
    double cashNeededForGap = annualAtRetire * gapYears;

    if (gapYears > 0 && liquidAvailable < cashNeededForGap) {
        int yearsLiquidLasts = static_cast<int>(liquidAvailable / annualAtRetire);
        int exhaustionAge = m_retireAge + yearsLiquidLasts;

        m_verdictText = QString("⚠️ WARNING: Your Liquid Cash will run out by age %1. "
                                "You are heavily over-exposed to government-locked funds. "
                                "You cannot survive until your Locked Cash opens at age 60.")
                            .arg(exhaustionAge);
    } else {
        m_verdictText = "✅ Asset allocation optimized. Your Liquid Cash safely covers "
                        "the early retirement gap until your Locked Cash opens at 60.";
    }
    emit verdictChanged();
}

