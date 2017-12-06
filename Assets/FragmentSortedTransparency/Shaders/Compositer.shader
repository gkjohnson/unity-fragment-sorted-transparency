Shader "Hidden/Compositer" {
	Properties {
		_MainTex("", 2D) = "white" {}
	}

	SubShader {
		Tags { "RenderType" = "Opaque" }

		Pass {
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;

			struct LinkedListNode {
				float4 color;
				float depth;
				int childIndex;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 spos: TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			uniform RWStructuredBuffer<int> _FragmentSortedTransparencyHead : register(u1);
			uniform RWStructuredBuffer<LinkedListNode> _FragmentSortedTransparencyLinkedList : register(u2);

			// Our Vertex Shader
			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.spos = ComputeScreenPos(o.pos);
				return o;
			}

			// Our Fragment Shader
			half4 frag(v2f i) : COLOR {
				float2 screenPos = i.spos.xy / i.spos.w;
				screenPos *= _ScreenParams.xy;
				screenPos = floor(screenPos);

				int headIndex = screenPos.y * _ScreenParams.x + screenPos.x;
				int child = _FragmentSortedTransparencyHead[headIndex];




				float3 normalValues;
				float4 uv = UNITY_PROJ_COORD(i.spos);
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, uv).r);
				
				float4 color = tex2Dproj(_MainTex, uv);
				float4 depth = float4(depthValue, depthValue, depthValue, 1);

				int currIndex = child;
				while (currIndex != -1) {
					LinkedListNode node = _FragmentSortedTransparencyLinkedList[currIndex];


					//color.rgb = color.rgb * (1 - node.color.a) + node.color.rgb * node.color.a;
					color = float4(node.color.r, 0, 0, 1);
					currIndex = node.childIndex;
				}

				return color;

				// extract depth value and normal values
				//DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.scrPos.xy), depthValue, normalValues);
				
				return (1 - depthValue) * color;
			}
			ENDCG
		}
	}
}