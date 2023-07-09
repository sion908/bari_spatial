Shader "Custom/leaf"
{
    Properties {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _FrontAlpha ("Front Alpha", Range(0, 1)) = 1
        _BackAlpha ("Back Alpha", Range(0, 1)) = 0
    }
    
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        
        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata {
                float4 vertex : POSITION;
            };
            
            struct v2f {
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD0;
            };
            
            float4 _Color;
            float _FrontAlpha;
            float _BackAlpha;
            
            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewDir = normalize(UnityWorldSpaceViewDir(v.vertex));
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                float alpha = dot(i.viewDir, float3(0, 0, -1)) > 0 ? _BackAlpha : _FrontAlpha;
                return _Color * alpha;
            }
            ENDCG
        }
    }
}
