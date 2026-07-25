#ifndef UNIFIEDSIPMODEL_H
#define UNIFIEDSIPMODEL_H

#include <QAbstractListModel>
#include <QVector>

struct SipItem {
    QString assetType; // Equity, Debt, RealEstate, Commodity, Crypto
    QString name;
    QString market;    // Only for Equity
    QString subType;   // The "Type" column
    QString category;  // Only for Equity
    QString goalName;
    double amount;
};

class UnifiedSipModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { TypeRole = Qt::UserRole + 1, NameRole, MarketRole, SubTypeRole, CategoryRole, GoalRole, AmountRole };

    explicit UnifiedSipModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        m_data << SipItem{"Equity", "Nifty Index", "Domestic", "Mutual Fund", "Largecap", "Retirement", 15000.0};
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.count(); }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return QVariant();
        const auto &item = m_data.at(index.row());
        switch (role) {
        case TypeRole: return item.assetType;
        case NameRole: return item.name;
        case MarketRole: return item.market;
        case SubTypeRole: return item.subType;
        case CategoryRole: return item.category;
        case GoalRole: return item.goalName;
        case AmountRole: return item.amount;
        default: return QVariant();
        }
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role) override {
        if (!index.isValid()) return false;
        auto &item = m_data[index.row()];
        bool changed = false;
        switch (role) {
        case NameRole: item.name = value.toString(); changed = true; break;
        case MarketRole: item.market = value.toString(); changed = true; break;
        case SubTypeRole: item.subType = value.toString(); changed = true; break;
        case CategoryRole: item.category = value.toString(); changed = true; break;
        case GoalRole: item.goalName = value.toString(); changed = true; break;
        case AmountRole: item.amount = value.toDouble(); changed = true; break;
        }
        if (changed) {
            emit dataChanged(index, index, {role});
            emit sipUpdated();
            return true;
        }
        return false;
    }

    Q_INVOKABLE void addEntry(QString type) {
        int row = m_data.count();
        beginInsertRows(QModelIndex(), row, row);
        m_data << SipItem{type, "New " + type, "Domestic", "Other", "-", "None", 0.0};
        endInsertRows();
        emit sipUpdated();
    }

    bool removeRows(int row, int count, const QModelIndex &parent = QModelIndex()) override {
        beginRemoveRows(parent, row, row + count - 1);
        m_data.removeAt(row);
        endRemoveRows();
        emit sipUpdated(); // Force Goals table to refresh
        return true;
    }

    Q_INVOKABLE double getTotal(QString type) {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (type == "Total" || item.assetType == type) sum += item.amount;
        }
        return sum;
    }

    Q_INVOKABLE double getGoalSum(const QString &goalName) {
        double sum = 0;
        for (const auto &item : std::as_const(m_data)) {
            if (item.goalName == goalName) sum += item.amount;
        }
        return sum;
    }

    // Returns every entry of a given assetType as {name, market, subType, category, amount}
    // so QML can group/aggregate by whichever field a chart needs (category, subType, market, or name).
    Q_INVOKABLE QVariantList getEntries(const QString &assetType) const {
        QVariantList list;
        for (const auto &item : std::as_const(m_data)) {
            if (item.assetType != assetType) continue;
            QVariantMap row;
            row["name"] = item.name;
            row["market"] = item.market;
            row["subType"] = item.subType;
            row["category"] = item.category;
            row["amount"] = item.amount;
            list.append(row);
        }
        return list;
    }

    QHash<int, QByteArray> roleNames() const override {
        return { {TypeRole, "assetType"}, {NameRole, "name"}, {MarketRole, "market"},
                {SubTypeRole, "subType"}, {CategoryRole, "category"},
                {GoalRole, "goalLink"}, {AmountRole, "amount"} };
    }

signals:
    void sipUpdated();

private:
    QVector<SipItem> m_data;
};

#endif