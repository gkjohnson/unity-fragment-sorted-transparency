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
			#pragma multi_compile _ FRAGS_PER_PIXEL

			sampler2D _CameraDepthTexture;

			struct LinkedListNode {
				half4 color;
				float depth;
				uint childIndex;

				// optional
				half4 fillColor;
				half4 normal;
				float facing;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 spos: TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			float _FragmentCount;
			StructuredBuffer<int> _FragmentSortedTransparencyHead;
			StructuredBuffer<LinkedListNode> _FragmentSortedTransparencyLinkedList;

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

				float4 uv = UNITY_PROJ_COORD(i.spos);
				float depthSample = tex2Dproj(_CameraDepthTexture, uv).r;
				float depthValue = Linear01Depth(depthSample);
				
				float4 depth = float4(depthValue, depthValue, depthValue, 1);

				int currIndex = child;
				int count = 0;
				float3 refractIntensity = float3(0, 0, 0);
				
				// TODO: roll this into the same loop we use for color
				// and sample the main texture after everything is done
				while (currIndex != 0) {
					LinkedListNode node = _FragmentSortedTransparencyLinkedList[currIndex - 1];
					currIndex = node.childIndex;
					count++;

					uint nextIndex = node.childIndex;

					if (depthValue > node.depth && node.facing == 1) {
						// TODO: include front face refraction?
					}
					else if (nextIndex != 0 && node.facing == -1) {
						LinkedListNode nextn = _FragmentSortedTransparencyLinkedList[nextIndex - 1];

						// bigger number is further away
						// TODO: convert the depth delta to a world-space distance
						// TODO: figure out what to do in the intersection volumes
						float depthDelta = min(depthValue, node.depth) - nextn.depth;
						refractIntensity += node.normal.rgb * saturate(depthDelta);

					}
				}
				uv.xy -= refractIntensity.xy * 10;
				float4 color = tex2Dproj(_MainTex, uv);

				currIndex = child;
				count = 0;
				while (currIndex != 0) {
					LinkedListNode node = _FragmentSortedTransparencyLinkedList[currIndex - 1];
					currIndex = node.childIndex;
					count++;
					
					uint nextIndex = node.childIndex;

					if (depthValue > node.depth && node.facing == 1) {
						// render the back face color
						color.rgb = lerp(color.rgb, node.color.rgb, node.color.a);
					} else if (nextIndex != 0 && node.facing == -1) {
						// render the inner volume
						LinkedListNode nextn = _FragmentSortedTransparencyLinkedList[nextIndex - 1];

						// bigger number is further away
						// TODO: convert the depth delta to a world-space distance
						// TODO: figure out what to do in the intersection volumes
						float depthDelta = min(depthValue, node.depth) - nextn.depth;
						float alpha = saturate(500 * depthDelta * node.fillColor.a);
						color.rgb = lerp(color.rgb, node.fillColor.rgb, alpha);
					}
				}

				// Draw a heat map of fragment overlay
				#ifdef FRAGS_PER_PIXEL
				float fragCount = max(_FragmentCount, 1);
				float val = saturate(count / fragCount);
				return float4(val, floor(val), floor(val), 1);
				#endif
	
				return color;
			}
			ENDCG
		}
	}
}