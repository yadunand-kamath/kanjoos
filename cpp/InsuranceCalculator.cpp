#include "InsuranceCalculator.h"

void InsuranceCalculator::calculate() {
    if (!m_hasDependents && m_totalLoans == 0) {
        m_recommendedLifeCover = 0;
        m_lifeCoverDirective = "Not Required. You have no dependents and no debt.";
    }
    else if (!m_hasDependents && m_totalLoans > 0) {
        m_recommendedLifeCover = m_totalLoans;
        m_lifeCoverDirective = "Cover your debt so it doesn't pass to your co-signers.";
    }
    else {
        double totalNeed = m_totalLoans + m_futureMilestones + (m_annualExpenses * m_multiplier);
        double netCoverNeeded = totalNeed - m_currentLiquidAssets;

        if (netCoverNeeded <= 0) {
            m_recommendedLifeCover = 0;
            m_lifeCoverDirective = "You are self-insured! Your current liquid wealth fully covers your family's needs.";
        } else {
            m_recommendedLifeCover = netCoverNeeded;
            m_lifeCoverDirective = "Pure Term Cover needed to bridge the gap between your current wealth and family's future needs.";
        }
    }
    emit resultsChanged();
}