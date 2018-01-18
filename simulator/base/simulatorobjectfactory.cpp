#include "simulatorobjectfactory.h"

unsigned int SimulatorObjectFactory::assignId()
{
    int returnValue = idCounter;
    idCounter++;
    return returnValue;
}

SimulatorFileObject *SimulatorObjectFactory::CreateFileObject(const QString &filename)
{
    SimulatorFileObject *fileObject = new SimulatorFileObject(filename);
    fileObject->SetId(assignId());
    return fileObject;
}
