Shader"Custom/TessShader"
{
    Properties
    {
        _Amplitude ("Amplitude", Float) = 0.1
        _Offset ("Offset (b)", Float) = 0.0
        _Mode ("Deformation Mode (0: Parabola, 1: Sine)", Float) = 0
        _TessellationFactor ("Tessellation Factor", Range(1, 64)) = 8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            #pragma target 4.6

            #include "UnityCG.cginc"

            // Properties
            float _Amplitude;
            float _TessellationFactor;
            float _Offset;
            float _Mode; // 0 for parabola, 1 for sine

            struct appdata
            {
                float4 vertex : POSITION; // Vertex position in object space
            };

            struct d2f
            {
                float4 pos : SV_POSITION; // Clip-space position
                float3 worldPos : TEXCOORD0; // World-space position for further processing
                float3 normal : TEXCOORD1; // World-space normal
            };

            struct TessControlPoint
            {
                float4 vertex : POSITION; // Vertex position in object space
                float3 worldPos : TEXCOORD0; // World-space position
            };

            // Vertex Shader
            TessControlPoint vert(appdata v)
            {
                TessControlPoint o;
                o.vertex = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            struct HS_PER_PATCH_OUTPUT
            {
                float edges[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // Hull Shader
            [domain("tri")]
            [partitioning("integer")] // Integer partitioning mode
            [outputtopology("triangle_cw")] // Clockwise triangles
            [patchconstantfunc("tessellationFactors")] // Patch constant function
            [outputcontrolpoints(3)] // Number of control points to emit
            TessControlPoint hull(InputPatch<TessControlPoint, 3> points, uint id : SV_OutputControlPointID)
            {
                TessControlPoint o;
                o.vertex = points[id].vertex;
                o.worldPos = points[id].worldPos;
                return o;
            }

            // Patch Constant Function
            HS_PER_PATCH_OUTPUT tessellationFactors(InputPatch<TessControlPoint, 3> points)
            {
                // How to calculate tessellation factors?!!!!
    
                HS_PER_PATCH_OUTPUT o;
                // Calculate tessellation factor based on edge lengths
                float3 p0 = points[0].worldPos.xyz;
                float3 p1 = points[1].worldPos.xyz;
                float3 p2 = points[2].worldPos.xyz;
                if (_Mode < 0.5)
                {
                    p0.y += (_Amplitude * 0.1 * p0.z * p0.z + _Offset);
                    p1.y += (_Amplitude * 0.1 * p1.z * p1.z + _Offset);
                    p2.y += (_Amplitude * 0.1 * p2.z * p2.z + _Offset);
                }
                else
                {
                    p0.y += (_Amplitude * sin(p0.z) + _Offset);
                    p1.y += (_Amplitude * sin(p1.z) + _Offset);
                    p2.y += (_Amplitude * sin(p2.z) + _Offset);
                }
    

    
                float len0 = distance(p1, p2);
                float len1 = distance(p0, p2);
                float len2 = distance(p0, p1);

                //float avgLen = (len0 + len1 + len2) / 3.0;
                //float tessFactor = saturate(avgLen / 10) * _TessellationFactor;
    
                float tessFactor0 = saturate(len0 / 10) * _TessellationFactor;
                float tessFactor1 = saturate(len1 / 10) * _TessellationFactor;
                float tessFactor2 = saturate(len2 / 10) * _TessellationFactor;
                o.edges[0] = tessFactor0;
                o.edges[1] = tessFactor1;
                o.edges[2] = tessFactor2;
                o.inside = (o.edges[0] + o.edges[1] + o.edges[2]) / 3; // The number of interior vertices generated is approximately related to the square of inside
                
                return o;
            }

            // Domain Shader
            [domain("tri")]
            d2f domain(HS_PER_PATCH_OUTPUT i, const OutputPatch<TessControlPoint, 3> cp, float3 bary : SV_DomainLocation)
            {
                d2f o;

                // Interpolate positions using barycentric coordinates
                float3 p0 = cp[0].worldPos.xyz;
                float3 p1 = cp[1].worldPos.xyz;
                float3 p2 = cp[2].worldPos.xyz;

                float3 worldPos = p0 * bary.x + p1 * bary.y + p2 * bary.z;

                // Calculate the displacement
                float z = worldPos.z;
    
                // Compute gradients
                float3 dp1 = p1 - p0;
                float3 dp2 = p2 - p0;
    
                if (_Mode < 0.5) 
                {
                    worldPos.y += (_Amplitude * 0.1 * z * z + _Offset);
                    dp1.y += _Amplitude * 0.1 * (2.0 * dp1.z * z); // Adjust for displacement gradient in y
                    dp2.y += _Amplitude * 0.1 * (2.0 * dp2.z * z); // Adjust for displacement gradient in y

                }
                else
                {
                    worldPos.y += (_Amplitude * sin(z) + _Offset);
        
                    dp1.y += _Amplitude * cos(z) * dp1.z; // Adjust for displacement gradient in y
                    dp2.y += _Amplitude * cos(z) * dp2.z; // Adjust for displacement gradient in y
                }
    


                // Compute normal using cross product of gradients
                float3 normal = normalize(cross(dp1, dp2));

                // Output
                o.worldPos = worldPos;
                o.pos = UnityObjectToClipPos(float4(worldPos, 1.0));

                // Attach normal to output
                o.normal = normal;

                return o;
            }

            // Fragment Shader
            half4 frag(d2f i) : SV_Target
            {
                // Simple lighting using normal
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    
                float diffuse = saturate(dot(i.normal, lightDir));
                return half4(0.3 * diffuse, 0.6 * diffuse, 0.9 * diffuse, 1.0); // Modulate light blue color
            }
            ENDCG
        }
    }
}
