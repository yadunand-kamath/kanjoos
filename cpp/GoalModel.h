#ifndef GOALMODEL_H
#define GOALMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <cmath>
#include <QDebug>

#include "UnifiedSipModel.h"

struct GoalItem {
    int priority;
    QString goalName;
    int yearsLeft;
    double currentCost;
    double currentFunded;
};

class GoalModel : public QAbstractListModel {
    Q_OBJECT
    // Global Tier Properties
    Q_PROPERTY(double shortInf MEMBER m_shortInf NOTIFY settingsChanged)
    Q_PROPERTY(double shortRet MEMBER m_shortRet NOTIFY settingsChanged)
    Q_PROPERTY(double medInf   MEMBER m_medInf   NOTIFY settingsChanged)
    Q_PROPERTY(double medRet   MEMBER m_medRet   NOTIFY settingsChanged)
    Q_PROPERTY(double longInf  MEMBER m_longInf  NOTIFY settingsChanged)
    Q_PROPERTY(double longRet  MEMBER m_longRet  NOTIFY settingsChanged)
    Q_PROPERTY(double totalRequiredSIP READ totalRequiredSIP NOTIFY totalsChanged)
    Q_PROPERTY(double coverageRatio READ coverageRatio NOTIFY totalsChanged)

public:
    enum Roles {
        PriorityRole = Qt::UserRole + 1,
        GoalNameRole,
        YearsLeftRole,
        CurrentCostRole,
        CurrentFundedRole,
        ActualSIPRole,
        FutureTargetRole, // Calculated
        RequiredSIPRole,  // Calculated
        HorizonRole       // Calculated Label
    };

    explicit GoalModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        // Default Tier Settings
        m_shortInf = 5.0;  m_shortRet = 6.0;   // Short Term
        m_medInf   = 6.0;  m_medRet   = 9.0;   // Medium Term
        m_longInf  = 7.0;  m_longRet  = 12.0;  // Long Term

        // Default Data
        m_data << GoalItem{1, "Emergency Fund", 1, 500000.0, 50000.0};
        m_data << GoalItem{2, "Retirement", 25, 2000000.0, 0.0};

        updateTotals();
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        return m_data.count();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return QVariant();

        const auto &item = m_data.at(index.row());

        double inf, ret;
        QString horizon;
        // Determine horizon
        if (item.yearsLeft < 1) { inf = 0; ret = 0; horizon = "-"; }
        else if (item.yearsLeft < 2) { inf = m_shortInf; ret = m_shortRet; horizon = "Short"; }
        else if (item.yearsLeft < 5) { inf = m_medInf; ret = m_medRet; horizon = "Medium"; }
        else { inf = m_longInf; ret = m_longRet; horizon = "Long"; }

        // Perform Calculations
        double futureTarget = (item.yearsLeft <= 0) ? item.currentCost : item.currentCost * std::pow(1.0 + (inf/100.0), item.yearsLeft);
        double reqSIP = (item.yearsLeft <= 0) ? 0 : calculateRequiredSIP(item, futureTarget, ret);

