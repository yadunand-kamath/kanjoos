#ifndef SIPFILTERPROXY_H
#define SIPFILTERPROXY_H
#include <QSortFilterProxyModel>

class SipFilterProxy : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY(QString filterType READ filterType WRITE setFilterType NOTIFY filterTypeChanged)
public:
    explicit SipFilterProxy(QObject *parent = nullptr) : QSortFilterProxyModel(parent) {}
    QString filterType() const { return m_type; }
    void setFilterType(const QString &t) { m_type = t; invalidate(); emit filterTypeChanged(); }

    // --- ADD THIS BLOCK ---
    Q_INVOKABLE void removeRow(int proxyRow) {
        if (proxyRow < 0 || proxyRow >= rowCount()) return;

        // 1. Map the index from the Proxy view to the actual Source Model
        QModelIndex proxyIdx = index(proxyRow, 0);
        QModelIndex sourceIdx = mapToSource(proxyIdx);

        // 2. Call the removal function on the source model dynamically.
        // This works for both UnifiedSipModel and PortfolioModel.
        QMetaObject::invokeMethod(sourceModel(), "removeEntry",
                                  Q_ARG(int, sourceIdx.row()));
    }
    // -----------------------

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override {
        QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        // Ensure 257 matches TypeRole (Qt::UserRole + 1) in both models
        return sourceModel()->data(index, 257 /* TypeRole */).toString() == m_type;
    }

private:
    QString m_type;

signals:
    void filterTypeChanged();
};
#endif