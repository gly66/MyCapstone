Shader"Custom/TessSnowShader"
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
        _BaseColor ("Base Color", Color) = (0.9, 0.9, 1.0, 1) // Soft blue tint for snow base color
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hs
			#pragma domain ds
            #pragma target 5.0  // Ensure shader model is 4.0 or higher
            
            #include "HLSLSupport.cginc"
            #include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Tessellation.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

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


			// hull constant shader ouput(tessellation factors)
            struct HS_PER_PATCH_OUTPUT
            {
                float edges[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct HS_INPUT
            {
                float4 vertex : POSITION;
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2; // Pass tangent to fragment shader
            };
            struct DS_INPUT
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2; // Pass tangent to fragment shader
            };
            struct FS_INPUT
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2; // Pass tangent to fragment shader
                float3 bitangent : TEXCOORD3; // Pass bitangent to fragment shader
                float3 worldPos : TEXCOORD4;
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

            HS_INPUT vert(appdata v)
            {
                HS_INPUT o;
                o.vertex = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.tangent = v.tangent;

                return o;
            }
            float edgeLength(float4 v1, float4 v2)
            {
				
                float2 p1 = v1.xyz / v1.w;
                float2 p2 = v2.xyz / v2.w;
    
                return length(p1 - p2);
            }
			//  Tessellation Factor
            float tessellationFactor(float edge1, float edge2, float edge3, float screenSize)
            {
                float targetLength = 0.03 * screenSize; // screen size 3%
                return max(max(edge1 / targetLength, edge2 / targetLength), edge3 / targetLength);
            }

			// tessellation hull constant shader, calculate the tessllation factors.
            HS_PER_PATCH_OUTPUT hsconst(InputPatch<HS_INPUT, 3> v)
            {
                HS_PER_PATCH_OUTPUT o;

                float factor0 = edgeLength(v[1].pos, v[2].pos) * _ScreenParams.y * 0.03;
                float factor1 = edgeLength(v[2].pos, v[0].pos) * _ScreenParams.y * 0.03;
                float factor2 = edgeLength(v[0].pos, v[1].pos) * _ScreenParams.y * 0.03;
				//float factor = max(1.f,(factor0 + factor1 + factor2) / 3.f);
	
				//float distanceToCamera = distance(_CameraPosition, (worldPos0 + worldPos1) * 0.5) * 0.1;
				// Decide how many segments the edge is divided into
                o.edges[0] = factor0;
                o.edges[1] = factor1;
                o.edges[2] = factor2;
                o.inside = (o.edges[0] + o.edges[1] + o.edges[2]) / 3; // The number of interior vertices generated is approximately related to the square of inside
                return o;
            }
			
			// here is a tessellator!

			// tessellation hull shader
            [UNITY_domain("tri")] // Signal we're inputting triangles
            [UNITY_partitioning("integer")] // Select a partitioning mode: integer, fractional_odd, fractional_even or pow2
            [UNITY_outputtopology("triangle_cw")] // Signal we're outputting triangle
            [UNITY_patchconstantfunc("hsconst")] // Register the patch constant function
            [UNITY_outputcontrolpoints(3)] // Triangles have three points

			DS_INPUT hs(InputPatch<HS_INPUT, 3> i, uint pointID : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID)
            {
                DS_INPUT o;
                o.vertex = i[pointID].vertex;
                o.uv = i[pointID].uv;
                o.normal = i[pointID].normal;
                o.tangent = i[pointID].tangent;
                return o;
            }
           
            [domain("tri")]
			FS_INPUT ds(HS_PER_PATCH_OUTPUT i, const OutputPatch<DS_INPUT, 3> vi, float3 bary : SV_DomainLocation)
            {
                FS_INPUT o;
                
    
                return o;
            }

            fixed4 frag(FS_INPUT i) : SV_Target
            {
    
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
