Shader "Custom/ground"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal] _NormalTex ("Normal map", 2D) = "bump" {}
        _Main_Scale("Main_Scale",Range (0, 10)) = 2
        _SubTex ("SubTexture", 2D) = "white" {}
        [Normal] _SubNormalTex ("SubNormal map", 2D) = "bump" {}
        _Sub_Scale("Sub_Scale",Range (0, 10)) = 4
        _Blend("Blend",Range (0, 1)) = 1
		_MaskTex ("Mask Texture", 2D) = "white" {}	
        _SpecularLevel("Specular Level", Range(1, 100)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 normal : TEXCOORD1; //法線
                half3 tangent : TEXCOORD2; //接線
                half3 binormal : TEXCOORD3; //従法線
                float4 worldPos : TEXCOORD4;
                // UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            sampler2D _SubTex;
            sampler2D _MaskTex;
            sampler2D _NormalTex;
            sampler2D _SubNormalTex;
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float _Main_Scale;
            float _Sub_Scale;
            float _Blend;
            float _SpecularLevel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal); //法線をワールド座標系に変換
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent)).xyz; //接線をワールド座標系に変換
                o.binormal = cross(v.normal, v.tangent) * v.tangent.w; //変換前の法線と接線から従法線を計算
                o.binormal = normalize(mul(unity_ObjectToWorld, o.binormal)); //従法線をワールド座標系に変換
                o.worldPos = v.vertex; //変換前の頂点を渡す
                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 main = tex2D(_MainTex, i.uv*_Main_Scale);
                fixed4 sub = tex2D(_SubTex, i.uv*_Sub_Scale);
                fixed4 mask = tex2D(_MaskTex, i.uv);
                fixed4 col = main * (1-mask) + sub * mask;


                // for normal
                float3 ligDirection = normalize(_WorldSpaceLightPos0.xyz); //シーンのディレクショナルライト方向を取得
                fixed3 ligColor = _LightColor0.xyz; //ディレクショナルライトのカラーを取得
                
                
                fixed4 main_normal = tex2D(_NormalTex, i.uv*_Main_Scale);
                fixed4 sub_normal = tex2D(_SubNormalTex, i.uv*_Sub_Scale);
                fixed4 col_Normal = main * (1-mask) + sub * mask;
                half3 normalmap = UnpackNormal(col_Normal); //ノーマルマップをプラットフォームに合わせて自動解釈
                float3 normal = (i.tangent * normalmap.x) + (i.binormal * normalmap.y) + (i.normal * normalmap.z); //ノーマルマップをもとに法線を合成


                //////////ランバート拡散反射
                float t = dot(normal, ligDirection); //ライト方向と法線方向で内積を計算
                t = max(0, t); //計算した内積のうち、t < 0は必要ないのでクランプ

                float3 diffuseLig = ligColor * t; //ディフューズカラーを計算。内積が0に近いほど色が黒くなる
                //////////

                //////////フォン鏡面反射
                float3 refVec = reflect(-ligDirection, normal); //ライト方向と法線方向から反射ベクトルを計算

                float3 toEye = _WorldSpaceCameraPos - i.worldPos; //カメラからの視線ベクトルを計算
                toEye = normalize(toEye); //視線ベクトルを正規化

                t = dot(refVec, toEye); //反射ベクトルと視線ベクトルで内積を計算
                t = max(0, t); //計算した内積のうち、t < 0は必要ないのでクランプ
                t = pow(t, _SpecularLevel); //反射の絞りを調整

                float3 specularLig = ligColor * t; //内積が１に近いほど照り返しが強いとみなし、ライトカラーを強く乗算
                //////////

                // float4 finalColor = tex2D(_MainTex, i.uv); //カラーテクスチャからサンプリング
                col.xyz *= (specularLig + diffuseLig); //ランバートとフォンの計算結果を乗算
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}

