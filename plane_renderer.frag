#version 430 core

uniform sampler2D dtex;
uniform sampler2D srn_tex;

uniform vec4 lens_param; //fov_y, fov_x, focus, res
uniform vec3 cam_right;
uniform vec3 cam_up;
uniform vec3 cam_front;
uniform vec3 cam_center;
uniform vec2 cam_screen_size;
uniform float view_distance;

in vec2 screen_x;

layout(location=0) out vec3 colors;
layout(location=1) out vec4 normals;

vec3 sand_get_composite(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN);
vec3 get_texture_color(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale);

vec4 get_tex_w(const in ivec2 c)
{
    ivec2 min_c=ivec2(0,0);
    ivec2 max_c=ivec2(int(cam_screen_size.x-0.5),int(cam_screen_size.y-0.5));
    return vec4(texelFetch(dtex,clamp(ivec2(c.x-1,c.y),min_c,max_c),0).w,
                texelFetch(dtex,clamp(ivec2(c.x+1.0,c.y),min_c,max_c),0).w,
                texelFetch(dtex,clamp(ivec2(c.x,c.y-1.0),min_c,max_c),0).w,
                texelFetch(dtex,clamp(ivec2(c.x,c.y+1.0),min_c,max_c),0).w);
}

vec3 get_point_pos(const in vec2 c, const in float w)
{
    vec3 dv=w*vec3((c-cam_screen_size*0.5)/lens_param[2],1.0);
    return cam_right*dv.x+cam_up*dv.y+cam_front*dv.z+cam_center;
}
vec3 face_normal(const in vec3 p0, const in vec3 p1, const in vec3 p2)
{
    vec3 v0=p1-p0;
    vec3 v1=p2-p0;
    return normalize(cross(v0,v1));
}

vec3 compute_normal(const in vec4 nw, const in float w)
{
    vec3 c=get_point_pos(screen_x,w);
    vec3 l=nw.x<0.01?vec3(0.0,0.0,0.0):get_point_pos(vec2(screen_x.x-1.0,screen_x.y),nw.x);
    vec3 r=nw.y<0.01?vec3(0.0,0.0,0.0):get_point_pos(vec2(screen_x.x+1.0,screen_x.y),nw.y);
    vec3 b=nw.z<0.01?vec3(0.0,0.0,0.0):get_point_pos(vec2(screen_x.x,screen_x.y-1.0),nw.z);
    vec3 t=nw.w<0.01?vec3(0.0,0.0,0.0):get_point_pos(vec2(screen_x.x,screen_x.y+1.0),nw.w);

    vec3 N=vec3(0.0,0.0,0.0);
    if (nw.x>=0.01 && nw.z>=0.01) N+=face_normal(c,l,b);
    if (nw.z>=0.01 && nw.y>=0.01) N+=face_normal(c,b,r);
    if (nw.y>=0.01 && nw.w>=0.01) N+=face_normal(c,r,t);
    if (nw.w>=0.01 && nw.x>=0.01) N+=face_normal(c,t,l);
    return normalize(N);
}


void main()
{
    ivec2 cur_c=ivec2(screen_x);
    vec4 cur_data=texelFetch(dtex,cur_c,0);    
    vec3 dir_v=normalize(get_point_pos(screen_x, 1.0)-cam_center);
    if (cur_data.w<0.01)
    {
        colors=vec3(0.0,0.0,0.0);
        normals=vec4(0.0,0.0,0.0,0.0);
        return;
    }
    vec4 srn=texelFetch(srn_tex,cur_c,0);
    vec3 wN=vec3(cos(srn.z),sin(srn.z)*sin(srn.w),sin(srn.z)*cos(srn.w));
    vec4 w=get_tex_w(cur_c);
    
    vec3 Nv=compute_normal(w,cur_data.w);
    vec3 world_X=get_point_pos(screen_x, cur_data.w);

    float pfar=length(world_X-cam_center);        
    float ps=pfar*lens_param.w;//surf_cos;            

    colors=get_texture_color(cur_data.xyz,srn.xy,wN,ps);
    normals=vec4(Nv,cur_data.w);
}
