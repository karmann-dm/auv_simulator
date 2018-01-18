#version 420

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec2 permute(vec2 x){return mod(((x*34.0)+1.0)*x, 289.0);}

vec3 fade(in vec3 t)
{
    return t*t*t*(t*(t*6.0-vec3(15.0))+vec3(10.0));
}

float grad(const in float hash, const in vec3 x)
{
    float h=mod(hash,12.0);
    float u=h<7.5?x.x:x.y;
    float v=h<3.5?x.y:x.z;
    return (mod(h,2.0)<0.5?u:-u)+((mod(h,4.0)/2.0<0.5)?v:-v);
}

vec4 grad(const in vec4 hash, const in vec4 x, const in vec4 y, const in vec4 z)
{
    vec4 h=mod(hash,12.0);
    vec4 u=vec4(h.x<7.5?x.x:y.x, h.y<7.5?x.y:y.y, h.z<7.5?x.z:y.z, h.w<7.5?x.w:y.w);
    vec4 v=vec4(h.x<3.5?y.x:z.x, h.y<3.5?y.y:z.y, h.z<3.5?y.z:z.z, h.w<3.5?y.w:z.w);
    vec4 half=vec4(0.5);
    bvec4 lv=lessThan(mod(h,2.0),half);
    bvec4 rv=lessThan(mod(h,4.0)/2.0,half);
    return vec4((lv.x?u.x:-u.x)+(rv.x?v.x:-v.x),
                (lv.y?u.y:-u.y)+(rv.y?v.y:-v.y),
                (lv.z?u.z:-u.z)+(rv.z?v.z:-v.z),
                (lv.w?u.w:-u.w)+(rv.w?v.w:-v.w));
}

float get_noise3D(in vec3 x)
{
    vec3 xf=floor(x);
    x=x-xf;
    vec3 u=fade(x);

    vec2 P1=permute(vec2(xf.x,xf.x+1));
    vec2 A=P1+xf.yy;

    vec4 P2=permute(vec4(A,A+1.0));
    vec4 AB=P2+xf.zzzz;

    vec4 P3=permute(AB);
    vec4 P4=permute(AB+1.0);

    vec4 GX=vec4(x.x,x.x-1.0,x.x,x.x-1.0);
    vec4 GY=vec4(x.yy,x.y-1.0,x.y-1.0);
    vec4 GZ=vec4(x.z);
    vec4 GV_A=grad(P3,GX,GY,GZ);

    GZ=vec4(x.z-1.0);
    vec4 GV_B=grad(P4,GX,GY,GZ);

    vec4 IL0=mix(vec4(GV_A.xz,GV_B.xz),vec4(GV_A.yw,GV_B.yw),u.x);
    vec2 IL1=mix(IL0.xz,IL0.yw,u.y);
    return mix(IL1.x,IL1.y,u.z);
}

float get_sum(const in vec3 x, const in int lod)
{
    float A=1.0;
    float F=1.0;
    float H=0.0;

    for (int i=0; i<lod; i++)
    {
        H+=A*get_noise3D(x*F);
        F*=2.0;
        A*=0.5;
    }
    return H;
}

float get_sum(const in vec3 x, const in int lod, const in float max_freq)
{
    float A=1.0;
    float H=0.0;
    float F;

    float max_fr=float(1<<(lod-1));
    float cutoff=max_freq<max_fr?max_freq:max_fr;

    for (F=1.0; F<0.5*cutoff; F*=2.0)
    {
        H+=A*get_noise3D(x*F);
        A*=0.5;
    }
    float fade=clamp(2.0*(cutoff-F)/cutoff,0.0,1.0);
    H+=fade*A*get_noise3D(x*F);
    return H;
}

float get_turbulence(const in vec3 x, const in int lod)
{
    float A=1.0;
    float F=1.0;
    float H=0.0;

    for (int i=0; i<lod; i++)
    {
        H+=abs(A*get_noise3D(x*F));
        F*=2.0;
        A*=0.5;
    }
    return H;
}

float get_turbulence(const in vec3 x, const in int lod, const in float max_freq)
{
    float A=1.0;
    float H=0.0;
    float F;

    float max_fr=float(1<<(lod-1));
    float cutoff=max_freq<max_fr?max_freq:max_fr;

    for (F=1.0; F<0.5*cutoff; F*=2.0)
    {
        H+=abs(A*get_noise3D(x*F));
        A*=0.5;
    }
    float fade=clamp(2.0*(cutoff-F)/cutoff,0.0,1.0);
    fade=fade<0.0?0.0:(fade>1.0?1.0:fade);
    H+=fade*abs(A*get_noise3D(x*F));
    return H;
}
