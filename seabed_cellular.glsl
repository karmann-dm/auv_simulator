#version 420

uniform isampler1D samples_per_cell;

struct cellular_value
{
    vec3 x; //Координата ближайшей точки
    float d; //Дистанция
    uint id; //Индекс точки
};

uint ChurnSeed(const in uint seed)
{
    return 1402024253u*seed+586950981u;
}

vec3 permute(vec3 x){return mod(((x*34.0)+1.0)*x, 289.0);}

void supercompare(inout cellular_value F[3], const in float v, const in vec3 p, const in uint id)
{
   if (v<F[0].d)
   {
       F[2]=F[1];
       F[1]=F[0];
       F[0].d=v;
       F[0].x=p;
       F[0].id=id;
   }
   else if (v<F[1].d)
   {
        F[2]=F[1];
        F[1].d=v;
        F[1].x=p;
        F[1].id=id;
   }
   else if (v < F[2].d)
   {
        F[2].d=v;
        F[2].x=p;
        F[2].id=id;
   }
}

void supercompare(inout cellular_value F[2], const in float v, const in vec3 p, const in uint id)
{
   if (v<F[0].d)
   {
       F[1]=F[0];
       F[0].d=v;
       F[0].x=p;
       F[0].id=id;
   }
   else if (v<F[1].d)
   {
        F[1].d=v;
        F[1].x=p;
        F[1].id=id;
   }
}

void AddPoint(const in int xi0, const in int xi1, const in int xi2, const in vec3 x, inout cellular_value F[2])
{
    uint seed=702395077u*uint(xi0)+915488749u*uint(xi1)+2120969693u*uint(xi2);    
    int n=texelFetch(samples_per_cell,int(seed>>24u),0).r;
    seed=ChurnSeed(seed);

    const double diver=1.0/4294967296.0;

    vec3 px;
    uint id;
    float d;
    int insert_id;
    vec3 norm;
    for (int i=0; i<n; i++)
    {
        id=seed;
        seed=ChurnSeed(seed);
        px[0]=float((double(seed)+0.5)*diver)+xi0;
        seed=ChurnSeed(seed);
        px[1]=float((double(seed)+0.5)*diver)+xi1;
        seed=ChurnSeed(seed);
        px[2]=float((double(seed)+0.5)*diver)+xi2;
        norm=px-x;
        d=norm.x*norm.x+norm.y*norm.y+norm.z*norm.z;
        supercompare(F,d,x,id);
    }
}

void AddPoint(const in int xi0, const in int xi1, const in int xi2, const in vec3 x, inout cellular_value F[3])
{
    uint seed=702395077u*uint(xi0)+915488749u*uint(xi1)+2120969693u*uint(xi2);    
    int n=texelFetch(samples_per_cell,int(seed>>24u),0).r;
    seed=ChurnSeed(seed);

    const float diver=1.0/4294967296.0;

    vec3 px;
    uint id;
    float d;
    int insert_id;
    vec3 norm;
    for (int i=0; i<n; i++)
    {
        id=seed;
        seed=ChurnSeed(seed);
        px[0]=float((float(seed)+0.5)*diver) + xi0;
        seed=ChurnSeed(seed);
        px[1]=float((float(seed)+0.5)*diver) + xi1;
        seed=ChurnSeed(seed);
        px[2]=float((float(seed)+0.5)*diver) + xi2;
        norm = px - x;
        d=norm.x*norm.x+norm.y*norm.y+norm.z*norm.z;
        supercompare(F, d, px, id);
    }
}

