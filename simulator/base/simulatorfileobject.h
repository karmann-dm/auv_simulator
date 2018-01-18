#ifndef SIMULATORFILEOBJECT_H
#define SIMULATORFILEOBJECT_H

#include "simulatorobject.h"
#include <QtCore>

class SimulatorFileObject : public SimulatorObject
{
private:
    QString fileName;
    int fileSize;
    QFile *fileInstance;

public:
    SimulatorFileObject(const QString &fileName);
    ~SimulatorFileObject();

    QString getFileName() const;
    void setFileName(const QString &fileName);

    bool getIsOpened() const;

    virtual const QString Stringify();
};

#endif // SIMULATORFILEOBJECT_H
