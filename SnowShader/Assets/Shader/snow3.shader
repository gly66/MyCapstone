Shader"Custom/snow3"
{
    Properties
    {
        _Albedo ("Albedo", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _HeightMap ("Height Map", 2D) = "black" {}
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        _ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0.02
        _Smoothness ("Smoothness", Range(0,1)) = 0.4
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        
sampler2D _Albedo, _NormalMap, _HeightMap, _OcclusionMap;
float _ParallaxStrength, _Smoothness, _Metallic;
        
struct Input
{
    float2 uv_Albedo;
    float2 uv_NormalMap;
    float2 uv_HeightMap;
    float2 uv_OcclusionMap;
    float3 viewDir;
};
        
void surf(Input IN, inout SurfaceOutputStandard o)
{
            // Parallax Mapping (height-based offset UVs)
    float height = tex2D(_HeightMap, IN.uv_HeightMap).r;
    float2 parallaxOffset = (height - 0.5) * _ParallaxStrength * normalize(IN.viewDir).xy;
    float2 uv = IN.uv_Albedo + parallaxOffset;
            
            // Texture Sampling
    fixed4 albedo = tex2D(_Albedo, uv);
    fixed3 normal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
    fixed occlusion = tex2D(_OcclusionMap, IN.uv_OcclusionMap).r;
            
            // Apply a subtle blue tint to the snow
    albedo.rgb = lerp(albedo.rgb, fixed3(0.9, 0.95, 1.0), 0.2);
            
            // Assign Values
    o.Albedo = albedo.rgb * occlusion; // Apply occlusion effect
    o.Normal = normal;
    o.Smoothness = _Smoothness;
    o.Metallic = _Metallic;
}
        ENDCG
    }
FallBack"Diffuse"
}