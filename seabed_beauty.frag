#version 430 core

#define max_lights 5
#define ambient_kf 0.15

uniform vec4 sun_param; //Зенит, азимут, яркость, фоновое освещение
uniform vec3 zcol; //Цвет неба в зените, последний компонент - функция F(0, угол солнца от зенита)
uniform float turbidity; //Мутность атмосферы

uniform int lights_n;
uniform vec4 lights_param[max_lights]; //Положение, яркость
uniform vec3 lights_dir[max_lights]; //Направление
uniform vec4 lights_att[max_lights]; //Расстояние проникновения, степень затухания с расст., угол, степень затухания с углом

uniform float sea_level; //Уровень моря
uniform int wsurf_norm_noise_lod; //Уровень возмущающего отклонения нормалей водной поверхности
uniform vec4 water_param; //Макс отклонение нормали, макс период волн, яркость блика, степень блика
uniform vec4 water_extinction; //Степень затухания красной, синий и зелёной комп, расстояние полного затухания
uniform vec2 water_anim; //Радиус движения воды, угол поворота

uniform vec4 sky_param; //Высота, максимальный период, порог, макс плотность
uniform int sky_lod;

uniform vec4 lens_param; //fov_y, fov_x, focus, res
uniform vec3 cam_center;

float get_sum(const in vec3 x, const in int lod, const in float max_freq);

vec4 get_cloud_color(const in vec3 r_c, const in vec3 r_dir)
{
    if (abs(r_dir.z)<0.01) return vec4(0.0,0.0,0.0,0.0);
    float t=(sky_param[0]-r_c.z)/r_dir.z;
    if (t<0.0) return vec4(0.0,0.0,0.0,0.0);
    vec3 ip=r_c+t*r_dir;

    float ps=length(ip-cam_center)*lens_param.w;
    float nv=get_sum(ip/sky_param[1],sky_lod,sky_param[1]/ps);

    //float dens=smoothstep(sky_param[2],sky_param[3],nv);
    float dens=clamp((nv-sky_param[2])/(sky_param[3]-sky_param[2]),0.0,1.0);
    return vec4(1.0,1.0,1.0,dens);
}


vec3 sky_model_func (const float t, const float cosA, const float cosG)
{
    float g=acos(cosG);
    float cosG2=cosG*cosG;

    float aY= 0.17872*t-1.46303;
    float bY=-0.35540*t+0.42749;
    float cY=-0.02266*t+5.32505;
    float dY= 0.12064*t-2.57705;
    float eY=-0.06696*t+0.37027;
    float ax=-0.01925*t-0.25922;
    float bx=-0.06651*t+0.00081;
    float cx=-0.00041*t+0.21247;
    float dx=-0.06409*t-0.89887;
    float ex=-0.00325*t+0.04517;
    float ay=-0.01669*t-0.26078;
    float by=-0.09495*t+0.00921;
    float cy=-0.00792*t+0.21023;
    float dy=-0.04405*t-1.65369;
    float ey=-0.01092*t+0.05291;

    return vec3((1.0+aY*exp(bY/cosA))*(1.0+cY*exp(dY*g)+eY*cosG2),
                (1.0+ax*exp(bx/cosA))*(1.0+cx*exp(dx*g)+ex*cosG2),
                (1.0+ay*exp(by/cosA))*(1.0+cy*exp(dy*g)+ey*cosG2));
}

vec3  sky_Yxy_color(const float t, const float cosA, float cosG, float cosAS)
{
    vec3 col=zcol*sky_model_func(t, cosA, cosG)/sky_model_func(t,1.0,cosAS);
    col.x*=smoothstep(0.0, 0.1, cosAS);
    return col;
}


vec3 get_sky_color(const in vec3 r_c, const in vec3 r_dir)
{
    vec3 sun_v=vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),sin(sun_param.x));
    float cosG=dot(sun_v,r_dir);
    float cosA=max(r_dir.z,0.01);
    vec3 SC=sky_Yxy_color(turbidity,cosA,cosG,sun_v.z);

    SC.x=1.0-exp(-SC.x/25.0);

    float r=SC.x/SC.z;
    vec3 XYZ;
    XYZ.x=SC.y*r;
    XYZ.y=SC.x;
    XYZ.z=r-XYZ.x-XYZ.y;

    const vec3 R=vec3( 3.240479,-1.53715,-0.49853  );
    const vec3 G=vec3(-0.969256,1.875991, 0.041556 );
    const vec3 B=vec3( 0.055684,-0.204043,1.057311 );

    vec3 skyColor=vec3(dot(R,XYZ),dot(G,XYZ),dot(B,XYZ));
    vec4 cloud_c=get_cloud_color(r_c,r_dir);

    return mix(skyColor,cloud_c.rgb,cloud_c.a);
}

