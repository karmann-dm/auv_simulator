#version 420 core

layout (vertices=3) out;

uniform vec4 lens_param;
uniform vec4 c_P[4];
uniform float view_distance;
uniform vec3 cam_center;
uniform float max_visible_rad;
uniform float max_tess_level;


in vec3 world_N[];
in vec3 HSR[];

out vec4 normal[];
out vec3 vHSR[];



void main()
{    
    gl_out[gl_InvocationID].gl_Position=gl_in[gl_InvocationID].gl_Position;
    normal[gl_InvocationID]=vec4(world_N[gl_InvocationID],-dot(world_N[gl_InvocationID],gl_in[gl_InvocationID].gl_Position.xyz));
    vHSR[gl_InvocationID]=HSR[gl_InvocationID];


    const ivec4 ring=ivec4(1,2,0,1);
    vec3 p0=gl_in[ring[gl_InvocationID]].gl_Position.xyz;
    vec3 p1=gl_in[ring[gl_InvocationID+1]].gl_Position.xyz;


    vec3 side_c=0.5*(p0+p1);
    vec3 vv=side_c-cam_center;
    float vvl=length(vv);
    vv=vv/vvl;
    float d=max(vvl,0.001)*1.0;

    vec3 p1_p0=p1-p0;
    p1_p0=p1_p0-dot(p1_p0,vv)*vv;


    float sub_pow=clamp(floor(log2((length(p1_p0)+0.001)/(d*lens_param[3]))+0.5),0.0,min(6.0,max_tess_level));
    gl_TessLevelOuter[gl_InvocationID]=pow(2.0,sub_pow);

    barrier();

    if (gl_InvocationID==0)
    {
        vec3 C=0.33333*(gl_in[0].gl_Position.xyz+gl_in[1].gl_Position.xyz+gl_in[2].gl_Position.xyz);
        float R=max_visible_rad;
        float D=length(C-cam_center);
        if (D>view_distance ||
                dot(c_P[0],vec4(C-R*c_P[0].xyz,1))>0 ||
                dot(c_P[1],vec4(C-R*c_P[1].xyz,1))>0 ||
                dot(c_P[2],vec4(C-R*c_P[2].xyz,1))>0 ||
                dot(c_P[3],vec4(C-R*c_P[3].xyz,1))>0)
        {
            gl_TessLevelOuter[0]=-1.0;
            gl_TessLevelOuter[1]=-1.0;
            gl_TessLevelOuter[2]=-1.0;
            gl_TessLevelInner[0]=-1.0;
        }
        else            
            gl_TessLevelInner[0]=min(gl_TessLevelOuter[0],min(gl_TessLevelOuter[1],gl_TessLevelOuter[2]));
    }
}

