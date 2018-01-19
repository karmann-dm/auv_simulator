#ifndef SIMULATORSHADEROBJECT_H
#define SIMULATORSHADEROBJECT_H

#include "simulatorfileobject.h"
#include <GL/glew.h>

class SimulatorShaderObject : public SimulatorFileObject
{
private:
    int index;
    GLuint shaderObject;
    GLenum shaderType;
    char* info;
    bool compiled;
    SimulatorShaderObject *next;

public:
    SimulatorShaderObject(const QString &filename);
    ~SimulatorShaderObject();

    void SetIndex(int index);
    int GetIndex() const;

    void SetShaderType(GLenum type);
    GLenum GetShaderType() const;

    void SetShaderObject(GLuint shaderObject);
    GLuint GetShaderObject() const;

    void SetInfo(char *info);
    char* GetInfo() const;

    void SetCompiled(bool compiled);
    bool GetCompiled() const;

    void SetNext(SimulatorShaderObject *next);
    SimulatorShaderObject* GetNext() const;

    virtual const QString Stringify();
};

#endif // SIMULATORSHADEROBJECT_H