        switch (role) {
        case PriorityRole:      return item.priority;
        case GoalNameRole:      return item.goalName;
        case YearsLeftRole:     return item.yearsLeft;
        case CurrentCostRole:   return item.currentCost;
        case CurrentFundedRole: return item.currentFunded;
        case FutureTargetRole:  return futureTarget;
        case ActualSIPRole:     return m_sipModel ? m_sipModel->getGoalSum(item.goalName) : 0.0;
        case RequiredSIPRole:   return reqSIP;
        case HorizonRole:       return horizon;
        default:                return QVariant();
        }
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role) override {
        if (!index.isValid() || index.row() >= m_data.count()) return false;

        auto &item = m_data[index.row()];
        bool changed = false;

        if (role == PriorityRole) {
            // RULE: Cannot change priority of "Emergency Fund" (Index 0)
            if (index.row() == 0) return false;

            int newPrio = value.toInt();
            // RULE: Cannot swap into position 1 (Emergency Fund is fixed at 1)
            if (newPrio <= 1 || newPrio > m_data.count()) return false;

            int oldPrio = item.priority;
            int targetIdx = -1;

            // Find the item currently holding the target priority
            for(int i=0; i < m_data.count(); ++i) {
                if (m_data[i].priority == newPrio) {
                    targetIdx = i;
                    break;
                }
            }

            if (targetIdx != -1 && targetIdx != index.row()) {
                beginResetModel();
                // Perform the swap
                m_data[targetIdx].priority = oldPrio;
                m_data[index.row()].priority = newPrio;

                // Sort to ensure visual order matches priority
                std::sort(m_data.begin(), m_data.end(), [](const GoalItem &a, const GoalItem &b){
                    return a.priority < b.priority;
                });
                endResetModel();
                return true;
            }
            return false;
        }

        switch (role) {
        case GoalNameRole: // Block renaming for both protected goals
            if (item.goalName != "Emergency Fund" && item.goalName != "Retirement") {
                item.goalName = value.toString();
                changed = true;
            }
            break;
        case YearsLeftRole:   item.yearsLeft = value.toInt(); changed = true; break;
        case CurrentCostRole: item.currentCost = value.toDouble(); changed = true; break;
        case CurrentFundedRole: item.currentFunded = value.toDouble(); changed = true; break;
        }

        if (changed) {
            // Signal refresh for the row and all calculated columns
            emit dataChanged(index, index, {role, FutureTargetRole, RequiredSIPRole, HorizonRole});
            updateTotals();
            return true;
        }
        return false;
    }

    QHash<int, QByteArray> roleNames() const override {
        return {
            {PriorityRole, "priority"},
            {GoalNameRole, "goalName"},
            {YearsLeftRole, "yearsLeft"},
            {CurrentCostRole, "currentCost"},
            {CurrentFundedRole, "currentFunded"},
            {ActualSIPRole, "actualSIP"},
            {FutureTargetRole, "futureTarget"},
            {RequiredSIPRole, "requiredSIP"},
            {HorizonRole, "horizon"}
        };
    }

    Q_INVOKABLE void updateSettings(double si, double sr, double mi, double mr, double li, double lr) {
        m_shortInf = si; m_shortRet = sr;
        m_medInf = mi;   m_medRet = mr;
        m_longInf = li;  m_longRet = lr;
        emit settingsChanged();
        if (!m_data.isEmpty())
            emit dataChanged(index(0, 0), index(m_data.count() - 1, 0));
    }

    Q_INVOKABLE void addGoal() {
        int newIndex = m_data.count();
        beginInsertRows(QModelIndex(), newIndex, newIndex);
        // Corrected struct mapping (6 members)
        m_data << GoalItem{newIndex + 1, "New Goal", 10, 100000.0, 0.0};
        endInsertRows();
        updateTotals();
    }

    Q_INVOKABLE void removeGoal(int index) {
        if (index < 1 || index >= m_data.count()) return;

        // Do not allow removal of fixed goals.
        QString name = m_data[index].goalName;
        if (name == "Emergency Fund" || name == "Retirement") return;

        beginRemoveRows(QModelIndex(), index, index);
        m_data.removeAt(index);
        // Re-normalize priorities for remaining removable items
        for(int i = 0; i < m_data.size(); ++i) m_data[i].priority = i + 1;
        endRemoveRows();
        updateTotals();
    }

    double totalRequiredSIP() const { return m_totalRequiredSIP; }

    double coverageRatio() const { return m_coverageRatio; }

    void updateTotals() {
        // Safety check: if model is empty, reset totals and exit
        if (m_data.isEmpty()) {
            m_totalRequiredSIP = 0;
            m_coverageRatio = 0;
            emit totalsChanged();
            return;
        }
        double sumRequired = 0;
        double sumActual = 0;

        for (const auto &item : std::as_const(m_data)) {
            // Re-run the same logic used in data() to find the horizon rate
            double rate = (item.yearsLeft < 2) ? m_shortRet :
                              (item.yearsLeft < 5) ? m_medRet : m_longRet;

            double inf = (item.yearsLeft < 2) ? m_shortInf :
                             (item.yearsLeft < 5) ? m_medInf : m_longInf;

            double fv = item.currentCost * std::pow(1.0 + (inf/100.0), item.yearsLeft);

            sumRequired += calculateRequiredSIP(item, fv, rate);

            if (m_sipModel) {
                sumActual += m_sipModel->getGoalSum(item.goalName);
            }
        }

        m_totalRequiredSIP = sumRequired;
        // Prevent division by zero
        m_coverageRatio = (sumRequired > 0) ? (sumActual / sumRequired) * 100.0 : 0.0;
        // Notify QML
        emit totalsChanged();
    }

    void setSipModel(UnifiedSipModel* model) {
        m_sipModel = model;
        // This ensures "Actual SIP" and "Coverage Ratio" update on startup
        handleSipUpdate();
    }

public slots:
    void handleSipUpdate() {
        if (m_data.isEmpty()) return;
        // This tells the QML ListView to re-call the data() function for the ActualSIPRole
        emit dataChanged(index(0, 0), index(m_data.count() - 1, 0), {ActualSIPRole});
        updateTotals(); // update the footer (Total Required / Coverage)
    }

signals:
    void settingsChanged();
    void totalsChanged();

private:
    double calculateRequiredSIP(const GoalItem &item, double fv, double rate) const {
        if (item.yearsLeft <= 0) return 0;

        // Monthly compounded rate
        double r = std::pow(1.0 + (rate/100.0), 1.0/12.0) - 1.0;
        int n = item.yearsLeft * 12;

        // FV of current corpus growing at expected rate
        double fvLump = item.currentFunded * std::pow(1.0 + (rate/100.0), item.yearsLeft);
        double gap = fv - fvLump;

        if (gap <= 0) return 0;

        // SIP Formula (Annuity Due: payment at start of period)
        return (gap * r) / ((std::pow(1.0 + r, n) - 1.0) * (1.0 + r));
    }

    QVector<GoalItem> m_data;
    double m_shortInf, m_shortRet, m_medInf, m_medRet, m_longInf, m_longRet;
    double m_totalRequiredSIP = 0;
    double m_coverageRatio = 0;

    UnifiedSipModel* m_sipModel = nullptr;
};

#endif