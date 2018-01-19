#include "glslprogram.h"

GLSLProgram::GLSLProgram()
{
    program = 0;
    linkInfo = nullptr;
    linked = false;
    shaderObjects = nullptr;
    nextShaderIndex = 0;
}

SimulatorShaderObject* GLSLProgram::AddShaderCode(const QString &code, GLenum type)
{
    SimulatorShaderObject *obj = new SimulatorShaderObject;
    obj->SetIndex(nextShaderIndex++);
    obj->SetShaderType(type);
    obj->next = shaderObjects;
    obj->SetInfo(nullptr);
    obj->SetCompiled(false);
    obj->SetShaderObject(glCreateShader(type));

    glShaderSource(obj->shaderObject, 1, code.toUtf8().constData(), NULL);
    glCompileShader(obj->shaderObject);

    GLint result;
    glGetShaderiv(obj->shaderObject, GL_COMPILE_STATUS, &result);
    obj->SetCompiled(result == GL_TRUE);

    glGetShaderiv(obj->shaderObject, GL_INFO_LOG_LENGTH, &result);
    if(result > 0) {
        char *info = new char[result];
        glGetShaderInfoLog(obj->shaderObject, result, NULL, obj->GetInfo());
    } else
        obj->SetInfo(NULL);
    return obj;
}

SimulatorShaderObject* GLSLProgram::AddShaderFile(const QString &code, GLenum type)
{
    QFile file(code);
    if(file.open(QIODevice::ReadWrite)) {
        QI
    }
}