void full_cellular(const in vec3 x, inout cellular_value F[3])
{
    for (int i=0; i<=2; i++)
    {
        F[i].d=12.0;
        F[i].id=0;
    }
    ivec3 xi = ivec3(floor(x));
    int xi0 = xi.x;
    int xi1 = xi.y;
    int xi2 = xi.z;
    AddPoint(xi0, xi1, xi2, x, F);

    float x2=x[0]-xi0;
    float y2=x[1]-xi1;
    float z2=x[2]-xi2;
    float mx2=(1.0-x2)*(1.0-x2);
    float my2=(1.0-y2)*(1.0-y2);
    float mz2=(1.0-z2)*(1.0-z2);
    x2*=x2;
    y2*=y2;
    z2*=z2;
    /* Test 6 facing neighbors of center cube. These are closest and most
    likely to have a close feature point. */
    if (x2<F[2].d)  AddPoint(xi0-1, xi1,   xi2,   x, F);
    if (y2<F[2].d)  AddPoint(xi0,   xi1-1, xi2,   x, F);
    if (z2<F[2].d)  AddPoint(xi0,   xi1,   xi2-1, x, F);
    if (mx2<F[2].d) AddPoint(xi0+1, xi1,   xi2,   x, F);
    if (my2<F[2].d) AddPoint(xi0,   xi1+1, xi2,   x, F);
    if (mz2<F[2].d) AddPoint(xi0,   xi1,   xi2+1, x, F);
    /* Test 12 “edge cube” neighbors if necessary. They’re next closest. */
    if (x2+y2<F[2].d)   AddPoint(xi0-1, xi1-1, xi2,   x, F);
    if (x2+z2<F[2].d)   AddPoint(xi0-1, xi1,   xi2-1, x, F);
    if (y2+z2<F[2].d)   AddPoint(xi0,   xi1-1, xi2-1, x, F);
    if (mx2+my2<F[2].d) AddPoint(xi0+1, xi1+1, xi2,   x, F);
    if (mx2+mz2<F[2].d) AddPoint(xi0+1, xi1,   xi2+1, x, F);
    if (my2+mz2<F[2].d) AddPoint(xi0,   xi1+1, xi2+1, x, F);
    if (x2+my2<F[2].d)  AddPoint(xi0-1, xi1+1, xi2,   x, F);
    if (x2+mz2<F[2].d)  AddPoint(xi0-1, xi1,   xi2+1, x, F);
    if (y2+mz2<F[2].d)  AddPoint(xi0,   xi1-1, xi2+1, x, F);
    if (mx2+y2<F[2].d)  AddPoint(xi0+1, xi1-1, xi2,   x, F);
    if (mx2+z2<F[2].d)  AddPoint(xi0+1, xi1,   xi2-1, x, F);
    if (my2+z2<F[2].d)  AddPoint(xi0,   xi1+1, xi2-1, x, F);

    /* Final 8 “corner” cubes */
    if (x2+y2+z2<F[2].d)    AddPoint(xi0-1, xi1-1, xi2-1,   x, F);
    if (x2+y2+mz2<F[2].d)   AddPoint(xi0-1, xi1-1, xi2+1,   x, F);
    if (x2+my2+z2<F[2].d)   AddPoint(xi0-1, xi1+1, xi2-1,   x, F);
    if (x2+my2+mz2<F[2].d)  AddPoint(xi0-1, xi1+1, xi2+1,   x, F);
    if (mx2+y2+z2<F[2].d)   AddPoint(xi0+1, xi1-1, xi2-1,   x, F);
    if (mx2+y2+mz2<F[2].d)  AddPoint(xi0+1, xi1-1, xi2+1,   x, F);
    if (mx2+my2+z2<F[2].d)  AddPoint(xi0+1, xi1+1, xi2-1,   x, F);
    if (mx2+my2+mz2<F[2].d) AddPoint(xi0+1, xi1+1, xi2+1,   x, F);

    F[0].d=sqrt(F[0].d);
    F[1].d=sqrt(F[1].d);
    F[2].d=sqrt(F[2].d);
}

