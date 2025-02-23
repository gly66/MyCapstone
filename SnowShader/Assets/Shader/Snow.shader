Shader"Custom/Snow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1) // 基础颜色
        _MainTex ("Albedo (RGB)", 2D) = "white" {} // 漫反射贴图
        _NormalMap ("Normal Map", 2D) = "bump" {} // 法线贴图
        _OcclusionMap ("Occlusion Map", 2D) = "white" {} // 环境光遮挡贴图
        _Metallic ("Metallic", Range(0,1)) = 0.0 // 金属度
        _Glossiness ("Smoothness", Range(0,1)) = 0.5 // 光滑度
        _OcclusionStrength ("Occlusion Strength", Range(0,1)) = 1.0 // 环境光遮挡强度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
#include "UnityCG.cginc"

            // 属性变量
sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _OcclusionMap;
float4 _Color;
float _Metallic;
float _Glossiness;
float _OcclusionStrength;

            // 输入结构
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

            // 输出结构
struct v2f
{
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
    float3 worldTangent : TEXCOORD3;
    float3 worldBitangent : TEXCOORD4;
    float4 pos : SV_POSITION;
};

            // 顶点着色器
v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;

                // 计算世界空间法线、切线和副切线
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
    o.worldBitangent = cross(o.worldNormal, o.worldTangent) * v.tangent.w;

                // 计算世界空间顶点位置
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

    return o;
}

            // 手动计算 Fresnel 反射
float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

            // 手动计算法线分布函数（NDF）
float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = UNITY_PI * denom * denom;

    return nom / denom;
}

            // 手动计算几何遮蔽函数（Geometry Function）
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx1 = GeometrySchlickGGX(NdotV, roughness);
    float ggx2 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

            // 片段着色器
fixed4 frag(v2f i) : SV_Target
{
                // 采样漫反射贴图并乘以基础颜色
    fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;

                // 采样法线贴图并解包到切线空间法线
    float3 tangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));

                // 构建 TBN 矩阵（切线空间到世界空间的转换矩阵）
    float3x3 TBN = float3x3(i.worldTangent, i.worldBitangent, i.worldNormal);
    float3 worldNormal = normalize(mul(TBN, tangentNormal));

                // 直接使用 _Metallic 和 _Glossiness 属性
    float metallic = _Metallic; // 金属度
    float roughness = 1.0 - _Glossiness; // 粗糙度（1 - 光滑度）

                // 采样环境光遮挡贴图并应用强度
    float occlusion = lerp(1.0, tex2D(_OcclusionMap, i.uv).r, _OcclusionStrength);

                // 计算光照方向
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算视线方向
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                // 计算半角向量
    float3 halfDir = normalize(lightDir + viewDir);

                // 计算基础反射率 F0
    float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo.rgb, metallic);

                // 计算 Fresnel 反射
    float3 F = FresnelSchlick(max(dot(halfDir, viewDir), 0.0), F0);

                // 计算法线分布函数（NDF）
    float NDF = DistributionGGX(worldNormal, halfDir, roughness);

                // 计算几何遮蔽函数（Geometry Function）
    float G = GeometrySmith(worldNormal, viewDir, lightDir, roughness);

                // 计算 Cook-Torrance BRDF
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(worldNormal, viewDir), 0.0) * max(dot(worldNormal, lightDir), 0.0);
    float3 specular = numerator / max(denominator, 0.001);

                // 计算漫反射
    float3 kS = F; // 高光反射比例
    float3 kD = (1.0 - kS) * (1.0 - metallic); // 漫反射比例

                // 最终光照
    float3 finalColor = (kD * albedo.rgb / UNITY_PI + specular) * max(dot(worldNormal, lightDir), 0.0) * occlusion;

    return fixed4(lightDir, 1.0); // 直接返回光照方向可视化结果

}
            ENDCG
        }
    }
FallBack"Diffuse"
}