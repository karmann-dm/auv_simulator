#version 420
uniform isampler1D sand_tex;
uniform vec3 sand_mid_color;
uniform vec3 sand_colors[7];

#define sand_grain_intensity 0.759196
#define sand_bump_power 0.15
#define sand_bump_intensity 0.942156


const float sand_grain_a[9]=float[9](-0.528794,
                                      0.637928,
                                      0.567431,
                                     -0.452132,
                                      0.126438,
                                     -0.650563,
                                     -0.751518,
                                      0.514206,
                                     -0.172399);

const vec2 sand_grain_scaler = vec2(-1.111489, 1.0);
const vec2 sand_bump_scaler = vec2(0.0, 0.7);
const vec2 parts_to_sand = vec2(0.0025, 0.01);
const vec2 bumps_to_sand = vec2(0.3, 0.5);

const float sand_grain_scale=(parts_to_sand[1]+parts_to_sand[0])*0.5;
const float sand_bump_scale = (bumps_to_sand[1]+bumps_to_sand[0])*0.5;


struct cellular_value
{
    vec3 x; //Координата ближайшей точки
    float d; //Дистанция
    uint id; //Индекс точки
};

void full_cellular(const in vec3 x, inout cellular_value F[2]);
float get_noise3D(in vec3 x);
float rocks_get_h(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN);
float rocks_get(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k,
                inout vec3 color, const in vec3 mN);

float sand_bump(const in vec3 x)
{
    cellular_value cval[2];
    full_cellular(x,cval);
    float v=(cval[0].d-sand_bump_scaler[0])*sand_bump_scaler[1];
    return pow(1.0-clamp(v,0.0,1.0),sand_bump_power);
}

float sand_grain(const in vec3 x, inout vec3 c)
{
    cellular_value cval[2];
    full_cellular(x,cval);
    vec2 f=vec2(cval[0].d,cval[1].d);
    vec2 ff=f*f;

    float k=sand_grain_a[0]+sand_grain_a[1]*f.y+sand_grain_a[2]*ff.y+sand_grain_a[3]*f.x+
            sand_grain_a[4]*f.x*f.y+sand_grain_a[5]*f.x*ff.y+sand_grain_a[6]*ff.x+
            sand_grain_a[7]*ff.x*f.y+sand_grain_a[8]*ff.x*ff.y;
    k=(k-sand_grain_scaler[0])*sand_grain_scaler[1];

    int cid=texelFetch(sand_tex,int(cval[0].id>>24u),0).r;
    c=sand_colors[cid];

    return clamp(k,0.0,1.0);
}

//x - неизменяемая координата (не зависит от уровня детализации) - точка на сеточной модели
//scale - приблизительный размер пикселя в метрах, рассчитанный на основе сеточной модели
float sand_get_h(const in vec3 x, const in float scale)
{
    if (scale>bumps_to_sand[1]) return 0.0; //Масштаб не позволяет отобразить высоту песка
    //Рассчитываем кооэффициент допустимой детализации кочек
    float sk=scale<=bumps_to_sand[0]?1.0f:(bumps_to_sand[1]-scale)/(bumps_to_sand[1]-bumps_to_sand[0]);

    float nv=get_noise3D(vec3(1.5*x.x/sand_bump_scale, 0.75*x.y/sand_bump_scale,x.z));
    float factor=0.6+0.35*get_noise3D(0.1*x); //Колебание величины кочек в пространстве

    return sk*(factor*0.03*pow(1.0+nv,2.0)-0.043285); //Кочки, отмасштабированные до ~8 см, с нулевой средней высотой
}

//x - точка на сеточной модели
//scale - размер пикселя в метрах
//color - рассчитанный цвет RGB, значения каналов от 0 до 1
vec3 sand_get(const in vec3 x, const in float scale)
{
    vec3 gx=x/sand_grain_scale; //Координаты для расчёта зерна

    vec3 grain_color=vec3(1.0);
    float grain_light=1.0f;
    if (scale<=parts_to_sand[1]) //Если масштаб достаточно мелкий
        grain_light=sand_grain(gx,grain_color); //Рассчитываем цвет зерна

    float grain_color_coef=smoothstep(parts_to_sand[0],parts_to_sand[1], scale); //Коэффициент, с которым усредняется цвет зерна

    vec3 use_color=(sand_mid_color-grain_color)*grain_color_coef+grain_color; //Усреднённый цвет песка

    float use_light=mix(grain_light, sand_grain_intensity, grain_color_coef); //Усреднённое освещение песка

    vec3 clear_sand_color=use_color*use_light; //Цвет чистого песка без кочек

    float bump_coef=smoothstep(bumps_to_sand[0],bumps_to_sand[1], scale); //Коэффициент того, на сколько можно видеть кочки
    use_light=mix(1.0, sand_bump_intensity, bump_coef); //Цвет с учётом доп. затенения кочек вдалеке

    return clear_sand_color*use_light;
}
//
vec3 sand_get_composite(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN)
{
    vec3 rcol=vec3(0.0);
    float opaque=rocks_get(x, scale, rock_k, shell_k, rcol, mN);
    vec3 scol=vec3(0.0);
    if (opaque<0.99) scol=sand_get(x, scale);
    return rcol+scol*(1.0-opaque);
}

float sand_get_composite_h(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN)
{
    float h=rocks_get_h(x,scale,rock_k,shell_k,mN);
    float sand_h=sand_get_h(x,scale);
    return sand_h+h;
}
