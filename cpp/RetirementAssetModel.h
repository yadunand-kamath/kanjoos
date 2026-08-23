#ifndef RETIREMENTASSETMODEL_H
#define RETIREMENTASSETMODEL_H

#include <QAbstractListModel>
#include <QVector>

struct Asset {
    QString name;
    bool    isLiquid;
    double  value;
    bool    fromPortfolio = false; // true = auto-synced, protected from removal
    QString assetType;             // "" for manual rows; e.g. "Equity", "Debt"...
};

class RetirementAssetModel : public QAbstractListModel {
    Q_OBJECT

    // Derived values — recomputed whenever assets change
    Q_PROPERTY(double lockedRatio    READ lockedRatio  NOTIFY assetsChanged)
    Q_PROPERTY(double totalValueProp READ totalValue   NOTIFY assetsChanged)
    Q_PROPERTY(double liquidValue    READ liquidValue  NOTIFY assetsChanged)
    Q_PROPERTY(double lockedValue    READ lockedValue  NOTIFY assetsChanged)
    Q_PROPERTY(int    assetCount     READ count        NOTIFY assetsChanged)

public:
    enum Roles { NameRole = Qt::UserRole + 1, TypeRole, ValueRole, FromPortfolioRole, AssetTypeRole };

    explicit RetirementAssetModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}
    // Model starts empty; portfolio-linked assets are synced in at runtime.

    // ── QAbstractListModel interface ─────────────────────────────────────────

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        if (parent.isValid()) return 0;
        return m_assets.size();
    }

    // QML-callable count (rowCount() override takes a QModelIndex QML can't construct)
    Q_INVOKABLE int count() const { return m_assets.size(); }

    double totalValue() const {
        double sum = 0;
        for (const auto &a : m_assets) sum += a.value;
        return sum;
    }

    double liquidValue() const {
        double sum = 0;
        for (const auto &a : m_assets) if (a.isLiquid) sum += a.value;
        return sum;
    }

    double lockedValue() const {
        double sum = 0;
        for (const auto &a : m_assets) if (!a.isLiquid) sum += a.value;
        return sum;
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_assets.size()) return {};
        const auto &a = m_assets.at(index.row());
        switch (role) {
        case NameRole:          return a.name;
        case TypeRole:          return a.isLiquid ? "LIQUID" : "LOCKED";
        case ValueRole:         return a.value;
        case FromPortfolioRole: return a.fromPortfolio;
        case AssetTypeRole:     return a.assetType;
        default:                return {};
        }
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role) override {
        if (!index.isValid() || index.row() >= m_assets.size()) return false;
        auto &a = m_assets[index.row()];
        switch (role) {
        case NameRole:  a.name     = value.toString();  break;
        case TypeRole:  a.isLiquid = (value.toString() == "LIQUID"); break;
        case ValueRole: a.value    = value.toDouble();  break;
        default:        return false; // AssetTypeRole is portfolio-owned, not writable
        }
        emit dataChanged(index, index, {role});
        emit assetsChanged();
        return true;
    }

    QHash<int, QByteArray> roleNames() const override {
        static const QHash<int, QByteArray> roles{
            {NameRole,          "name"},
            {TypeRole,          "type"},
            {ValueRole,         "value"},
            {FromPortfolioRole, "fromPortfolio"},
            {AssetTypeRole,     "assetType"}
        };
        return roles;
    }

    // ── CRUD ─────────────────────────────────────────────────────────────────

    // Named setters so QML doesn't need to know role numbers.
    // Portfolio-synced rows are protected — auto-derived fields must not be
    // hand-edited, or they'll silently revert on the next sync anyway.
    Q_INVOKABLE void setName(int row, const QString &name) {
        if (isPortfolioRow(row)) return;
        setData(index(row, 0), name, NameRole);
    }
    Q_INVOKABLE void setLiquid(int row, bool liquid) {
        if (isPortfolioRow(row)) return;
        setData(index(row, 0), liquid ? QString("LIQUID") : QString("LOCKED"), TypeRole);
    }
    Q_INVOKABLE void setValue(int row, double val) {
        if (isPortfolioRow(row)) return;
        setData(index(row, 0), val, ValueRole);
    }

    // No-arg overload for QML call with zero arguments (default args not
    // supported by Qt's meta-object system for Q_INVOKABLE QML calls)
    Q_INVOKABLE void addAsset() {
        addAssetImpl("New Asset", true, 0.0, false, QString());
    }
    Q_INVOKABLE void addAsset(const QString &name, bool isLiquid, double value) {
        addAssetImpl(name, isLiquid, value, false, QString());
    }
    // fromPortfolio=true marks rows that are auto-synced and cannot be removed
    Q_INVOKABLE void addPortfolioAsset(const QString &name, bool isLiquid, double value, const QString &assetType) {
        addAssetImpl(name, isLiquid, value, true, assetType);
    }

    Q_INVOKABLE void removeAsset(int row) {
        if (row < 0 || row >= m_assets.size()) return;
        if (m_assets[row].fromPortfolio) return; // portfolio rows are protected
        beginRemoveRows({}, row, row);
        m_assets.removeAt(row);
        endRemoveRows();
        emit assetsChanged();
    }

    // Sync portfolio-sourced rows: clear all fromPortfolio rows, re-add from list
    Q_INVOKABLE void syncPortfolioAssets(const QVariantList &items) {
        beginResetModel();
        for (int i = m_assets.size() - 1; i >= 0; --i) {
            if (m_assets[i].fromPortfolio) m_assets.removeAt(i);
        }
        for (int i = 0; i < items.size(); ++i) {
            QVariantMap item = items[i].toMap();
            m_assets.insert(i, Asset{
                item["name"].toString(),
                item["isLiquid"].toBool(),
                item["value"].toDouble(),
                true,
                item["assetType"].toString()
            });
        }
        endResetModel();
        emit assetsChanged();
    }

    Q_INVOKABLE bool isPortfolioRow(int row) const {
        if (row < 0 || row >= m_assets.size()) return false;
        return m_assets[row].fromPortfolio;
    }

    Q_INVOKABLE void clearAll() {
        if (m_assets.isEmpty()) return;
        beginResetModel();
        m_assets.clear();
        endResetModel();
        emit assetsChanged();
    }

    // ── Derived property ─────────────────────────────────────────────────────

    // Fraction of total value that is in LOCKED (non-liquid) assets.
    // Returns 0 when no assets exist (safe default: 0% locked → 100% liquid).
    double lockedRatio() const {
        double total = 0, locked = 0;
        for (const auto &a : m_assets) {
            total  += a.value;
            if (!a.isLiquid) locked += a.value;
        }
        return total > 0 ? locked / total : 0.0;
    }

signals:
    void assetsChanged();

private:
    QVector<Asset> m_assets;

    void addAssetImpl(const QString &name, bool isLiquid, double value, bool fromPortfolio, const QString &assetType) {
        beginInsertRows({}, m_assets.size(), m_assets.size());
        m_assets << Asset{name, isLiquid, value, fromPortfolio, assetType};
        endInsertRows();
        emit assetsChanged();
    }
};

#endif
