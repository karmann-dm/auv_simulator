#version 330 core

uniform vec2 cam_screen_size;

in vec3 vertex_pos;

out vec2 screen_x;

void main()
{
    screen_x=0.5*(vertex_pos.xy+1.0)*cam_screen_size;
    gl_Position=vec4(vertex_pos,1.0);
}
