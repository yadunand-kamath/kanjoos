#ifndef POLICYMODEL_H
#define POLICYMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QVariantList>
#include <QVariantMap>

struct PolicyItem {
    QString category;      // "Health" | "Life" | "Asset"
    QString provider;
    QString policyNumber;
    double  sumInsured = 0.0;
    double  premium = 0.0;
    bool    isAnnual = false;   // false = monthly
    QString nominee;
    QString label;          // asset name; Asset category only
    double  assetValue = 0.0;   // optional insure-to target; Asset category only
};

class PolicyModel : public QAbstractListModel {
    Q_OBJECT

    Q_PROPERTY(double healthSumInsured READ healthSumInsured NOTIFY policiesUpdated)
    Q_PROPERTY(double lifeSumInsured   READ lifeSumInsured   NOTIFY policiesUpdated)
    Q_PROPERTY(double assetSumInsured  READ assetSumInsured  NOTIFY policiesUpdated)
    Q_PROPERTY(double totalSumInsured  READ totalSumInsured  NOTIFY policiesUpdated)

    Q_PROPERTY(double healthMonthlyPremium READ healthMonthlyPremium NOTIFY policiesUpdated)
    Q_PROPERTY(double lifeMonthlyPremium   READ lifeMonthlyPremium   NOTIFY policiesUpdated)
    Q_PROPERTY(double assetMonthlyPremium  READ assetMonthlyPremium  NOTIFY policiesUpdated)
    Q_PROPERTY(double totalMonthlyPremium  READ totalMonthlyPremium  NOTIFY policiesUpdated)

public:
    enum Roles {
        CategoryRole = Qt::UserRole + 1,
        ProviderRole, PolicyNumberRole, SumInsuredRole,
        PremiumRole, IsAnnualRole, NomineeRole,
        LabelRole, AssetValueRole,
        MonthlyPremiumRole
    };

    explicit PolicyModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        if (parent.isValid()) return 0;
        return m_data.count();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return QVariant();
        const auto &item = m_data.at(index.row());

