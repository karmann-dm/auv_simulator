#define tex_r0 0.5
#define tex_s0 0.4
#define tex_line_delta 0.1
#define tex_h_bwidth 0.05
#define tex_bwidth 0.01

float sand_get_composite_h(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN);
float sand_get_h(const in vec3 x, const in float scale);
float cStone_GetH(const in vec3 x, const in float scale);
vec3 stone_compute_color(const in vec3 x, const in float scale, const in float bioshift);
vec3 sand_get_composite(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN);


float sand_bondary_distance(vec2 sr)
{
    vec2 dv=normalize(vec2(tex_s0,-tex_r0));
    vec2 nv=vec2(-dv.y,dv.x);
    vec2 dvc=vec2(0.5*tex_s0,0.5*tex_r0);
    float pdv_proj=dot(sr-dvc,dv); //Координата на базовой линии границы
    float pdn_proj=dot(sr-dvc,nv); //Рассотяние до базовой линии границы

    float rx=pdv_proj*9.42478/length(vec2(tex_s0,-tex_r0)); //Координата на оси для косинуса
    float cos_h=smoothstep(-4.7124,-3.1416,rx)*(1.0-smoothstep(3.1416,4.7124,rx))*tex_line_delta;
    float cdh=cos(rx)*cos_h;
    return pdn_proj-cdh;
}

float get_texture_h(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale)
{
    float d_to_sand=sand_bondary_distance(sr);
    float stone_k=smoothstep(-tex_h_bwidth,tex_h_bwidth,d_to_sand);
    float sand_h=stone_k<0.99?sand_get_composite_h(x,scale,0.0,0.0,wN):0.0;
    float stone_h=stone_k>0.01?cStone_GetH(x,scale):0.0;
    return mix(sand_h,stone_h,stone_k);
}

float get_texture_h_for_depth(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale)
{
    float d_to_sand=sand_bondary_distance(sr);
    float stone_k=smoothstep(-tex_h_bwidth,tex_h_bwidth,d_to_sand);
    float sand_h=stone_k<0.99?sand_get_h(x,scale):0.0;
    float stone_h=stone_k>0.01?cStone_GetH(x,scale):0.0;
    return mix(sand_h,stone_h,stone_k);
}

vec3 get_texture_color(const in vec3 x, const in vec2 sr, const in vec3 wN, const in float scale)
{
    float d_to_sand=sand_bondary_distance(sr);
    float stone_k=smoothstep(-tex_bwidth,tex_h_bwidth,d_to_sand);
    vec3 sand_c=stone_k<0.99?sand_get_composite(x,scale,0.0,0.0,wN):vec3(0.0);
    vec3 stone_c=stone_k>0.01?stone_compute_color(x,scale,0.0):vec3(0.0);
    return mix(sand_c,stone_c,stone_k);
}