vec3 get_water_normal(const vec3 wx)
{
    vec3 x=wx+vec3(cos(water_anim[1])*water_anim[0],0.0,sin(water_anim[1])*water_anim[0]);

    float surf_cos=max(dot(normalize(cam_center-wx),vec3(0.0,0.0,1.0)),0.25);
    float ps=length(wx-cam_center)*lens_param.w/surf_cos;
    float nvx=get_sum(x/water_param[1],wsurf_norm_noise_lod,water_param[1]/ps)*water_param[0];
    float nvy=get_sum(x/water_param[1]+vec3(387.25,517.614,-281.973),
            wsurf_norm_noise_lod,water_param[1]/ps)*water_param[0];
    return normalize(vec3(nvx,nvy,1.0));
}

vec3 extinct_color(const in vec3 color, const in float water_d)
{
    vec3 ek=vec3(1.0-min(water_d/water_extinction.a,1.0));
    return color*pow(ek,water_extinction.xyz);
}

float get_underwater_dist(const in vec3 r_c, const in vec3 r_dir, const in vec3 P) //Когда есть пересечение с поверхностью воды
{
    float t=(sea_level-r_c.z)/r_dir.z;
    return r_c.z>sea_level?length(r_c-P)-t:t;
}

float GetExtraLightsDiffuse(const in vec3 N, const in vec3 P)
{
    float total_dk=0.0;

    for (int i=0; i<lights_n; i++)
    {
        vec3 L=lights_param[i].xyz-P; //Вектор на источник света
        float d=length(L); //Расстояние до источника света
        L=L/d;
        float ang=acos(dot(-L,lights_dir[i]));
        float d_att=pow(1.0-min(1.0,d/lights_att[i][0]),lights_att[i][1]);
        float ang_att=pow(1.0-min(1.0,ang/lights_att[i][2]),lights_att[i][3]);
        float dk=max(0.0,dot(N,L))*d_att*ang_att*lights_param[i][3];
        total_dk+=dk;
    }
    return total_dk;
}

vec3 get_ray_color_case_1(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c) //Камера и точка под водой
{
    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));
    float d_to_sun=(sea_level-r_c.z)/sun_v.z; //Расстояние до солнца в воде

    float dif_k=max(0.0,dot(sun_v,N));
    vec3 pcol=extinct_color(surf_c*(dif_k*sun_param[2]+sun_param[3]),d_to_sun);
    pcol=pcol+GetExtraLightsDiffuse(N,P)*surf_c;
    float D=length(r_c-P); //Расстояние до точки в воде
    return extinct_color(pcol,D);
}
vec3 get_ray_color_case_2(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c) //Камера и точка над водой
{
    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));

    float dif_k=max(0.0,dot(sun_v,N));
    vec3 pcol=surf_c*(dif_k*sun_param[2]+sun_param[3]+GetExtraLightsDiffuse(N,P));
    return pcol;
}
vec3 get_ray_color_case_3(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c) //Камера над, точка под водой
{
    float t=(sea_level-r_c.z)/r_dir.z;
    vec3 wip=r_c+t*r_dir; //Пересечение с поверхностью воды

    vec3 wN=get_water_normal(wip); //Нормаль к поверхности воды

    float fall_cos=max(dot(wN,-r_dir),0.0); //Косинус угла падения
    float refl_part=pow(1.0-fall_cos,0.5); //Доля отражённого света

    vec3 r_dir_refl=normalize(reflect(r_dir,wN));

    vec3 refl_color=get_sky_color(wip,r_dir_refl);
    vec3 refr_color=get_ray_color_case_1(wip,r_dir,N,P,surf_c);

    vec3 base_col=mix(refr_color,refl_color,refl_part);

    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));
    vec3 reflect_v=normalize(reflect(-sun_v,wN));

    float dif_k=max(dot(sun_v,wN),0.0);
    float sk=pow(max(0.0,dot(reflect_v,-r_dir)),water_param[3]);
    vec3 spec_col=vec3(water_param[2])*sk;

    vec3 res_color=base_col*(dif_k*sun_param[2]+sun_param[3])+spec_col*sun_param[2];
    return res_color;
}
vec3 get_ray_color_case_4(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c) //Камера под, точка над водой
{   
    float t=(sea_level-r_c.z)/r_dir.z;
    vec3 wip=r_c+t*r_dir; //Пересечение с поверхностью воды

    vec3 wN=get_water_normal(wip); //Нормаль к поверхности воды

    vec3 base_col=get_ray_color_case_2(wip,r_dir,N,P,surf_c);

    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));
    vec3 refract_v=normalize(refract(-sun_v,wN,1.3));
    vec3 reflect_v=-normalize(reflect(-sun_v,wN));

    float dif_k=max(dot(sun_v,wN),0.0);
    float sk=pow(max(0.0,max(dot(reflect_v,-r_dir),dot(refract_v,-r_dir))),water_param[3]);
    vec3 spec_col=vec3(water_param[2])*sk;

    vec3 res_color=base_col*(dif_k*sun_param[2]+sun_param[3])+spec_col*sun_param[2];
    return extinct_color(res_color,t);
}


