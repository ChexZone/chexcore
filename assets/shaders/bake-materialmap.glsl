#pragma language glsl3


extern Image normalMap;   
extern Image specularMap;  

extern float normalWeight;    // 1.0 if real map, 0.0 if dummy
extern float specularWeight;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // --- Normal
    vec3 n = Texel(normalMap, uv).rgb * 2.0 - 1.0;
    vec2 enc = n.xy * 0.5 + 0.5;
    // default = flat normal (0.5, 0.5)
    enc = mix(vec2(0.5, 0.5), enc, normalWeight);

    // --- Specular
    float spec = Texel(specularMap, uv).r;
    spec = mix(0.0, spec, specularWeight);
    
    return vec4(enc, spec, 1.0);
}