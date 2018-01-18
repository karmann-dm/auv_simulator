#version 420

layout (triangles, equal_spacing, ccw) in;

in vec4 normal[];
in vec3 vHSR[];

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


vec3 get_smooth_pos(vec3 u, vec3 P1, vec3 P2, vec3 P3, vec3 N1, vec3 N2, vec3 N3)
{
    vec3 b210=(2.0*P1+P2-dot(P2-P1,N1)*N1)/3.0;
    vec3 b120=(2.0*P2+P1-dot(P1-P2,N2)*N2)/3.0;
    vec3 b021=(2.0*P2+P3-dot(P3-P2,N2)*N2)/3.0;
    vec3 b012=(2.0*P3+P2-dot(P2-P3,N3)*N3)/3.0;
    vec3 b102=(2.0*P3+P1-dot(P1-P3,N3)*N3)/3.0;
    vec3 b201=(2.0*P1+P3-dot(P3-P1,N1)*N1)/3.0;

    vec3 E=(b210+b120+b021+b012+b102+b201)/6.0;
    vec3 V=(P1+P2+P3)/3.0;
    vec3 b111=E+(E-V)/2.0;

    return P1*u.z*u.z*u.z+P2*u.x*u.x*u.x+P3*u.y*u.y*u.y+
            3.0*b210*u.z*u.z*u.x+
            3.0*b120*u.z*u.x*u.x+
            3.0*b201*u.z*u.z*u.y+
            3.0*b021*u.x*u.x*u.y+
            3.0*b102*u.z*u.y*u.y+
            3.0*b012*u.x*u.y*u.y+
            6.0*b111*u.z*u.x*u.y;
}

void build_srn(const in vec3 N, const in vec2 sr)
{
    srn_val=vec4(sr,acos(N.x),atan(N.y,N.z));
}

void main()
{
    vec3 u=vec3(gl_TessCoord[0],gl_TessCoord[1],gl_TessCoord[2]);

    base_X=gl_in[0].gl_Position.xyz*u.x+
           gl_in[1].gl_Position.xyz*u.y+
           gl_in[2].gl_Position.xyz*u.z;


    vec3 world_N=normalize(normal[0].xyz*u.x+
                           normal[1].xyz*u.y+
                           normal[2].xyz*u.z);

    vec3 cur_hsr=vHSR[0]*u.x+
                 vHSR[1]*u.y+
                 vHSR[2]*u.z;


    //Два варианта сглаживания геометрии (оба не работают):
    //base_X=get_smooth_pos(u,gl_in[0].gl_Position.xyz, gl_in[1].gl_Position.xyz, gl_in[2].gl_Position.xyz,
        //			normal[0].xyz,normal[1].xyz,normal[2].xyz);

    vec3 q=base_X;
    vec3 pr0=q-(dot((q-gl_in[0].gl_Position.xyz),normal[0].xyz))*normal[0].xyz;
    vec3 pr1=q-(dot((q-gl_in[1].gl_Position.xyz),normal[1].xyz))*normal[1].xyz;
    vec3 pr2=q-(dot((q-gl_in[2].gl_Position.xyz),normal[2].xyz))*normal[2].xyz;
    base_X=u.x*pr0+u.y*pr1+u.z*pr2;



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

