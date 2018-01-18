#include "simulatorfileobject.h"

SimulatorFileObject::SimulatorFileObject(const QString &fileName)
{
    this->fileName = fileName;
    fileInstance = new QFile(fileName);
    fileInstance->open(QIODevice::ReadWrite);
}

SimulatorFileObject::~SimulatorFileObject()
{
    if(fileInstance)
        delete fileInstance;
}

QString SimulatorFileObject::getFileName() const
{
    return this->fileName;
}

void SimulatorFileObject::setFileName(const QString &fileName)
{
    this->fileName = fileName;
}

bool SimulatorFileObject::getIsOpened() const
{
    return fileInstance->isOpen();
}

const QString SimulatorFileObject::Stringify()
{
    return "Simulator file object, filename = " + fileName + ", opened: " + QString::number(getIsOpened());
}

