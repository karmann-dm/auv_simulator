#version 420 core

in vec3 vertex_pos;
in vec3 vertex_normal;
in vec3 vertex_hsr;

out vec3 world_N;
out vec3 HSR;

void main()
{
    gl_Position=vec4(vertex_pos,1.0);
    world_N=vertex_normal;
    HSR=vertex_hsr;
}
