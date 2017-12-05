Shader "Hidden/Compositer" {
	Properties {
		_MainTex("", 2D) = "white" {}
	}

	SubShader {
		Tags { "RenderType" = "Opaque" }

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos: TEXCOORD1;
			};

			// Our Vertex Shader
			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.pos);
				return o;
			}

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;

			// Our Fragment Shader
			half4 frag(v2f i) : COLOR {

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					i.scrPos.y = 1 - i.scrPos.y;
				#endif

				float3 normalValues;
				float4 uv = UNITY_PROJ_COORD(i.scrPos);
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, uv).r);
				
				float4 color = tex2Dproj(_MainTex, uv);
				float4 depth = float4(depthValue, depthValue, depthValue, 1);

				// extract depth value and normal values
				//DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.scrPos.xy), depthValue, normalValues);
				
				return (1 - depthValue) * color;
			}
			ENDCG
		}
	}
}