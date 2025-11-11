uniform sampler2DArray MainTex;
extern float rotation;

void effect()
{
    // layer0 rgba: UV
    // layer1 rg: surface normal
    // layer1 b: specular map
    // layer2 r: emission/occlusion
    // layer2 g: height map
    // layer2 b: rotation

    // Sample the 3 layers from the texture array
    vec4 layer0 = Texel(MainTex, vec3(VaryingTexCoord.xy, 0.0));
    vec4 layer1 = Texel(MainTex, vec3(VaryingTexCoord.xy, 1.0));
    vec4 layer2 = Texel(MainTex, vec3(VaryingTexCoord.xy, 2.0));
    
    // Set the blue component to the rotation extern only if it's 0.0
    layer2.b = mix(rotation, layer2.b, step(0.001, layer2.b));
    
    // Output each layer to its corresponding canvas
    // Multiply RGB by alpha, keep alpha separate
    vec4 output0 = vec4(0.0,0.0,0.0,1.0);
    love_Canvases[0] = output0;
    love_Canvases[1] = layer1 * layer0.a; // * VaryingColor.a;
    love_Canvases[2] = layer2 * layer0.a; // * VaryingColor.a;
}