void full_cellular(const in vec3 x, inout cellular_value F[2])
{
    F[0].d=12.0;
    F[0].id=0;
    F[1].d=12.0;
    F[1].id=0;

    ivec3 xi = ivec3(floor(x));
    int xi0 = xi.x;
    int xi1 = xi.y;
    int xi2 = xi.z;
    AddPoint(xi0, xi1, xi2, x, F);

    float x2=x[0]-xi0;
    float y2=x[1]-xi1;
    float z2=x[2]-xi2;
    float mx2=(1.0-x2)*(1.0-x2);
    float my2=(1.0-y2)*(1.0-y2);
    float mz2=(1.0-z2)*(1.0-z2);
    x2*=x2;
    y2*=y2;
    z2*=z2;
    /* Test 6 facing neighbors of center cube. These are closest and most
    likely to have a close feature point. */
    if (x2<F[1].d)  AddPoint(xi0-1, xi1,   xi2,   x, F);
    if (y2<F[1].d)  AddPoint(xi0,   xi1-1, xi2,   x, F);
    if (z2<F[1].d)  AddPoint(xi0,   xi1,   xi2-1, x, F);
    if (mx2<F[1].d) AddPoint(xi0+1, xi1,   xi2,   x, F);
    if (my2<F[1].d) AddPoint(xi0,   xi1+1, xi2,   x, F);
    if (mz2<F[1].d) AddPoint(xi0,   xi1,   xi2+1, x, F);
    /* Test 12 “edge cube” neighbors if necessary. They’re next closest. */
    if (x2+y2<F[1].d)   AddPoint(xi0-1, xi1-1, xi2,   x, F);
    if (x2+z2<F[1].d)   AddPoint(xi0-1, xi1,   xi2-1, x, F);
    if (y2+z2<F[1].d)   AddPoint(xi0,   xi1-1, xi2-1, x, F);
    if (mx2+my2<F[1].d) AddPoint(xi0+1, xi1+1, xi2,   x, F);
    if (mx2+mz2<F[1].d) AddPoint(xi0+1, xi1,   xi2+1, x, F);
    if (my2+mz2<F[1].d) AddPoint(xi0,   xi1+1, xi2+1, x, F);
    if (x2+my2<F[1].d)  AddPoint(xi0-1, xi1+1, xi2,   x, F);
    if (x2+mz2<F[1].d)  AddPoint(xi0-1, xi1,   xi2+1, x, F);
    if (y2+mz2<F[1].d)  AddPoint(xi0,   xi1-1, xi2+1, x, F);
    if (mx2+y2<F[1].d)  AddPoint(xi0+1, xi1-1, xi2,   x, F);
    if (mx2+z2<F[1].d)  AddPoint(xi0+1, xi1,   xi2-1, x, F);
    if (my2+z2<F[1].d)  AddPoint(xi0,   xi1+1, xi2-1, x, F);

     /* Final 8 “corner” cubes */
    if (x2+y2+z2<F[1].d)    AddPoint(xi0-1, xi1-1, xi2-1,   x, F);
    if (x2+y2+mz2<F[1].d)   AddPoint(xi0-1, xi1-1, xi2+1,   x, F);
    if (x2+my2+z2<F[1].d)   AddPoint(xi0-1, xi1+1, xi2-1,   x, F);
    if (x2+my2+mz2<F[1].d)  AddPoint(xi0-1, xi1+1, xi2+1,   x, F);
    if (mx2+y2+z2<F[1].d)   AddPoint(xi0+1, xi1-1, xi2-1,   x, F);
    if (mx2+y2+mz2<F[1].d)  AddPoint(xi0+1, xi1-1, xi2+1,   x, F);
    if (mx2+my2+z2<F[1].d)  AddPoint(xi0+1, xi1+1, xi2-1,   x, F);
    if (mx2+my2+mz2<F[1].d) AddPoint(xi0+1, xi1+1, xi2+1,   x, F);


    F[0].d=sqrt(F[0].d);
    F[1].d=sqrt(F[1].d);
 }



//Uniform grid basis
#define grid_size 0.2 //Размер сетки
#define grid_safe_radius 0.05 //Радиус безопасности, сводящий к минимому возможнось пересечения ежей

float cGridBasis_ComputeF(const in vec3 x, inout uint id, inout vec3 p)
{
    //Масштабируем x согласно размеру сетки
    vec3 xs=x/grid_size;
    //Находим ближайшую к x точку сетки
    vec3 xc=round(xs);
    ivec3 xi=ivec3(xc);

    uint seed=702395077u*uint(xi[0])+915488749u*uint(xi[1])+2120969693u*uint(xi[2]);

    const float diver=1.0/4294967296.0;
    float len=max(0.0,0.5-grid_safe_radius/grid_size);

    //Сдвигаем точку, согласно сдвигу
    float dx=float(2.0*(float(seed)+0.5)*diver-1.0)*len;
    seed=ChurnSeed(seed);
    float dy=float(2.0*(float(seed)+0.5)*diver-1.0)*len;
    seed=ChurnSeed(seed);
    float dz=float(2.0*(float(seed)+0.5)*diver-1.0)*len;
    seed=ChurnSeed(seed);
    id=seed;

    //Возвращаем исходную систему координат
    p=(xc+vec3(dx,dy,dz))*grid_size;
    //На всякий случай возвращаем расстояние до узла, но пока это не используется.
    return length(p-x);
}
