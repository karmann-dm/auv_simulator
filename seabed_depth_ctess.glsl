#version 420 core

layout (vertices=3) out;

uniform float view_distance;
uniform vec3 cam_center;
uniform vec2 cam_accuracy;

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

    float ps=max(d*cam_accuracy[0],cam_accuracy[1]);
    //float ps=max(d*0.01745,0.1);
    float sub_pow=clamp(floor(max(log2((length(p1_p0)+0.001)/ps)+0.5,0.0)),0.0,6.0);

    gl_TessLevelOuter[gl_InvocationID]=pow(2.0,sub_pow);

    barrier();

    if (gl_InvocationID==0)
    {
        vec3 C=0.33333*(gl_in[0].gl_Position.xyz+gl_in[1].gl_Position.xyz+gl_in[2].gl_Position.xyz);        
        float D=length(C-cam_center);
        if (D>view_distance)
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

