#version 420 core

uniform float general_scale;
uniform vec3 fluc_s_shift;
uniform vec3 fluc_r_shift;
uniform ivec2 fluc_sr_lod;
uniform vec2 fluc_sr_scale;
uniform float cube_size;


float get_noise3D(in vec3 x);
float get_sum(const in vec3 x, const in int lod, const in float max_freq);


float get_amp(const in float S, const in float R, const in float F)
{
    float sk=0.1*log2(F)+0.2;
    return mix(S,R,sk);
}

float get_relief_shift(const in vec3 x, inout vec3 v, float ps)
{
    float F=1.0/cube_size;
    float max_sr_Fr=1.0/(F*ps);
    float sn=get_sum(x*F+fluc_s_shift,fluc_sr_lod.x,max_sr_Fr);
    float rn=get_sum(x*F+fluc_r_shift,fluc_sr_lod.y,max_sr_Fr);

    vec2 sr=clamp(v.yz+vec2(sn,rn)*fluc_sr_scale,vec2(0.0),vec2(1.0));
    v=vec3(v.x,sr);

    float cutoff=1.0/max(ps,1.0);
    float A=cube_size;
    float sum=0.0;
    for (;F<0.5*cutoff; F*=2.0)
    {
        sum+=get_amp(sr.x,sr.y,F)*general_scale*A*get_noise3D(x*F);
        A*=0.5;
    }
    float fade=clamp(2.0*(cutoff-F)/cutoff,0.0,1.0);
    sum+=fade*get_amp(sr.x,sr.y,F)*general_scale*A*get_noise3D(x*F);
    return sum;
}
