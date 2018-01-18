#version 420 core

in vec2 vertex_sd_pos;

uniform vec3 tP[3];
uniform vec3 tN[3];
uniform vec3 tHSR[3];


uniform vec4 lens_param;
uniform vec3 cam_right;
uniform vec3 cam_up;
uniform vec3 cam_front;
uniform vec3 cam_center;
uniform vec2 cam_screen_size;

const float zN=0.25;
const float zF=5000.0;


out vec3 world_X;
out vec4 srn_val;
out vec3 base_X;


float get_relief_shift(const in vec3 x, inout vec3 v, float ps);
float get_texture_h(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale);


void build_srn(const in vec3 N, const in vec2 sr)
{
    srn_val=vec4(sr,acos(N.x),atan(N.y,N.z));
}

void main()
{
    vec3 u=vec3(0.0,vertex_sd_pos.x,vertex_sd_pos.y);
    u.x=1.0-u.y-u.z;

    base_X=tP[0]*u.x+tP[1]*u.y+tP[2]*u.z;
    vec3 world_N=normalize(tN[0]*u.x+tN[1]*u.y+tN[2]*u.z);


    vec3 q=base_X;
    vec3 pr0=q-(dot((q-tP[0]),tN[0]))*tN[0];
    vec3 pr1=q-(dot((q-tP[1]),tN[1]))*tN[1];
    vec3 pr2=q-(dot((q-tP[2]),tN[2]))*tN[2];
    base_X=u.x*pr0+u.y*pr1+u.z*pr2;


    vec3 cur_hsr=tHSR[0]*u.x+tHSR[1]*u.y+tHSR[2]*u.z;

    float surf_cos=max(dot(normalize(cam_center-base_X),world_N),0.4);
    float ps=length(base_X-cam_center)*lens_param.w/surf_cos;

    float relief_noise=get_relief_shift(base_X,cur_hsr,ps);
    build_srn(world_N,cur_hsr.yz);

    float tex_noise=get_texture_h(base_X,cur_hsr.yz,world_N,ps);

    world_X=base_X+world_N*(relief_noise+tex_noise);

    vec3 pos=world_X-cam_center;
    pos=vec3(dot(pos,cam_right),dot(pos,cam_up),dot(pos,cam_front));

    float aspect=cam_screen_size[0]/cam_screen_size[1];
    float f=1.0/tan(0.5*lens_param[0]*3.141592654/180.0);
    gl_Position=vec4(pos.x*f/aspect, pos.y*f, pos.z*(zF+zN)/(zF-zN)+2*(zF*zN)/(zN-zF),pos.z);
}

