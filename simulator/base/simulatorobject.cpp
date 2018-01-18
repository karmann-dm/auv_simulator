#include "simulatorobject.h"

SimulatorObject::SimulatorObject()
{}

int SimulatorObject::GetId()
{
    return this->id;
}

void SimulatorObject::SetId(int id)
{
    this->id = id;
}