vec3 get_ray_color(const in vec3 r_c, const in vec3 r_dir, const in vec3 N, const in vec3 P, const in vec3 surf_c) //Рельеф виден
{
    //Определяем расстояние под водой вдоль луча до точки
    if (r_c.z<=sea_level)
        return P.z<=sea_level?get_ray_color_case_1(r_c,r_dir,N,P,surf_c):
                              get_ray_color_case_4(r_c,r_dir,N,P,surf_c);
    return P.z>=sea_level?get_ray_color_case_2(r_c,r_dir,N,P,surf_c):
                          get_ray_color_case_3(r_c,r_dir,N,P,surf_c);  
}

vec3 get_ray_color_case_1(const in vec3 r_c, const in vec3 r_dir) //Смотрим из воды вверх
{
    float t=(sea_level-r_c.z)/r_dir.z;
    vec3 wip=r_c+t*r_dir; //Пересечение с поверхностью воды

    vec3 wN=get_water_normal(wip); //Нормаль к поверхности воды

    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));
    vec3 sun_refract_v=normalize(refract(-sun_v,wN,1.3));
    vec3 sun_reflect_v=-normalize(reflect(-sun_v,wN));
    vec3 view_refract=normalize(refract(r_dir,-wN,0.77));

    vec3 base_col=get_sky_color(wip,view_refract);

    float dif_k=max(dot(sun_v,wN),0.0);
    float sk=pow(max(0.0,max(dot(sun_reflect_v,-r_dir),dot(sun_refract_v,-r_dir))),water_param[3]);
    vec3 spec_col=vec3(water_param[2])*sk;

    vec3 res_color=base_col*(dif_k*sun_param[2]+sun_param[3])+spec_col*sun_param[2];
    return extinct_color(res_color,t);
}

vec3 get_ray_color_case_4(const in vec3 r_c, const in vec3 r_dir) //Смотрим снаружи вводу
{
    float t=(sea_level-r_c.z)/r_dir.z;
    vec3 wip=r_c+t*r_dir; //Пересечение с поверхностью воды

    vec3 wN=get_water_normal(wip); //Нормаль к поверхности воды

    float fall_cos=max(dot(wN,-r_dir),0.0); //Косинус угла падения
    float refl_part=pow(1.0-fall_cos,0.5); //Доля отражённого света

    vec3 r_dir_refl=normalize(reflect(r_dir,wN));

    vec3 refl_color=get_sky_color(wip,r_dir_refl);
    vec3 refr_color=vec3(0.0,0.0,0.0);

    vec3 base_col=mix(refr_color,refl_color,refl_part);

    vec3 sun_v=normalize(vec3(cos(sun_param.y)*cos(sun_param.x),sin(sun_param.y)*cos(sun_param.x),max(sin(sun_param.x),0.01)));
    vec3 reflect_v=normalize(reflect(-sun_v,wN));

    float dif_k=max(dot(sun_v,wN),0.0);
    float sk=pow(max(0.0,dot(reflect_v,-r_dir)),water_param[3]);
    vec3 spec_col=vec3(water_param[2])*sk;

    vec3 res_color=base_col*(dif_k*sun_param[2]+sun_param[3])+spec_col*sun_param[2];
    return res_color;
}

vec3 get_ray_color(const in vec3 r_c, const in vec3 r_dir) //Рельеф не виден
{
    if (r_c.z<=sea_level)
        return r_dir.z<=0.0?vec3(0.0,0.0,0.0):get_ray_color_case_1(r_c,r_dir);

    return r_dir.z>=0.0?get_sky_color(r_c,r_dir):get_ray_color_case_4(r_c,r_dir);
}
