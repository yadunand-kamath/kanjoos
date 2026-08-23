#include "InsuranceCalculator.h"

void InsuranceCalculator::calculate() {
    bool noData = (m_annualExpenses <= 0 && m_totalLoans <= 0 &&
                   m_futureMilestones <= 0 && m_currentLiquidAssets <= 0);
    if (noData) {
        m_recommendedLifeCover = 0;
        m_lifeVerdictLevel = 0;
        m_lifeCoverDirective = "Tell us about your dependents and expenses to size your cover.";
        m_recommendedHealthCover = 0;
        m_healthVerdictLevel = 0;
        m_isHealthCoverAdequate = false;
        emit resultsChanged();
        return;
    }

    // Life cover
    if (!m_hasDependents && m_totalLoans == 0) {
        m_recommendedLifeCover = 0;
        m_lifeVerdictLevel = 3;
        m_lifeCoverDirective = "Not Required. You have no dependents and no debt.";
    }
    else if (!m_hasDependents && m_totalLoans > 0) {
        m_recommendedLifeCover = m_totalLoans;
        m_lifeVerdictLevel = 2;
        m_lifeCoverDirective = "Cover your debt so it doesn't pass to your co-signers.";
    }
    else {
        double totalNeed = m_totalLoans + m_futureMilestones + (m_annualExpenses * m_multiplier);
        double netCoverNeeded = totalNeed - m_currentLiquidAssets;

        if (netCoverNeeded <= 0) {
            m_recommendedLifeCover = 0;
            m_lifeVerdictLevel = 3;
            m_lifeCoverDirective = "You are self-insured! Your current liquid wealth fully covers your family's needs.";
        } else {
            m_recommendedLifeCover = netCoverNeeded;
            m_lifeVerdictLevel = 1;
            m_lifeCoverDirective = "Pure Term Cover needed to bridge the gap between your current wealth and family's future needs.";
        }
    }

    // Health cover: target is healthMultiplier x annual expenses (default 12.5x, 10-15x rule)
    m_recommendedHealthCover = m_annualExpenses * m_healthMultiplier;
    m_isHealthCoverAdequate  = m_annualExpenses > 0 && m_currentHealthCover >= m_recommendedHealthCover;
    m_healthVerdictLevel = m_isHealthCoverAdequate ? 3 : (m_currentHealthCover > 0 ? 2 : 1);

    emit resultsChanged();
}
