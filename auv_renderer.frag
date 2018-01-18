#version 420
in vec3 N;
in vec3 v;
in vec2 t;
uniform vec3 light_pos;
uniform sampler2D diffuseTex;
out vec4 fragColor;

void main(void)
{
    vec3 L = normalize(light_pos - v);
    vec3 E = normalize(-v);
    vec3 R = normalize(-reflect(L, N));

    vec4 Iambient = vec4(0.1, 0.1, 0.1, 1.0);
    vec4 Idiff = vec4(0.8, 0.8, 0.8, 1.0) * max(dot(N, L), 0.0);
    Idiff = clamp(Idiff, 0.0, 1.0);

    vec4 Ispec = vec4(0.3, 0.3, 0.3, 1.0) * pow(max(dot(R, E), 0.0), 1 * 2);
    Ispec = clamp(Ispec, 0.0, 1.0);

    vec4 texColor = texture2D(diffuseTex, t);

    fragColor = Idiff * texColor + Ispec + Iambient;
}
