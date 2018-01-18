#version 420

layout (triangles, equal_spacing, ccw) in;

in vec4 normal[];
in vec3 vHSR[];

uniform vec3 cam_right;
uniform vec3 cam_up;
uniform vec3 cam_front;
uniform vec3 cam_center;
uniform vec2 cam_screen_size;
uniform vec2 cam_accuracy;
uniform float view_distance;

const float zN=0.25;
const float zF=5000.0;

out float depth;

float get_relief_shift(const in vec3 x, inout vec3 v, float ps);
float get_texture_h_for_depth(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale);

vec4 get_normalized_coords(const in vec3 p)
{
    const float l=-3.141592654;
    const float r=-l;
    const float b=l*0.5;
    const float t=-b;
    const float f=view_distance;

    return vec4(p.x*2.0/(r-l)-(r+l)/(r-l),
                p.y*2.0/(t-b)-(t+b)/(t-b),
                p.z*2.0/f-1.0,1.0);
}

void main()
{
    vec3 u=vec3(gl_TessCoord[0],gl_TessCoord[1],gl_TessCoord[2]);

    vec3 base_X=gl_in[0].gl_Position.xyz*u.x+
                gl_in[1].gl_Position.xyz*u.y+
                gl_in[2].gl_Position.xyz*u.z;


    vec3 world_N=normalize(normal[0].xyz*u.x+
                           normal[1].xyz*u.y+
                           normal[2].xyz*u.z);

    vec3 cur_hsr=vHSR[0]*u.x+
                 vHSR[1]*u.y+
                 vHSR[2]*u.z;


    vec3 q=base_X;
    vec3 pr0=q-(dot((q-gl_in[0].gl_Position.xyz),normal[0].xyz))*normal[0].xyz;
    vec3 pr1=q-(dot((q-gl_in[1].gl_Position.xyz),normal[1].xyz))*normal[1].xyz;
    vec3 pr2=q-(dot((q-gl_in[2].gl_Position.xyz),normal[2].xyz))*normal[2].xyz;
    base_X=u.x*pr0+u.y*pr1+u.z*pr2;

    float surf_cos=max(dot(normalize(cam_center-base_X),world_N),0.4);
    float ps=max(cam_accuracy[1],length(base_X-cam_center)*cam_accuracy[0]/surf_cos);

    float relief_noise=get_relief_shift(base_X,cur_hsr,ps);    

    float tex_noise=get_texture_h_for_depth(base_X,cur_hsr.yz,world_N,ps);

    vec3 world_X=base_X+world_N*(relief_noise+tex_noise);


    vec3 ray=world_X-cam_center;

    depth=length(ray);
    ray/=depth;
    depth=clamp(depth,0.0,view_distance);

    vec3 ray_xy=ray-dot(ray,cam_up)*cam_up;
    float rl=length(ray_xy);
    ray_xy=rl<0.00001?cam_front:ray_xy/rl;
    float xa=acos(dot(cam_front,ray_xy));
    if (dot(ray_xy,cam_right)<0.0) xa=-xa;

    float ya=acos(dot(ray,ray_xy));
    if (dot(ray,cam_up)<0.0) ya=-ya;

    gl_Position=get_normalized_coords(vec3(xa,ya,depth));
}

