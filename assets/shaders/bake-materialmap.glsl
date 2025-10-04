extern Image normalMap;    // bound even if dummy
extern Image specularMap;  // bound even if dummy
extern Image emissiveMap;  // bound even if dummy

// use uniforms to blend in defaults (0 or 1)
extern float normalWeight;    // 1.0 if real map, 0.0 if dummy
extern float specularWeight;
extern float emissiveWeight;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // --- Normal
    vec3 n = Texel(normalMap, uv).rgb * 2.0 - 1.0;
    vec2 enc = n.xy * 0.5 + 0.5;
    // default = flat normal (0.5, 0.5)
    enc = mix(vec2(0.5, 0.5), enc, normalWeight);

    // --- Specular
    float spec = Texel(specularMap, uv).r;
    spec = mix(0.0, spec, specularWeight);

    // --- Emissive
    float em = Texel(emissiveMap, uv).r;
    em = mix(0.0, em, emissiveWeight);

    return vec4(enc, em, 1.0);
}