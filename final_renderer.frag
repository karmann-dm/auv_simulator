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

out vec4 fColor;

const float zN=0.25;
const float zF=5000.0;

vec3 get_ray_color(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c);
vec3 get_ray_color(const in vec3 r_c, const in vec3 r_dir);

vec3 get_point_pos(const in vec2 c, const in float w)
{
    vec3 dv=w*vec3((c-cam_screen_size*0.5)/lens_param[2],1.0);
    return cam_right*dv.x+cam_up*dv.y+cam_front*dv.z+cam_center;
}

void main()
{
    ivec2 cur_c=ivec2(screen_x);
    vec3 color_data=texelFetch(dtex,cur_c,0).xyz;
    vec4 normal_data=texelFetch(srn_tex,cur_c,0);

    vec3 N=normal_data.xyz;
    vec3 world_X=get_point_pos(screen_x,normal_data.w);
    vec3 rdir=normalize(get_point_pos(screen_x,1.0)-cam_center);


    vec3 col=normal_data.w<0.01?get_ray_color(cam_center,rdir):
                                get_ray_color(cam_center,rdir,N,world_X,color_data);

    fColor=vec4(col,1.0);
    float D=(zF+zN-2.0*zN*zF/normal_data.w)/(zF-zN);
    if(normal_data.w < 0.01)
        gl_FragDepth = 0.9999;
    else
        gl_FragDepth=(D+1.0)*0.5;
}
