#version 420
uniform isampler1D sand_tex;
uniform vec3 ushell_mid_color;
uniform vec3 rocks_mid_color;
uniform vec3 rock_colors[7];


#define rock_scale 0.2
#define rock_noise_scale 0.03
#define rock_noise_intens 0.976 //Затенение при усреднении шума камней
#define rock_intens 0.85 //Затенение при усреднении самих каменй
#define rock_noise_T 15.0 //Длина полян камней
#define rock_noise_lod 5 //Количество октав в полянах камней
#define rock_transition 0.01 //Граница перехода камень/песок, где цвета усредняются
#define rock_noise_one_h 0.05 //Большесть нуля шумовой функции, не приводящая к уменьшению высоты камней
#define rock_mid_transparency 0.7 //Средняя прозрачность полян камней

#define shell_noise_T 6.0 //Длина пятен панцерей ежей
#define shell_noise_lod 4 //Количество октав в полянах ежей
#define shell_mid_transparency 0.1 //Срденяя прозрачность полян ежей
#define shell_transition 0.005 //Граница высоты, где происходит смешение с цветом песка

const vec2 rock_scales = vec2(0.1*0.5, 0.2*0.5);
const vec3 rock_noise_shift = vec3(1421.173, -2715.961, 973.597);
const vec3 shell_noise_shift = vec3(-395.197, 519.759, -3711.135);
const vec3 rock_a = vec3(-1.0, 0.4, 0.4);


struct cellular_value
{
    vec3 x; //Координата ближайшей точки
    float d; //Дистанция
    uint id; //Индекс точки
};
float get_turbulence(const in vec3 x, const in int lod);
float get_turbulence(const in vec3 x, const in int lod, const in float max_freq);
float get_sum(const in vec3 x, const in int lod, const in float max_freq);
float cGridBasis_ComputeF(const in vec3 x, inout uint id, inout vec3 p);
float ushell_get(const in vec3 shell_x, const in vec3 x, const in uint shell_id, const in vec3 N, inout vec3 color, const in float scale);
float ushell_get_h(const in vec3 shell_x, const in vec3 x, const in uint shell_id, const in vec3 N, const in float scale);
void full_cellular(const in vec3 x, inout cellular_value F[3]);



float rocks_compute_high_scale(const in float rock_n, const in float shell_n, const in float scale, inout vec3 color)
{
    float mix_bnd=scale*0.1; //Зона смешения цветов разных покрытий (уменьшается с приближением)
    float rock_alpha; //Коэффициент цвета камня
    float shell_alpha; //Коэффициент цвета панциря
    if (rock_n>=shell_n) //Шум для камня дал большее значение
    {
        shell_alpha=smoothstep(rock_n-mix_bnd, rock_n+mix_bnd, shell_n);
        rock_alpha=1.0-shell_alpha;
    }
    else
    {
        rock_alpha=smoothstep(shell_n-mix_bnd, shell_n+mix_bnd, rock_n);
        shell_alpha=1.0-rock_alpha;
    }
    float best=max(rock_n,shell_n);
    float parts_alpha=smoothstep(-mix_bnd, mix_bnd, best); //Общий коэффициент цветов панцирей и камней

    rock_alpha=parts_alpha*rock_alpha*rock_mid_transparency; //Конечный коэффициент цвета камней
    shell_alpha=parts_alpha*shell_alpha*shell_mid_transparency;  //Конечный коэффициент цвета панцирей
    //Цвет с учётом коэффициентов
    color=rocks_mid_color*rock_noise_intens*rock_intens*rock_alpha+ushell_mid_color*shell_alpha;
    //Возвращаем коэффициент рассчитанного цвета для последующей смеси с песком
    return rock_alpha+shell_alpha;
}

float rocks_compute_close_scale(const in vec3 x, const in float rock_nx, const in float shell_nx, const in float scale,
       const in float rock_k, const in float shell_k, inout vec3 color, const in vec3 mN)
{               
    color=vec3(0.0); //Если вдруг не нужно будет считать
    vec3 cx=x/rock_scale; //Вершина для обращения в cellular
    cellular_value cval[3];
    full_cellular(cx,cval);

    vec3 X=cval[0].x*rock_scale; //Координаты центра камня или ежа
    //Находим шумовое значение в центре камня
    float rock_n=get_turbulence(X/rock_noise_T+rock_noise_shift, rock_noise_lod)-0.5+rock_k;
    //Находим шумовое значения в центре панциря (несмотря на то, что ёж, ищем по точке камня, чтобы не ламать линию камней)
    float shell_n=get_turbulence(X/shell_noise_T+shell_noise_shift,shell_noise_lod)-0.5+shell_k;

    if (rock_n<0.0 && shell_n<0.0) return 0.0; //Нет ни ежей ни камней

    if (rock_n>=shell_n) //Место имеют камни
    {
        float factor=smoothstep(0.0, rock_noise_one_h, rock_nx); //Сглаживания на краях каменной поляны
        float h=(cval[0].d*rock_a[0]+cval[1].d*rock_a[1]+cval[2].d*rock_a[2]+0.06)*0.15; //Высота камня
        //Дополнительные неровности на камне
        h+=0.3*(10.0*h+0.2)*rock_noise_scale*get_sum(x/rock_noise_scale,5,rock_noise_scale/scale);
        if (h<0.0) return 0.0; //Дырка в каменном полотне
        h*=factor; //Плавный переход высоты на краях        
        float delta=max(rock_transition,scale*2.0);
        float rock_alpha=smoothstep(0.0,delta,h); //Переход в песок на основании камня

        //Определяем коэффициент затенения, если не виден микрошум
        float lk=smoothstep(rock_noise_scale/4.0, rock_noise_scale, scale);
        float shade=1.0-lk+lk*rock_noise_intens;
        //int cid=texelFetch(sand_tex,int(cval[0].id>>24),0).g;
        //color=rock_colors[cid]*rock_alpha*shade;
        color=rock_colors[texelFetch(sand_tex,int(cval[0].id>>24u),0).g]*rock_alpha*shade;
        return rock_alpha;
    }
    else //Место имеют ежи
    {
        vec3 sh_x; //Координаты центра ёжика
        uint sh_id; //Уникальный индекс ёжика
        cGridBasis_ComputeF(x, sh_id, sh_x); //Вычисление центраёжика
        float h=ushell_get(sh_x,x,sh_id,mN,color,scale);
        float delta=max(shell_transition,scale*2.0);
        float shell_alpha=smoothstep(0.0,delta,h); //Переход в песок на основании ежа
        color*=shell_alpha;
        return shell_alpha;
    }
}


