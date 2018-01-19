#include "simulatorshaderobject.h"

SimulatorShaderObject::SimulatorShaderObject(const QString &filename)
    :SimulatorFileObject(filename)
{
    shaderObject = 0;
    info = nullptr;
    next = nullptr;
}

SimulatorShaderObject::~SimulatorShaderObject()
{
    if(shaderObject == 0)
        glDeleteShader(shaderObject);
    shaderObject = 0;
    delete[] info;
    delete next;
}

void SimulatorShaderObject::SetIndex(int index)
{
    this->index = index;
}

int SimulatorShaderObject::GetIndex() const
{
    return this->index;
}

void SimulatorShaderObject::SetShaderType(GLenum type)
{
    this->shaderType = type;
}

void SimulatorShaderObject::GetShaderType() const
{
    return shaderType;
}

void SimulatorShaderObject::SetInfo(char *info)
{
    this->info = info;
}

char* SimulatorShaderObject::GetInfo() const
{
    return this->info;
}

void SimulatorShaderObject::SetCompiled(bool compiled)
{
    this->compiled = compiled;
}

bool SimulatorShaderObject::GetCompiled() const
{
    return this->compiled;
}

void SimulatorShaderObject::SetNext(SimulatorShaderObject *next)
{
    this->next = next;
}

SimulatorShaderObject* SimulatorShaderObject::GetNext() const
{
    return this->next;
}

const QString SimulatorShaderObject::Stringify()
{
    return "Simulator shader object: " + SimulatorFileObject::Stringify();
}
