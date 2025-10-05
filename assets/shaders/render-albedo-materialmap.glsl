uniform sampler2DArray MainTex;

void effect()
{
    // Sample the 3 layers from the texture array
    vec4 layer0 = Texel(MainTex, vec3(VaryingTexCoord.xy, 0.0));
    vec4 layer1 = Texel(MainTex, vec3(VaryingTexCoord.xy, 1.0));
    vec4 layer2 = Texel(MainTex, vec3(VaryingTexCoord.xy, 2.0));
    
    // Output each layer to its corresponding canvas
    love_Canvases[0] = layer0 * VaryingColor;
    love_Canvases[1] = layer1 * VaryingColor;
    love_Canvases[2] = layer2 * VaryingColor;
}