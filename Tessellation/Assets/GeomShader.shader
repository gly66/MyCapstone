Shader"Custom/GeomShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _QuadSize ("Quad Size", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2g
            {
                float4 pos : POSITION;
                float3 worldPos : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float normal : NORMAL;

            };

            float _QuadSize;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            [maxvertexcount(6)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                // replace the triangle with a quad(two triangles and 6 vertices)
                float size = _QuadSize;
                float4 center = (input[0].pos + input[1].pos + input[2].pos) / 3.0;
                
    
                // Compute the normal using cross product of two edges
                float3 edge1 = input[1].worldPos - input[0].worldPos;
                float3 edge2 = input[2].worldPos - input[0].worldPos;
                float3 normal = normalize(cross(edge1, edge2));
    
                // set the vertices
                g2f quad[4];
                quad[0].pos = center + float4(-size, -size, 0, 0);
                quad[0].uv = float2(0, 0);
                quad[0].normal = normal;
                quad[1].pos = center + float4(-size, size, 0, 0);
                quad[1].uv = float2(0, 1);
                quad[1].normal = normal;
                quad[2].pos = center + float4(size, size, 0, 0);
                quad[2].uv = float2(1, 1);
                quad[2].normal = normal;
                quad[3].pos = center + float4(size, -size, 0, 0);
                quad[3].uv = float2(1, 0);
                quad[3].normal = normal;

                // Emit two triangles to form the quad
                triStream.Append(quad[1]);   // Lower left
                triStream.Append(quad[0]);   // Upper left
                triStream.Append(quad[2]);   // Upper right
                triStream.RestartStrip(); // Restart build triangle
                triStream.Append(quad[0]);
                triStream.Append(quad[2]);
                triStream.Append(quad[3]);   // Lower left

            }

            sampler2D _MainTex;

            fixed4 frag(g2f i) : SV_Target
            {
                // directional light direction
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // conpute diffuse
                float diff = max(dot(i.normal, lightDir), 0.0);
                fixed4 texColor = tex2D(_MainTex, i.uv);
                return half4(0.3 * diff, 0.6 * diff, 0.9 * diff, 1.0);
            }
            ENDCG
        }
    }
}