        switch (role) {
        case CategoryRole:     return item.category;
        case ProviderRole:     return item.provider;
        case PolicyNumberRole: return item.policyNumber;
        case SumInsuredRole:   return item.sumInsured;
        case PremiumRole:      return item.premium;
        case IsAnnualRole:     return item.isAnnual;
        case NomineeRole:      return item.nominee;
        case LabelRole:        return item.label;
        case AssetValueRole:   return item.assetValue;
        case MonthlyPremiumRole: return item.isAnnual ? item.premium / 12.0 : item.premium;
        default: return QVariant();
        }
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role) override {
        if (!index.isValid() || index.row() >= m_data.count()) return false;
        auto &item = m_data[index.row()];
        bool changed = false;

        switch (role) {
        case ProviderRole:     item.provider = value.toString(); changed = true; break;
        case PolicyNumberRole: item.policyNumber = value.toString(); changed = true; break;
        case SumInsuredRole:   item.sumInsured = value.toDouble(); changed = true; break;
        case PremiumRole:      item.premium = value.toDouble(); changed = true; break;
        case IsAnnualRole:     item.isAnnual = value.toBool(); changed = true; break;
        case NomineeRole:      item.nominee = value.toString(); changed = true; break;
        case LabelRole:        item.label = value.toString(); changed = true; break;
        case AssetValueRole:   item.assetValue = value.toDouble(); changed = true; break;
        default: break;
        }

        if (changed) {
            emit dataChanged(index, index, {role, MonthlyPremiumRole});
            emit policiesUpdated();
            return true;
        }
        return false;
    }

    Q_INVOKABLE void addPolicy(const QString &category) {
        beginInsertRows(QModelIndex(), m_data.count(), m_data.count());
        PolicyItem item;
        item.category = category;
        item.provider = category == "Asset" ? "" : "New Provider";
        item.label = category == "Asset" ? "New Asset" : "";
        m_data << item;
        endInsertRows();
        emit policiesUpdated();
    }

    Q_INVOKABLE void removePolicy(int index) {
        if (index < 0 || index >= m_data.count()) return;
        beginRemoveRows(QModelIndex(), index, index);
        m_data.removeAt(index);
        endRemoveRows();
        emit policiesUpdated();
    }

    Q_INVOKABLE void setProvider(int index, const QString &v)     { setData(this->index(index), v, ProviderRole); }
    Q_INVOKABLE void setPolicyNumber(int index, const QString &v) { setData(this->index(index), v, PolicyNumberRole); }
    Q_INVOKABLE void setSumInsured(int index, double v)           { setData(this->index(index), v, SumInsuredRole); }
    Q_INVOKABLE void setPremium(int index, double v)              { setData(this->index(index), v, PremiumRole); }
    Q_INVOKABLE void setIsAnnual(int index, bool v)                { setData(this->index(index), v, IsAnnualRole); }
    Q_INVOKABLE void setNominee(int index, const QString &v)      { setData(this->index(index), v, NomineeRole); }
    Q_INVOKABLE void setLabel(int index, const QString &v)        { setData(this->index(index), v, LabelRole); }
    Q_INVOKABLE void setAssetValue(int index, double v)           { setData(this->index(index), v, AssetValueRole); }

    Q_INVOKABLE double sumInsuredFor(const QString &category) const {
        double sum = 0;
        for (const auto &item : std::as_const(m_data))
            if (item.category == category) sum += item.sumInsured;
        return sum;
    }

    Q_INVOKABLE double monthlyPremiumFor(const QString &category) const {
        double sum = 0;
        for (const auto &item : std::as_const(m_data))
            if (item.category == category) sum += item.isAnnual ? item.premium / 12.0 : item.premium;
        return sum;
    }

    Q_INVOKABLE int countFor(const QString &category) const {
        int count = 0;
        for (const auto &item : std::as_const(m_data))
            if (item.category == category) ++count;
        return count;
    }

    Q_INVOKABLE QVariantList policiesFor(const QString &category) const {
        QVariantList result;
        for (int i = 0; i < m_data.count(); ++i) {
            const auto &item = m_data.at(i);
            if (item.category != category) continue;
            QVariantMap m;
            m["index"]       = i;
            m["provider"]    = item.provider;
            m["policyNumber"]= item.policyNumber;
            m["sumInsured"]  = item.sumInsured;
            m["premium"]     = item.premium;
            m["isAnnual"]    = item.isAnnual;
            m["nominee"]     = item.nominee;
            m["label"]       = item.label;
            m["assetValue"]  = item.assetValue;
            result << m;
        }
        return result;
    }

    Q_INVOKABLE double assetDeficit() const {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (item.category != "Asset" || item.assetValue <= 0) continue;
            sum += std::max(0.0, item.assetValue - item.sumInsured);
        }
        return sum;
    }

    double healthSumInsured() const { return sumInsuredFor("Health"); }
    double lifeSumInsured()   const { return sumInsuredFor("Life"); }
    double assetSumInsured()  const { return sumInsuredFor("Asset"); }
    double totalSumInsured()  const { return healthSumInsured() + lifeSumInsured() + assetSumInsured(); }

    double healthMonthlyPremium() const { return monthlyPremiumFor("Health"); }
    double lifeMonthlyPremium()   const { return monthlyPremiumFor("Life"); }
    double assetMonthlyPremium()  const { return monthlyPremiumFor("Asset"); }
    double totalMonthlyPremium()  const { return healthMonthlyPremium() + lifeMonthlyPremium() + assetMonthlyPremium(); }

    QHash<int, QByteArray> roleNames() const override {
        return {
            {CategoryRole, "category"}, {ProviderRole, "provider"},
            {PolicyNumberRole, "policyNumber"}, {SumInsuredRole, "sumInsured"},
            {PremiumRole, "premium"}, {IsAnnualRole, "isAnnual"},
            {NomineeRole, "nominee"}, {LabelRole, "label"},
            {AssetValueRole, "assetValue"}, {MonthlyPremiumRole, "monthlyPremium"}
        };
    }

signals:
    void policiesUpdated();

private:
    QVector<PolicyItem> m_data;
};

#endif // POLICYMODEL_H
