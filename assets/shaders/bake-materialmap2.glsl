extern Image emissionMap;   
extern Image occlusionMap;  
extern Image heightMap; 

extern float emissionWeight;    // 1.0 if real map, 0.0 if dummy
extern float occlusionWeight;
extern float heightWeight;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // --- Red channel: emission/occlusion with alpha priority encoding
    vec4 emissionSample = Texel(emissionMap, uv);
    vec4 occlusionSample = Texel(occlusionMap, uv);
    
    float emissionAlpha = emissionSample.a * emissionWeight;
    float occlusionAlpha = occlusionSample.a * occlusionWeight;
    
    float emOccChannel;
    if (emissionAlpha > 0.0) {
        // Emission takes priority, map alpha to 0.5-1.0 range
        emOccChannel = 0.5 + (emissionAlpha * 0.5);
    } else if (occlusionAlpha > 0.0) {
        // Occlusion, map alpha to 0.0-0.5 range
        emOccChannel = max((1.0 - occlusionAlpha) * 0.5, 0.002);
    } else {
        // Default value when both alphas are 0
        emOccChannel = 0.0;
    }

    // --- Green channel: height
    float height = Texel(heightMap, uv).r;
    height = mix(0.0, height, heightWeight);

    // --- Blue channel: blank (0.0)
    float blueChannel = 0.0;

    return vec4(emOccChannel, height, blueChannel, 1.0);
}