#ifndef SIMULATOROBJECTFACTORY_H
#define SIMULATOROBJECTFACTORY_H

#include <QtCore>
#include "simulatorfileobject.h"

class SimulatorObjectFactory
{
private:
    unsigned int idCounter = 0;

    SimulatorObjectFactory() {}
    ~SimulatorObjectFactory() {}

    SimulatorObjectFactory(SimulatorObjectFactory const&) = delete;
    SimulatorObjectFactory& operator= (SimulatorObjectFactory const&) = delete;

    unsigned int assignId();
public:
    static SimulatorObjectFactory& GetInstance()
    {
        static SimulatorObjectFactory s;
        return s;
    }

    SimulatorFileObject* CreateFileObject(const QString &filename);
};

#endif // SIMULATOROBJECTFACTORY_H
