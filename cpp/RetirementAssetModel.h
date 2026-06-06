#ifndef RETIREMENTASSETMODEL_H
#define RETIREMENTASSETMODEL_H

#include <QAbstractListModel>

struct Asset {
    QString name;
    bool isLiquid;
    double value;
};

class RetirementAssetModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { NameRole = Qt::UserRole + 1, TypeRole, ValueRole };

    explicit RetirementAssetModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        m_assets << Asset{"EPF/PPF", false, 500000} << Asset{"Mutual Funds", true, 1200000};
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_assets.size(); }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_assets.size()) return QVariant();
        const auto &asset = m_assets.at(index.row());
        if (role == NameRole) return asset.name;
        if (role == TypeRole) return asset.isLiquid ? "LIQUID" : "LOCKED";
        if (role == ValueRole) return asset.value;
        return QVariant();
    }

    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roles;
        roles[NameRole] = "name";
        roles[TypeRole] = "type";
        roles[ValueRole] = "value";
        return roles;
    }

private:
    QList<Asset> m_assets;
};

#endif