Shader"Custom/ParabolicTessellation"
{
    Properties
    {
        _Amplitude ("Amplitude", Float) = 0.1
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

            struct appdata
            {
                float4 vertex : POSITION; // Vertex position in object space
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // Clip-space position
                float3 worldPos : TEXCOORD0; // World-space position for further processing
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
            [partitioning("integer")] // Fractional tessellation for smooth transitions
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
    
                p0.y += _Amplitude * p0.z * p0.z;
                p1.y += _Amplitude * p1.z * p1.z;
                p2.y += _Amplitude * p2.z * p2.z;
    
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
            v2f domain(HS_PER_PATCH_OUTPUT i, const OutputPatch<TessControlPoint, 3> cp, float3 bary : SV_DomainLocation)
            {
                // How to deform?
                v2f o;
                //o.vertex = cp[0].vertex * bary.x + cp[1].vertex * bary.y + cp[2].vertex * bary.z;
                // Interpolate positions using barycentric coordinates
                o.worldPos = cp[0].worldPos.xyz * bary.x + cp[1].worldPos.xyz * bary.y + cp[2].worldPos.xyz * bary.z;

                // Apply parabolic deformation
                //float u = bary.y; // Assuming deformation happens along one dimension
                //float deformation = _Amplitude * u * u;
                float z = o.worldPos.z; // 当前顶点的 z 坐标
                o.worldPos.y += _Amplitude * z * z;

               // o.worldPos = mul(unity_ObjectToWorld, o.vertex).xyz;
                o.pos = UnityObjectToClipPos(float4(o.worldPos, 1.0));
               return o;
            }

            // Fragment Shader
            half4 frag(v2f i) : SV_Target
            {
                return half4(0.3, 0.6, 0.9, 1.0); // Light blue
            }
            ENDCG
        }
    }
}
