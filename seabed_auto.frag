#version 420 core

uniform vec3 cam_center;
uniform vec3 cam_front;

in vec3 world_X;
//in vec3 world_N;
in vec3 base_X;
in vec4 srn_val;


layout(location=0) out vec4 depth;
layout(location=1) out vec4 srn;


//vec3 sun_pos=vec3(5000.0,5000.0,10000.0);


void main()
{    
    depth=vec4(base_X,dot((world_X-cam_center),cam_front));
    srn=srn_val;
    /*
    vec3 Nv=normalize(world_N);

    vec3 view_vec=normalize(cam_center-world_X); //Вектор на наблюдателя
    vec3 sun_vec=normalize(sun_pos-world_X);

    float dif_k=max(0.0,dot(sun_vec,Nv));
    vec4 dif_scaler=vec4(dif_k,dif_k,dif_k,1.0);

    vec4 seabed_col=vec4(1.0,1.0,1.0,1.0);
    vec4 col=seabed_col*dif_scaler;

    vec4 spec_color=vec4(0.3,0.3,0.3,0.3);
    float spec_pow=30.0;

    float spec_k=pow(max(0.0,dot(view_vec,normalize(reflect(-sun_vec,Nv)))),spec_pow);
    vec4 spec_scale=vec4(spec_k,spec_k,spec_k,0.0);


    fColor=col+spec_scale*spec_color;
    */
}
