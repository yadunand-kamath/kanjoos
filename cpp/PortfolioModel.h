#ifndef PORTFOLIOMODEL_H
#define PORTFOLIOMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QStringList>

struct PortfolioItem {
    QString assetType;
    QString name;
    QString market;
    QString subType;
    QString category;
    double invested;
    double currentValue;
    QString goalLink;
};

class PortfolioModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        TypeRole = Qt::UserRole + 1, // 257 (Matches Proxy)
        NameRole, MarketRole, SubTypeRole, CategoryRole,
        InvestedRole, ValueRole, ReturnRole, GoalRole
    };

    explicit PortfolioModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        // EQUITY
        // m_data << PortfolioItem{"Equity", "Bluechip Stocks", "Domestic", "Stock", "Largecap", 850000.0, 1120000.0, "Retirement"};
        // m_data << PortfolioItem{"Equity", "Nasdaq 100", "International", "ETF", "Largecap", 400000.0, 525000.0, "Retirement"};
        // m_data << PortfolioItem{"Equity", "Midcap Fund", "Domestic", "Mutual Fund", "Midcap", 200000.0, 185000.0, "Home Downpayment"};

        // // DEBT
        // m_data << PortfolioItem{"Debt", "HDFC Fixed Deposit", "Domestic", "FD/RD", "-", 500000.0, 535000.0, "Emergency Fund"};
        // m_data << PortfolioItem{"Debt", "Employee Provident Fund", "Domestic", "Govt. Scheme", "-", 1200000.0, 1200000.0, "Retirement"};
        // m_data << PortfolioItem{"Debt", "Sovereign Gold Bond", "Domestic", "Bond", "-", 150000.0, 180000.0, "World Tour"};

        // // REAL ESTATE
        // m_data << PortfolioItem{"Real Estate", "Ancestral Land", "Domestic", "Other", "-", 2500000.0, 4800000.0, "Retirement"};
        // m_data << PortfolioItem{"Real Estate", "REIT - Embassy", "Domestic", "REITs", "-", 100000.0, 112000.0, "Home Downpayment"};

        // // COMMODITY
        // m_data << PortfolioItem{"Commodity", "Physical Gold", "Domestic", "Physical", "-", 250000.0, 380000.0, "Emergency Fund"};

        // // CRYPTO
        // m_data << PortfolioItem{"Crypto", "Bitcoin", "-", "-", "-", 150000.0, 245000.0, "None"};
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.count(); }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return QVariant();
        const auto &item = m_data.at(index.row());

        switch (role) {
        case TypeRole: return item.assetType;
        case NameRole: return item.name;
        case MarketRole:   return item.market;
        case SubTypeRole:  return item.subType;
        case CategoryRole: return item.category;
        case InvestedRole: return item.invested;
        case ValueRole: return item.currentValue;
        case GoalRole: return item.goalLink;
        case ReturnRole: {
            if (item.invested <= 0) return 0.0;
            return ((item.currentValue - item.invested) / item.invested) * 100.0;
        }
        default: return QVariant();
        }
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role) override {
        if (!index.isValid()) return false;
        auto &item = m_data[index.row()];
        bool changed = false;
        switch (role) {
        case NameRole: item.name = value.toString(); changed = true; break;
        case MarketRole:   item.market = value.toString(); changed = true; break;
        case SubTypeRole:  item.subType = value.toString(); changed = true; break;
        case CategoryRole: item.category = value.toString(); changed = true; break;
        case InvestedRole: item.invested = value.toDouble(); changed = true; break;
        case ValueRole: item.currentValue = value.toDouble(); changed = true; break;
        case GoalRole:
            if (item.goalLink != value.toString()) {
                item.goalLink = value.toString();
                changed = true;
            }
            break;
        }

        if (changed) {
            // When invested or value changes, notify QML that Returns also changed
            emit dataChanged(index, index, {role, ReturnRole});
            emit portfolioUpdated();
            return true;
        }
        return false;
    }

    Q_INVOKABLE void addEntry(QString type) {
        beginInsertRows(QModelIndex(), m_data.count(), m_data.count());
        m_data << PortfolioItem{type, "New " + type, "Domestic", "Other", "-", 0.0, 0.0, "None"};
        endInsertRows();
        emit portfolioUpdated();
    }

    Q_INVOKABLE void removeEntry(int index) {
        if (index < 0 || index >= m_data.count()) return;
        beginRemoveRows(QModelIndex(), index, index);
        m_data.removeAt(index);
        endRemoveRows();
        emit portfolioUpdated();
    }

    // Remove all entries of a specific asset type
    Q_INVOKABLE void clearAsset(const QString &type) {
        for (int i = m_data.count() - 1; i >= 0; --i) {
            if (m_data[i].assetType == type) {
                beginRemoveRows(QModelIndex(), i, i);
                m_data.removeAt(i);
                endRemoveRows();
            }
        }
        emit portfolioUpdated();
    }

    // Remove all portfolio entries
    Q_INVOKABLE void clearAll() {
        if (m_data.isEmpty()) return;
        beginResetModel();
        m_data.clear();
        endResetModel();
        emit portfolioUpdated();
    }

    Q_INVOKABLE QVariantList getEntries(const QString &type) const {
        QVariantList result;
        for (const auto &item : std::as_const(m_data)) {
            if (type != "Total" && item.assetType != type) continue;
            QVariantMap m;
            m["name"]     = item.name;
            m["subType"]  = item.subType;
            m["category"] = item.category;
            m["market"]   = item.market;
            m["invested"] = item.invested;
            m["value"]    = item.currentValue;
            m["goalLink"] = item.goalLink;
            result << m;
        }
        return result;
    }

    Q_INVOKABLE double getTotalValue(QString type) {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (type == "Total" || item.assetType == type) sum += item.currentValue;
        }
        return sum;
    }

    // Sum current value for entries whose subType is in the provided list
    Q_INVOKABLE double getLiquidValue(const QStringList &liquidSubTypes) const {
        double sum = 0;
        for (const auto &item : std::as_const(m_data))
            if (liquidSubTypes.contains(item.subType)) sum += item.currentValue;
        return sum;
    }

    Q_INVOKABLE double getIlliquidValue(const QStringList &illiquidSubTypes) const {
        double sum = 0;
        for (const auto &item : std::as_const(m_data))
            if (illiquidSubTypes.contains(item.subType)) sum += item.currentValue;
        return sum;
    }

    // Returns name/isLiquid/value for all portfolio items linked to goalName,
    // for use by RetirementAssetModel::syncPortfolioAssets()
    Q_INVOKABLE QVariantList getAssetsForGoal(const QString &goalName) const {
        static const QStringList liquidSubTypes = {
            "Stock","Mutual Fund","ETF","FD/RD","Bond","Fund",
            "Cash & Savings","REITs","Digital","ETF/Fund","Crypto"
        };
        QVariantList result;
        for (const auto &item : std::as_const(m_data)) {
            if (item.goalLink != goalName) continue;
            QVariantMap m;
            m["name"]      = item.name;
            m["isLiquid"]  = liquidSubTypes.contains(item.subType);
            m["value"]     = item.currentValue;
            m["assetType"] = item.assetType;
            result << m;
        }
        return result;
    }

    // Helper for GoalModel
    Q_INVOKABLE double getFundedAmountForGoal(const QString &goalName) {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (item.goalLink == goalName) sum += item.currentValue;
        }
        return sum;
    }

    QHash<int, QByteArray> roleNames() const override {
        return { {TypeRole, "assetType"}, {NameRole, "name"}, {MarketRole, "market"},
                {SubTypeRole, "subType"}, {CategoryRole, "category"}, {InvestedRole, "invested"},
                {ValueRole, "currentValue"}, {ReturnRole, "returns"}, {GoalRole, "goalLink"} };
    }

signals:
    void portfolioUpdated();

private:
    QVector<PortfolioItem> m_data;
};

#endif // PORTFOLIOMODEL_H
