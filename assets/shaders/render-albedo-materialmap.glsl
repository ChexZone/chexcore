uniform sampler2D albedoTexture;
uniform sampler2D materialTexture;

void effect()
{
    // Sample both textures at the same UV coordinates
    vec4 albedoColor = Texel(albedoTexture, VaryingTexCoord.xy);
    vec4 materialColor = Texel(materialTexture, VaryingTexCoord.xy);
    
    // Apply the vertex color (from love.graphics.setColor) to the albedo
    love_Canvases[0] = albedoColor * VaryingColor;
    
    // Material properties usually don't get tinted, but you could apply it if needed
    love_Canvases[1] = materialColor; // or materialColor * VaryingColor if you want tinting
}