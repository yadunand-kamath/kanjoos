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

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override {
        QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        return sourceModel()->data(index, 257 /* TypeRole */).toString() == m_type;
    }
private:
    QString m_type;
signals:
    void filterTypeChanged();
};
#endif