// Illumination part codes created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
Shader "Dynamic Snow" {
    Properties {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("Base Color", 2D) = "bump" {}
        [MaterialToggle] _UseLowerLayer ("Use Lower Layer", Float ) = 0
        _LowerLayer ("Lower Layer", Color) = (0.1862024,0.5477839,0.9044118,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecMap ("Spec Map", 2D) = "white" {}
        _GlossColor ("Gloss Color", Color) = (1,1,1,1)
        _GlossMap ("Gloss Map", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Heigth ("Initial Heigth", 2D) = "black" {}
        _TrailMap ("Trail Map", 2D) = "white" {}
        _InitialHeight ("InitialHeight", Float ) = 1
        _DisplacementStrength ("Displacement Strength", Float ) = 1
        _BlurSize ("Blur Size", Float) = 0.001
        _DistanceBlend ("Distance Blend", Float ) = 0
        _TesselationEdgeLength ("Tesselation Edge Length", Float ) = 20
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex tessvert
            #pragma hull hull
            #pragma domain domain
            //#pragma geometry gs
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "Tessellation.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"

            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma target 5.0

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform sampler2D _TrailMap; uniform float4 _TrailMap_ST;
            uniform float _InitialHeight;
            uniform float _DisplacementStrength;
            uniform float _BlurSize;
            uniform float4 _LowerLayer;
            uniform float _DistanceBlend;
            uniform sampler2D _Heigth; uniform float4 _Heigth_ST;
            uniform sampler2D _GlossMap; uniform float4 _GlossMap_ST;
            uniform sampler2D _SpecMap; uniform float4 _SpecMap_ST;
            uniform fixed _UseLowerLayer;
            uniform float4 _BaseColor;
            uniform float4 _SpecularColor;
            uniform float4 _GlossColor;
            uniform float _TesselationEdgeLength;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;

            };
            struct VertexOutput {
    
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD3;
                float3 normalDir : TEXCOORD4;
                float3 tangentDir : TEXCOORD5;
                float3 bitangentDir : TEXCOORD6;
                LIGHTING_COORDS(7,8)
                UNITY_FOG_COORDS(9)
                #if defined(LIGHTMAP_ON) || defined(UNITY_SHOULD_SAMPLE_SH)
                    float4 ambientOrLightmapUV : TEXCOORD10;
                #endif
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;


                #ifdef LIGHTMAP_ON
                    o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.ambientOrLightmapUV.zw = 0;
                #elif UNITY_SHOULD_SAMPLE_SH
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    o.ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            struct TessVertex {
                float4 vertex : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;

            };
            struct OutputPatchConstant {
                float edge[3]         : SV_TessFactor;
                float inside          : SV_InsideTessFactor;
                float3 vTangent[4]    : TANGENT;
                float2 vUV[4]         : TEXCOORD;
                float3 vTanUCorner[4] : TANUCORNER;
                float3 vTanVCorner[4] : TANVCORNER;
                float4 vCWts          : TANWEIGHTS;
            };
            TessVertex tessvert (VertexInput v) {
                TessVertex o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.texcoord0 = v.texcoord0;

                return o;
            }

            float3 displacement (inout VertexInput v){
    
                /// 5x5 Sampling with GaussianBlur
    
                float3 blurredHeigthRGB = float3(0.0, 0.0, 0.0);
                float3 blurredTrailMapRGB = float3(0.0, 0.0, 0.0);
                float2 uv = TRANSFORM_TEX(v.texcoord0, _TrailMap);
    
                float gaussianWeights[25] =
                {
                    0.003765, 0.015019, 0.023792, 0.015019, 0.003765,
                    0.015019, 0.059912, 0.094907, 0.059912, 0.015019,
                    0.023792, 0.094907, 0.150342, 0.094907, 0.023792,
                    0.015019, 0.059912, 0.094907, 0.059912, 0.015019,
                    0.003765, 0.015019, 0.023792, 0.015019, 0.003765
                };

                int index = 0;
                for (int i = -2; i <= 2; i++)
                {
                    for (int j = -2; j <= 2; j++)
                    {
                        float2 offset = float2(i, j) * _BlurSize;
                        float4 uv_lod = float4(uv + offset, 0, 0);
                        float3 sampleColor = tex2Dlod(_TrailMap, uv_lod).rgb;
                        float3 sampleHeigthColor = tex2Dlod(_Heigth, uv_lod).rgb;
                        blurredTrailMapRGB += sampleColor * gaussianWeights[index];
                        blurredHeigthRGB += sampleHeigthColor * gaussianWeights[index];
                        index++;
                    }
                }
    
                float3 initialHeight = blurredTrailMapRGB * _InitialHeight;
                /// original trail is black, invert it and get white representing deformed trail: if not, more black, rgb is closer to 0. the displacement will be 0
                float3 invertedTrailMap = 1.0 - blurredTrailMapRGB;
                float3 trailDisplacement = invertedTrailMap * _DisplacementStrength;
                
                /// Smooth the trail edge. The logic is: lower down the very white place, rise up the dark(not that white)place, and have a smoothy transition.
    
                //float whiteness = saturate((invertedTrailMap.r + invertedTrailMap.g + invertedTrailMap.b) / 3.0);
                //// if whiteness < 0.2 then flipFactor = 0, if whiteness > 0.8 then flipFactor = 1, if 0.2 < whiteness < 0.8, then flipFactor is set in range(0,1) smoothly
                //float flipFactor = 1 - smoothstep(0.2, 0.8, whiteness); 
                //// if flipFactor = 1 return trailDisplacement, if flipFactor = 0 return -trailDisplacement, else return linear interpolate value of (-trailDisplacement, trailDisplacement)
                //trailDisplacement = lerp(trailDisplacement, -trailDisplacement, flipFactor);
                float3 finalDisplacement = ((initialHeight - trailDisplacement) * v.normal);
                return finalDisplacement;
                //v.vertex.xyz += ((initialHeight - trailDisplacement) * v.normal);
            }
			// Edge length in clip space
            float edgeLength(float4 v1, float4 v2)
            {
				
                float2 p1 = v1.xyz / v1.w;
                float2 p2 = v2.xyz / v2.w;
    
                return length(p1 - p2);
            }
            float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2){
                // Tessellated based on edge length in clipspace
                return UnityEdgeLengthBasedTess(v.vertex, v1.vertex, v2.vertex, _TesselationEdgeLength);
            }

            OutputPatchConstant hullconst (InputPatch<TessVertex,3> v) {
                OutputPatchConstant o = (OutputPatchConstant)0;
                float4 ts = Tessellation( v[0], v[1], v[2] );
                o.edge[0] = ts.x;
                o.edge[1] = ts.y;
                o.edge[2] = ts.z;
                o.inside = ts.w; // The number of interior vertices generated is approximately related to the square of inside
                //o.inside = ts.w;
                return o;
            }
            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [patchconstantfunc("hullconst")]
            [outputcontrolpoints(3)]
            TessVertex hull (InputPatch<TessVertex,3> v, uint id : SV_OutputControlPointID) {
                return v[id];
            }
            [domain("tri")]
            VertexOutput domain(OutputPatchConstant tessFactors, const OutputPatch<TessVertex, 3> vi, float3 bary : SV_DomainLocation)
            {
                VertexInput v = (VertexInput)0;
                v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
                v.normal = vi[0].normal * bary.x + vi[1].normal * bary.y + vi[2].normal * bary.z;
                v.tangent = vi[0].tangent * bary.x + vi[1].tangent * bary.y + vi[2].tangent * bary.z;
                v.texcoord0 = vi[0].texcoord0*bary.x + vi[1].texcoord0*bary.y + vi[2].texcoord0*bary.z;
                
                float3 displacementAmount = displacement(v);
                v.vertex.xyz += displacementAmount;
    
                //float3 edge1 = v.vertex.xyz - vi[0].vertex.xyz;
                //float3 edge2 = v.vertex.xyz - vi[1].vertex.xyz;
                //float3 edge3 = v.vertex.xyz - vi[2].vertex.xyz;
    
                //float3 normal1 = normalize(cross(edge1, edge2));
                //float3 normal2 = normalize(cross(edge2, edge3));
                //float3 normal3 = normalize(cross(edge3, edge1));
                //v.normal = normalize(normal1 + normal2 + normal3);
    
                 //Set the offset step size
                float offset = 1.0 / 4096; // You can adjust this value to control smoothness

                float2 offsetU = float2(offset, 0.0);
                float2 offsetV = float2(0.0, offset);

                // hexagonal approximation
                VertexInput v1 = v, v2 = v, v3 = v, v4 = v, v5 = v, v6 = v;
                    // Right
                v1.texcoord0 += offsetU;
                    //RightUpCorner
                v2.texcoord0 = v2.texcoord0 + offsetU + offsetV;
                    // Up
                v3.texcoord0 += offsetV;
                    //Left
                v4.texcoord0 -= offsetU;
                    //LeftDownCorner
                v5.texcoord0 = v6.texcoord0 - offsetU - offsetV;
                    //Down
                v6.texcoord0 -= offsetV;
    
                // Map uv offset to vertex offset
                v1.vertex.xyz += float3(1, 0, 0);
                v2.vertex.xyz += float3(1, 0, 1);
                v3.vertex.xyz += float3(0, 0, 1);
                v4.vertex.xyz -= float3(1, 0, 0);
                v5.vertex.xyz -= float3(1, 0, 1);
                v6.vertex.xyz -= float3(0, 0, 1);
    
                // Sample the displaced height field at offset positions
                v1.vertex.xyz += displacement(v1);
                v2.vertex.xyz += displacement(v2);
                v3.vertex.xyz += displacement(v3);
                v4.vertex.xyz += displacement(v4);
                v5.vertex.xyz += displacement(v5);
                v6.vertex.xyz += displacement(v6);
                
                // Edges of adjacent triangle
                float3 edge1 = v.vertex.xyz - v1.vertex.xyz;
                float3 edge2 = v.vertex.xyz - v2.vertex.xyz;
                float3 edge3 = v.vertex.xyz - v3.vertex.xyz;
                float3 edge4 = v.vertex.xyz - v4.vertex.xyz;
                float3 edge5 = v.vertex.xyz - v5.vertex.xyz;
                float3 edge6 = v.vertex.xyz - v6.vertex.xyz;
                
                // Normals of adjacent triangle
                float3 normal1 = normalize(cross(edge1, edge2));
                float3 normal2 = normalize(cross(edge2, edge3));
                float3 normal3 = normalize(cross(edge3, edge4));
                float3 normal4 = normalize(cross(edge4, edge5));
                float3 normal5 = normalize(cross(edge5, edge6));
                float3 normal6 = normalize(cross(edge6, edge1));
    
                // recalculate normals only when there is a displacement
                if (length(displacementAmount) >= 10)
                {
                    v.normal = -normalize(normal1 + normal2 + normal3 + normal4 + normal5 + normal6);
                }

                VertexOutput o = vert(v);
                return o;
            }
            //[maxvertexcount(3)]
            //void gs(triangle VertexInput input[3], inout TriangleStream<VertexOutput> outputStream)
            //{
            //    VertexOutput output[3];

            //    //float3 p0 = input[0].vertex;
            //    //float3 p1 = input[1].vertex;
            //    //float3 p2 = input[2].vertex;
    
            //    float3 p0 = mul(unity_ObjectToWorld, input[0].vertex).xyz;
            //    float3 p1 = mul(unity_ObjectToWorld, input[1].vertex).xyz;
            //    float3 p2 = mul(unity_ObjectToWorld, input[2].vertex).xyz;


            //    float3 edge1 = p1 - p0;
            //    float3 edge2 = p2 - p0;

  
            //    float3 normal = normalize(cross(edge1, edge2));

            //    for (int i = 0; i < 3; i++)
            //    {
            //        VertexInput v = input[i];
            //        //v.normal = normal;
            //        output[i] = vert(v);
            //        output[i].normalDir += normal;
            //        outputStream.Append(output[i]);
            //    }

            //    outputStream.RestartStrip();
            //}


            float4 frag(VertexOutput i) : COLOR
            {

                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float3 normalLocal = _BumpMap_var.rgb;
    
                // blend normals with normal maps
                float3 normalDirection = normalize(mul(normalLocal, tangentTransform) + i.normalDir);
                //float3 normalDirection = i.normalDir;
    
                // View direction and light direction
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
    
                // Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
    
                // Gloss:
                float4 _GlossMap_var = tex2D(_GlossMap,TRANSFORM_TEX(i.uv0, _GlossMap));
                float gloss = (_GlossMap_var.r*_GlossColor.r);
                float perceptualRoughness = 1.0 - (_GlossMap_var.r*_GlossColor.r);
                float roughness = perceptualRoughness * perceptualRoughness;
    
                // GI Data:
                UnityLight light;
                #ifdef LIGHTMAP_OFF
                    light.color = lightColor;
                    light.dir = lightDirection;
                    light.ndotl = LambertTerm (normalDirection, light.dir);
                #else
                    light.color = half3(0.f, 0.f, 0.f);
                    light.ndotl = 0.0f;
                    light.dir = half3(0.f, 0.f, 0.f);
                #endif
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld.xyz;
                d.worldViewDir = viewDirection;
                d.atten = attenuation;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    d.ambient = 0;
                    d.lightmapUV = i.ambientOrLightmapUV;
                #else
                    d.ambient = i.ambientOrLightmapUV;
                #endif
                #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMin[0] = unity_SpecCube0_BoxMin;
                    d.boxMin[1] = unity_SpecCube1_BoxMin;
                #endif
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMax[0] = unity_SpecCube0_BoxMax;
                    d.boxMax[1] = unity_SpecCube1_BoxMax;
                    d.probePosition[0] = unity_SpecCube0_ProbePosition;
                    d.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
                lightDirection = gi.light.dir;
                lightColor = gi.light.color;
    
                // Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float4 _SpecMap_var = tex2D(_SpecMap,TRANSFORM_TEX(i.uv0, _SpecMap));
                float3 specularColor = (_SpecMap_var.rgb*_SpecularColor.rgb);
                float specularMonochrome;
                
                float UseLower = step(0.5, _UseLowerLayer); //Decide blending lower layer or not
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 baseColor = (_MainTex_var.rgb*_BaseColor.rgb);
                float4 _TrailMap_var = tex2D(_TrailMap,TRANSFORM_TEX(i.uv0, _TrailMap));
                float3 lowerLayerColor = lerp(_LowerLayer.rgb, baseColor, _TrailMap_var.rgb);
                float3 mixedColor = lerp(baseColor, lowerLayerColor, UseLower);
                float distanceFactor = saturate(pow(distance(i.posWorld.rgb, _WorldSpaceCameraPos) / _DistanceBlend, 8.0)); 
                float3 diffuseColor = lerp(mixedColor, baseColor, distanceFactor); // Need this for specular when using metallic. And blend based on distance. If is far away, only show base color
                diffuseColor = EnergyConservationBetweenDiffuseAndSpecular(diffuseColor, specularColor, specularMonochrome);
    
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = abs(dot( normalDirection, viewDirection ));
                float NdotH = saturate(dot( normalDirection, halfDirection ));
                float VdotH = saturate(dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, roughness );
                float normTerm = GGXTerm(NdotH, roughness);
                float specularPBL = (visTerm*normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;
                #else
                    surfaceReduction = 1.0/(roughness*roughness + 1.0);
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                half grazingTerm = saturate( gloss + specularMonochrome );
                float3 indirectSpecular = (gi.indirect.specular);
                indirectSpecular *= FresnelLerp (specularColor, grazingTerm, NdotV);
                indirectSpecular *= surfaceReduction;
                float3 specular = (directSpecular + indirectSpecular);
    
                /////// Diffuse:
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotL);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += gi.indirect.diffuse;
                diffuseColor *= 1-specularMonochrome;
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
    
                // Final Color:
                float3 finalColor = diffuse + specular;
                return fixed4(finalColor, 1);
                

            }
            ENDCG
        }
        Pass {
            Name"Shadow"
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            Offset 1, 1
            Cull Back
            
            CGPROGRAM
 
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma target 5.0
            #include "UnityCG.cginc"


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;

            };
            struct VertexOutput
            {
                V2F_SHADOW_CASTER;

                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.uv0 = v.texcoord0;
                TRANSFER_SHADOW_CASTER(o)

                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    
}