float rocks_get(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k,
                inout vec3 color, const in vec3 mN)
{
    //Рассчитываем шум для пятен камней и панцирей
    float rock_nx=get_turbulence(x/rock_noise_T+rock_noise_shift,rock_noise_lod,rock_noise_T/scale)-0.5+rock_k;
    float shell_nx=get_turbulence(x/shell_noise_T+shell_noise_shift,shell_noise_lod,shell_noise_T/scale)-0.5+shell_k;

    //Усреднённые плотность и цвет пятен камней и панцирей
    float mid_opaque=1.0;
    vec3 mid_color=vec3(0.0);
    //Если далеко, то понадобяться значения среднего цвета и плотности
    if (scale>rock_scales[0])
        mid_opaque=rocks_compute_high_scale(rock_nx, shell_nx, scale, mid_color);

    //Реальная плотность и цвет пятна камней или поляны
    float part_opaque=1.0;
    vec3 part_color=vec3(0.0);

    //Достаточно близко, чтобы потребовался расчёт деталей камней и панцирей
    if (scale<rock_scales[1])
        part_opaque=rocks_compute_close_scale(x,rock_nx, shell_nx, scale, rock_k, shell_k, part_color, mN);

    //Коэффициент выбора между средним и реальным цветом и плотностью
    float sck=smoothstep(rock_scales[0], rock_scales[1], scale);

    //Смешиваем цвета
    color=mix(part_color, mid_color, sck);
    //Смешиваем и возращаем заполненость
    return mix(part_opaque, mid_opaque, sck);
}

float rocks_get_h(const in vec3 x, const in float scale, const in float rock_k, const in float shell_k, const in vec3 mN)
{
    if (scale>=rock_scales[1]) return 0.0; //Ни камней ни ежей самих по себе не видно
    else //Видны кмни и ежи, что не может не радовать
    {        
        float scale_k=1.0-smoothstep(rock_scales[0],rock_scales[1], scale); //Коэффициент уменшьшения при отдалении камеры
        vec3 cx=x/rock_scale;
        cellular_value cval[3];
        full_cellular(cx,cval);
        vec3 X=cval[0].x*rock_scale;
        //Находим шумовое значение камня
        float rock_n=get_turbulence(X/rock_noise_T+rock_noise_shift,rock_noise_lod)-0.5+rock_k;
        //Находим шумовое значения панциря (несмотря на то, что это ёж, ищем в центре камня, чтобы не ломать линию камней)
        float shell_n=get_turbulence(X/shell_noise_T+shell_noise_shift,shell_noise_lod)-0.5+shell_k;

        if (rock_n<0.0 && shell_n<0.0) return 0.0; //Всё же ежей и камней нет

        if (rock_n>=shell_n) //Место имеют камни
        {
            //Считаем шумовую функцию уже в текущей точке, чтобы применить уменьшеение высот к кноцу поляны камней
            float rock_n2=get_turbulence(x/rock_noise_T+rock_noise_shift,rock_noise_lod,rock_noise_T/scale)-0.5+rock_k;

            float factor = smoothstep(0.0,rock_noise_one_h, rock_n2); //Коэффициент уменьшения высоты камней к краям поляны
            float h=(cval[0].d*rock_a[0]+cval[1].d*rock_a[1]+cval[2].d*rock_a[2]+0.06)*0.15; //Высота камня
            h+=0.3*(10.0*h+0.2)*rock_noise_scale*get_sum(x/rock_noise_scale,5,rock_noise_scale/scale); //Добавляем мелкий шум
            if (h<0.0) return 0.0;
            h*=factor;
            return h*scale_k;
        }
        else
        { //Место имеют ежи
            vec3 sh_x; //Координаты центра ёжика
            uint sh_id; //Уникальный индекс ёжика
            cGridBasis_ComputeF(x,sh_id,sh_x); //Вычисление центра ёжика
            return ushell_get_h(sh_x, x, sh_id, mN, scale)*scale_k; //Функция высоты ежа
        }
    }
}
