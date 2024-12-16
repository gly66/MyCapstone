Shader"Custom/TrailAccumulation"
{
    Properties
    {
        _MainTex ("Base (Height Map)", 2D) = "white" {}
        _TrailTex ("Trail (New Movement)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex; 
            sampler2D _TrailTex;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
          
                float4 current = tex2D(_MainTex, i.uv);

    
                float4 trail = tex2D(_TrailTex, i.uv);

         
                current.r = saturate(current.r + trail.r);

      
                return current;
            }
                        ENDCG
                    }
                }
}
