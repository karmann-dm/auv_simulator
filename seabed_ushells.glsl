#version 420
uniform isampler1D sand_tex;
uniform vec3 ushell_colors[5];

uint ChurnSeed(const in uint seed);

float get_rand(const in float from, const in float to, inout uint cur_seed)
{
    cur_seed=ChurnSeed(cur_seed);
    return (float(cur_seed)/4294967296.0)*(to-from)+from;
}

float ushell_get(const in vec3 shell_x, const in vec3 x, const in uint shell_id, const in vec3 N, inout vec3 color, const in float scale)
{
    uint cur_seed=shell_id;
    if (texelFetch(sand_tex,int(cur_seed>>24u),0).a==0) return 0.0;

    float R=get_rand(0.04,0.06,cur_seed); //Собственный радиус ежа

    vec3 dx=x-shell_x;
    vec3 z_axis=N;
    vec3 y_axis=normalize(cross(N,vec3(1.0,0.0,0.0)));
    vec3 x_axis=normalize(cross(N,y_axis));

    vec2 pv=vec2(dot(x_axis,dx),dot(y_axis,dx));
    float sq_r=dot(pv,pv);
    const float max_sq_r=1.2*1.2*R*R; //В еже не заключено квадрата большего, чем этот
    if (sq_r>max_sq_r) return 0.0; //Не получилось пока ежа

    float ori=get_rand(0.0,360.0, cur_seed);
    float assym_coef=get_rand(0.95f,1.05f, cur_seed);
    float rside=R*get_rand(0.75,1.1, cur_seed);
    float lside=rside*assym_coef;
    float rpeak_xshift=90*get_rand(0.2f,0.4f, cur_seed);
    float lpeak_xshift=rpeak_xshift*assym_coef;
    float rpeak_yshift=R*get_rand(1.0f,1.1f, cur_seed);
    float lpeak_yshift=assym_coef*rpeak_yshift;
    float mouth_hole=R*get_rand(0.7f,1.0f, cur_seed);
    float ass_len=R*get_rand(0.8f,1.1f, cur_seed);
    float height=R*get_rand(0.3f,0.6f, cur_seed);

    float hole_width=get_rand(7.0f,15.0f, cur_seed); //Ширина звездообразных ям на панцире в градусах
    float hole_depth=get_rand(0.005, 0.002, cur_seed); //Глубина звездообразных ям на панцире в метрах
    float hole_len=R*get_rand(0.65f,0.9f, cur_seed); //Длина звездообразных ям на панцире

     //Координаты в плоскости ежа
    float cur_r=length(pv); //Радиус точки
    pv=pv/cur_r;

    float a=acos(pv[0])*180.0/3.1415; //Угол точки в градусах
    a=(pv.y<0.0)?360.0-a:a;
    a=a+ori<360.0f?a+ori:a+ori-360.0; //Добавляем ориентацию ежа

    float shell_r=(a<=180.0)
       ?(a<=90.0)
          ?(a<=90.0-rpeak_xshift)?rside+a/(90.0-rpeak_xshift)*(rpeak_yshift-rside) : rpeak_yshift+(a-90.0+rpeak_xshift)/(rpeak_xshift)*(mouth_hole-rpeak_yshift)
          :(a<=90.0+lpeak_xshift)?mouth_hole+(a-90.0)/(lpeak_xshift)*(lpeak_yshift-mouth_hole) : lpeak_yshift+(a-90.0-lpeak_xshift)/(90.0-lpeak_xshift)*(lside-lpeak_yshift)
       :(a<=270.0)?lside+(a-180.0)/90.0*(ass_len-lside):ass_len+(a-270.0)/90.0*(rside-ass_len);

    if (cur_r>=shell_r) return 0.0; //За границей ежа

    float h=sqrt(shell_r*shell_r-cur_r*cur_r)*height/shell_r;

    int cid=texelFetch(sand_tex, int((shell_id>>16u) & 255u),0).b;
    color=ushell_colors[cid];
    return h;
}

float GetHolePos(const in float a, const in float sk,  const in float hole_width)
{
    float hw=hole_width*sk;
    return (abs(a-18.0)<hw)
      ?1.0-abs(a-18.0)/hw //Лучик первый - 18 градусов
      :(abs(a-90.0)<hw)
        ?1.0-abs(a-90.0)/hw //Лучик первый - 90 градусов
        :(abs(a-162.0)<hw)
          ?1.0-abs(a-162.0)/hw //Лучик первый - 162 градусов
          :(abs(a-234.0)<hw)
            ?1.0-abs(a-234.0)/hw //Лучик первый - 234 градусов
            :(abs(a-306.0)<hw)
              ?1.0-abs(a-306.0)/hw //Лучик первый - 306 градусов
              :0.0;
}


