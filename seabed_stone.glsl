#version 420
uniform sampler1D more_probability;
uniform sampler1D stone_colors;

struct cellular_value
{
    vec3 x; //Координата ближайшей точки
    float d; //Дистанция
    uint id; //Индекс точки
};

void full_cellular(const in vec3 x, inout cellular_value F[3]);
float get_noise3D(in vec3 x);
float get_sum(const in vec3 x, const in int lod, const in float max_freq);
float get_turbulence(const in vec3 x, const in int lod, const in float max_freq);


#define stone_bcn 4 //Количество цветов растительности
#define stone_bio_delta 0.1 //Максимальная разница цветовых компонентов групп одного лишайника
#define stone_scale 0.5 //Масштаб рисунка камня
#define stone_bio_scale 1.0 //Масштаб пятен растительности
#define stone_bio_col_smooth 0.1 //Разница шума между разными типами растительности, на которой они смешиваются
#define stone_bio_part_scale 100 //Масштаб рисунка растительности
#define stone_bio_transparent_bondary 0.5 //Граница между прозрачной и непрозрачной растительностью
#define stone_bio_intens 0.495250 //Средний уровень яркости рисунка растительности

const vec3 biocolors[stone_bcn]=vec3[](
    vec3(84.0/255.0, 128.0f/255.0, 74.0f/255.0),
    vec3(157.0/255.0, 96.0f/255.0, 96.0f/255.0),
    vec3(218.0/255.0, 179.0f/255.0, 123.0f/255.0),
    vec3(227.0/255.0, 240.0f/255.0, 141.0f/255.0));

//Уровни шумовой функции, выше которых располагается растительность при нулевом параметре bioshift
const vec4 bio_levels=vec4(0.4,0.65,0.65,0.5);

//Сдвиги шумов для разных видов растительности, чтобы обеспечить разные значения в одинаковых координатах
const vec3 bio_shifts[stone_bcn]=vec3[](
    vec3( 3735.953, -7871.711,  2592.174),
    vec3(-7628.371, -1943.111, -8892.591),
    vec3( 4158.627,  5571.938, -6569.686),
    vec3(-9989.533,  4674.837, -3472.836));

//Коэффициенты для расчёта рисунка растительности
const vec3 bio_a=vec3(-0.8,0.4,-1.0);

//Масштабные коэффициенты растительности
const vec2 bio_scaler=vec2(-1.494559, 0.68341);

//Масштаб, при котором яркость рисунка растительности заменяется средним цветом
const vec2 bio_to_mid_color=vec2(0.1, 0.4);


float get_bio_light(const in vec3 x, const in float dcol, out vec3 color_delta) //Расчёт рисунка растительности
{
    cellular_value cv[3];
    full_cellular(x,cv);
    float k=dot(vec3(cv[0].d,cv[1].d,cv[2].d),bio_a); //Яркость
    //Рассчитываем случайные значения от -1 до 1 на основе id и умножаем их на dcol
    color_delta = vec3((float((cv[2].id>>20u)&1023u)/512.0)-1.0,
                       (float((cv[2].id>>10u)&1023u)/512.0)-1.0,
                       (float((cv[2].id)&1023u)/512.0)-1.0)*dcol;
    return clamp((k-bio_scaler.x)*bio_scaler.y,0.0,1.0); //Масштабируем и возвращаем яркость
}

float cStone_GetH(const in vec3 x, const in float scale)
{
    if (scale>=1.0) return 0.0;
    float factor=0.6+0.5*get_noise3D(0.1*x);
    return 0.5*factor*get_sum(x,7,1.0/scale);
}

vec3 stone_compute_color(const in vec3 x, const in float scale, const in float bioshift)
{    
    float max_freq=1.0/scale; //Частота отсечения
    // Расчитываем шумовую функцию для рисунка камня
    float nval=get_sum(x*stone_scale,7,max_freq/stone_scale);
    vec3 color=texture(stone_colors,nval*0.5+0.5).rgb;

    float nv[stone_bcn]; //Значения шумов для всех типов растительности
    float pv[stone_bcn]; //Вероятности выбора покрытия каждого цвета
    float psum=0.0; //Сумма вероятностей выбора покрытия каждого цвета
    float pstone=1.0; //Вероятность выбора цвета камня
    float max_nv=0.0; //Здесь будем искать значение доминирующей растительности
    for (int i=0; i<stone_bcn; i++)
    {
        pv[i]=texture(more_probability,0.5*(bio_levels[i]-bioshift)).r;
        pstone*=(1.0-pv[i]); //Уменьшаем вероятность чистого камня
        psum+=pv[i];
        //Смещённое значение шума для i-й растительности
        nv[i]=get_turbulence(stone_bio_scale*x+bio_shifts[i],5,max_freq/stone_bio_scale)-bio_levels[i]+bioshift;
        max_nv=max(nv[i],nv[i]);
    }
    //Рассчитываем средний цвет растительности, который будет важен, если пятна растительности пока не видны
    //В качестве весовых коэффициентов используем вероятности, рассчитанные ранее
    vec3 mid_color=vec3(0.0);
    for (int i=0; i<stone_bcn; i++)
    {
        pv[i]/=psum;
        mid_color+=biocolors[i]*pv[i];
    }
    //Добавляем цвет камня с его вероятностью к цвету растительности
    mid_color=mix(mid_color, color, pstone);

    if (max_nv>0.0)
    {
        //К цвету добавляется цвет растительности
        float w[stone_bcn]; //Весовые коэффициенты цвета
        float sum=0.0;
        vec3 bio_color=vec3(0.0);
        //Смешиваем цвета всех типов растительности
        for (int i=0; i<stone_bcn; i++)
        {
            w[i]=smoothstep(max_nv-stone_bio_col_smooth, max_nv, nv[i]);
            sum+=w[i];
            bio_color+=w[i]*biocolors[i];
        }
        float b_alpha=1.0-smoothstep(max_nv-stone_bio_col_smooth, max_nv, 0.0f); //Коэффициент смешения растительности с камнем
        vec3 dc=vec3(0.0);
        //Координаты для расчёта рисунка растительности
        vec3 bpx=x*stone_bio_part_scale;

        //Коэффициент использования рисунка растительности
        float bio_coef=1.0-smoothstep(1.0/stone_bio_part_scale, 2.5/stone_bio_part_scale, scale);
        float color_difference=bio_coef*stone_bio_delta; //Удаляясь от растительности, труднее заметить локальные разницы цветов
        float bk=bio_coef>0.001?get_bio_light(bpx,color_difference,dc):0.0;
        bk=mix(stone_bio_intens, bk, bio_coef);
        b_alpha*=smoothstep(0.0, stone_bio_transparent_bondary, bk); //Уменьшаем коэффициент смешения растительности, если она прозрачна
        float s_alpha=1.0-b_alpha;

        vec3 bc=clamp((bio_color/sum+dc)*bk,0.0,1.0);
        //Смешиваем цвет растительности и цвет камня
        color=b_alpha*bc + color*s_alpha;
    }

    float mid_color_k=smoothstep(bio_to_mid_color[0], bio_to_mid_color[1], scale);
    //Если далеко, то выбираем средний цвет растительности+каменя вместо рассчитанного
    color=mix(color,mid_color,mid_color_k);
    return color;
}
