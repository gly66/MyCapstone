Shader"Custom/DeformShader"
{
    Properties
    {
        _HeightMap ("Height Map", 2D) = "white" {} // Height Map (Black and Red)
        _BlurSize ("Blur Size", Float) = 0.01
        _HeightMultiplier ("Height Multiplier", Float) = 1.0
        _SnowNormalMap ("Snow Normal Map", 2D) = "bump" {} // New Normal Map for Snow details
        _NormalStrength ("Normal Strength", Float) = 1.0 // Strength of the normal map effect
        _Shininess ("Shininess", Float) = 32.0 // Controls the size and sharpness of specular highlights
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1) // Specular highlight color
        _BaseColor ("Base Color", Color) = (1, 1, 1., 1) // Soft blue tint for snow base color
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0  // Ensure shader model is 4.0 or higher

        #include "UnityCG.cginc"

        sampler2D _HeightMap;
        sampler2D _SnowNormalMap; // New Normal Map
        float _BlurSize;
        float _HeightMultiplier;
        float _NormalStrength; // Strength of normal map
        float _Shininess; // Shininess factor for specular highlight
        fixed4 _SpecularColor; // Color of the specular highlights
        fixed4 _BaseColor; // Base color for soft blue tint

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT; // Add tangent for normal map space transformation
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : TEXCOORD1;
            float3 tangent : TEXCOORD2; // Pass tangent to fragment shader
            float3 bitangent : TEXCOORD3; // Pass bitangent to fragment shader
        };

        // Function to calculate height based on blurred TrailMap sampling
        float CalculateHeight(float2 uv)
        {
            float mean_height = 0.0;

            // Sampling a 3x3 area for height averaging
            for (int i = -1; i <= 1; i++)
            {
                for (int j = -1; j <= 1; j++)
                {
                    float2 offset = float2(i, j) * _BlurSize;
                    float4 uv_lod = float4(uv + offset, 0, 0); // LOD = 0
                    mean_height += tex2Dlod(_HeightMap, uv_lod).r;
                }
            }
            mean_height /= 9.0;
            return saturate(mean_height) * _HeightMultiplier;
        }

        v2f vert(appdata v)
        {
            v2f o;
            o.uv = v.uv;

            // Sample the current vertex height
            float heightPos = CalculateHeight(v.uv);
            v.vertex.y -= heightPos;

            // Sample heights at adjacent points to calculate the normal
            float heightL = CalculateHeight(v.uv + float2(-_BlurSize, 0));
            float heightR = CalculateHeight(v.uv + float2(_BlurSize, 0));
            float heightD = CalculateHeight(v.uv + float2(0, -_BlurSize));
            float heightU = CalculateHeight(v.uv + float2(0, _BlurSize));

            // Calculate the normal using cross product of surrounding height differences
            float3 dx = float3(2.0 * _BlurSize, heightR - heightL, 0.0);
            float3 dz = float3(0.0, heightU - heightD, 2.0 * _BlurSize);
            o.normal = normalize(cross(dz, dx));

            // Calculate tangent and bitangent for normal map space conversion
            o.tangent = normalize(mul((float3x3) unity_ObjectToWorld, v.tangent.xyz));
            o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;

            // Transform the vertex to clip space
            o.pos = UnityObjectToClipPos(v.vertex);

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            //SurfaceOutputStandard s;
            //s.Metallic = _SpecPow;
            //s.Smoothness = _GlossPow;
            float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                
            // Fetch normal map detail in tangent space
            float3 normalMapDetail = tex2D(_SnowNormalMap, i.uv).rgb * 2.0 - 1.0; // Convert to [-1, 1]

            // Create TBN matrix to transform normal map from tangent space to world space
            float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
            float3 worldNormalMap = normalize(mul(TBN, normalMapDetail)); // Transform to world space
                
            // Combine the original world normal with the normal map detail
            float3 combinedNormal = normalize(i.normal + _NormalStrength * worldNormalMap);
                
            // Diffuse lighting calculation using the combined normal
            float nDotL = max(0, dot(combinedNormal, lightDir));

            // Specular lighting calculation
            float3 viewDir = normalize(_WorldSpaceCameraPos - i.pos.xyz);
            float3 reflectDir = reflect(-lightDir, combinedNormal);
            float spec = pow(max(dot(viewDir, reflectDir), 0.0), _Shininess);
            
            // Final color combining base color, diffuse, and specular contributions
            fixed4 color = _BaseColor * nDotL + _SpecularColor * spec;

            return color;
        }
        ENDCG
        }
    }
}