float ushell_get_h(const in vec3 shell_x, const in vec3 x, const in uint shell_id, const in vec3 N, const in float scale)
{
    uint cur_seed=shell_id;
    if (texelFetch(sand_tex,int(cur_seed>>24u),0).a==0) return 0.0;

    float R=get_rand(0.04,0.06,cur_seed); //Собственный радиус ежа

    vec3 dx=x-shell_x;
    vec3 z_axis=N;
    vec3 y_axis=normalize(cross(N,vec3(1.0,0.0,0.0)));
    vec3 x_axis=normalize(cross(N,y_axis));

    vec2 pv=vec2(dot(x_axis,dx),dot(y_axis,dx));
    float sq_r=dot(pv,pv);
    const float max_sq_r=1.2*1.2*R*R; //В еже не заключено квадрата большего, чем этот
    if (sq_r>max_sq_r) return 0.0; //Не получилось пока ежа

    float ori=get_rand(0.0,360.0, cur_seed);
    float assym_coef=get_rand(0.95f,1.05f, cur_seed);
    float rside=R*get_rand(0.75,1.1, cur_seed);
    float lside=rside*assym_coef;
    float rpeak_xshift=90*get_rand(0.2f,0.4f, cur_seed);
    float lpeak_xshift=rpeak_xshift*assym_coef;
    float rpeak_yshift=R*get_rand(1.0f,1.1f, cur_seed);
    float lpeak_yshift=assym_coef*rpeak_yshift;
    float mouth_hole=R*get_rand(0.7f,1.0f, cur_seed);
    float ass_len=R*get_rand(0.8f,1.1f, cur_seed);
    float height=R*get_rand(0.3f,0.6f, cur_seed);

    float hole_width=get_rand(7.0f,15.0f, cur_seed); //Ширина звездообразных ям на панцире в градусах
    float hole_depth=get_rand(0.005, 0.002, cur_seed); //Глубина звездообразных ям на панцире в метрах
    float hole_len=R*get_rand(0.65f,0.9f, cur_seed); //Длина звездообразных ям на панцире

    //Координаты в плоскости ежа
    float cur_r=length(pv); //Радиус точки
    pv=pv/cur_r;

    float a=acos(pv[0])*180.0/3.1415; //Угол точки в градусах
    a=(pv.y<0.0)?360.0-a:a;
    a=a+ori<360.0f?a+ori:a+ori-360.0; //Добавляем ориентацию ежа

    float shell_r=(a<=180.0)
      ?(a<=90.0)
         ?(a<=90.0-rpeak_xshift)?rside+a/(90.0-rpeak_xshift)*(rpeak_yshift-rside) : rpeak_yshift+(a-90.0+rpeak_xshift)/(rpeak_xshift)*(mouth_hole-rpeak_yshift)
         :(a<=90.0+lpeak_xshift)?mouth_hole+(a-90.0)/(lpeak_xshift)*(lpeak_yshift-mouth_hole) : lpeak_yshift+(a-90.0-lpeak_xshift)/(90.0-lpeak_xshift)*(lside-lpeak_yshift)
      :(a<=270.0)?lside+(a-180.0)/90.0*(ass_len-lside):ass_len+(a-270.0)/90.0*(rside-ass_len);

    if (cur_r>=shell_r) return 0.0; //За границей ежа

    float shell_h=sqrt(shell_r*shell_r-cur_r*cur_r)*height/shell_r; //Высота ежа в x
    float hlen_scaler=cur_r>hole_len?0.0:(1.0-cur_r/hole_len); //Пока коэффициент длины бороздок на еже

    //Определяем точку относительно канавки (0-край, 1-центр)
    float sk=hlen_scaler>0.5?2.0-(hlen_scaler-0.5)/0.5:1.0+hlen_scaler/0.5;
    float hp=GetHolePos(a,sk,hole_width);

    hlen_scaler=hlen_scaler>0.8?pow(1.0-(hlen_scaler-0.8)/0.2,2.0):
                                 (hlen_scaler<0.3?pow(hlen_scaler/0.3,2.0):1.0); //Теперь масштабный коэффициет по длине

    float hole_h=hole_depth*hlen_scaler*hp*hp; //Глубина бороздки ежа в точке x
    float aa_reduction=1.0-smoothstep(0.003,0.006, scale); //Для устранения ступенчатости, уменьшаем глубину канавок при отдалении
    return shell_h-hole_h*aa_reduction;
}
