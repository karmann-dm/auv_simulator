#ifndef SIMULATOROBJECT_H
#define SIMULATOROBJECT_H

#include <QString>

class SimulatorObject
{
protected:
    int id;

public:
    SimulatorObject();

    int GetId();
    void SetId(int id);

    virtual const QString Stringify() = 0;
};

#endif // SIMULATOROBJECT_H
