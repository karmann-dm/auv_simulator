#ifndef GLSLPROGRAM_H
#define GLSLPROGRAM_H

#include "simulator/base/simulatorobject.h"
#include "simulator/base/simulatorshaderobject.h"

class GLSLProgram : SimulatorObject
{
private:
    GLuint program;
    char* linkInfo;
    bool linked;
    SimulatorShaderObject *shaderObjects;
    int nextShaderIndex;

    static void shader_type_to_string(char *str, GLenum type);

    void Free();
public:
    GLSLProgram();
    ~GLSLProgram();

    SimulatorShaderObject* AddShaderCode(const QString &code, GLenum type);
    SimulatorShaderObject* AddShaderFile(const QString &code, GLenum type);
    void DeleteShader(int index);
    void DeleteAllShaders();

    void PrintShaderInfo(int index, const QString &filename);
    void PrintAllShadersInfo(const QString &filename);

    bool LinkProgram();
    void PrintProgramInfo(const QString &filename);

    void Bind();
    void Unbind();

    GLuint GetProgram() const;
};

#endif // GLSLPROGRAM_H
