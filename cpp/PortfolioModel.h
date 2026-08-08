#ifndef PORTFOLIOMODEL_H
#define PORTFOLIOMODEL_H

#include <QAbstractListModel>
#include <QVector>

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
        m_data << PortfolioItem{"Equity", "Bluechip Stocks", "Domestic", "Stock", "Largecap", 850000.0, 1120000.0, "Retirement"};
        m_data << PortfolioItem{"Equity", "Nasdaq 100", "International", "ETF", "Largecap", 400000.0, 525000.0, "Retirement"};
        m_data << PortfolioItem{"Equity", "Midcap Fund", "Domestic", "Mutual Fund", "Midcap", 200000.0, 185000.0, "Home Downpayment"};

        // DEBT
        m_data << PortfolioItem{"Debt", "HDFC Fixed Deposit", "Domestic", "FD/RD", "-", 500000.0, 535000.0, "Emergency Fund"};
        m_data << PortfolioItem{"Debt", "Employee Provident Fund", "Domestic", "Govt. Scheme", "-", 1200000.0, 1200000.0, "Retirement"};
        m_data << PortfolioItem{"Debt", "Sovereign Gold Bond", "Domestic", "Bond", "-", 150000.0, 180000.0, "World Tour"};

        // REAL ESTATE
        m_data << PortfolioItem{"Real Estate", "Ancestral Land", "Domestic", "Other", "-", 2500000.0, 4800000.0, "Retirement"};
        m_data << PortfolioItem{"Real Estate", "REIT - Embassy", "Domestic", "REITs", "-", 100000.0, 112000.0, "Home Downpayment"};

        // COMMODITY
        m_data << PortfolioItem{"Commodity", "Physical Gold", "Domestic", "Physical", "-", 250000.0, 380000.0, "Emergency Fund"};

        // CRYPTO
        m_data << PortfolioItem{"Crypto", "Bitcoin", "-", "-", "-", 150000.0, 245000.0, "None"};
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.count(); }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return QVariant();
        const auto &item = m_data.at(index.row());

        switch (role) {
        case TypeRole: return item.assetType;
        case NameRole: return item.name;
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

    Q_INVOKABLE double getTotalValue(QString type) {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (type == "Total" || item.assetType == type) sum += item.currentValue;
        }
        return sum;
    }

    // Helper for GoalModel
    double getFundedAmountForGoal(const QString &goalName) {
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
