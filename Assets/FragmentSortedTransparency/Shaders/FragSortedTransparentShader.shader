Shader "Fragment Sorted Transparency" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
	}

	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "ForwardBase" }

		Pass {
			Cull Off
			ZWrite Off
			ZTest Off

			CGPROGRAM 
			#include "UnityCG.cginc"
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag

			struct LinkedListNode {
				float4 color;
				float depth;
				int childIndex;
			};
			
			struct v2f {
				float4 pos      : POSITION;
				float4 worldNormal : TEXCOORD0;
				float4 spos     : TEXCOORD1;
			};

			int LINKEDLIST_END;
			uniform RWStructuredBuffer<int> _FragmentSortedTransparencyHead : register(u1);
			uniform RWStructuredBuffer<LinkedListNode> _FragmentSortedTransparencyLinkedList : register(u2);
			
			uniform fixed4 _LightColor0;
			float4 _Color;

			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.spos = ComputeScreenPos(o.pos);
				o.worldNormal = mul(unity_ObjectToWorld, v.normal);
				o.worldNormal.xyz = normalize(o.worldNormal.xyz);

				return o;
			}

			float4 frag(v2f i, fixed facing: VFACE) : COLOR {
				float2 screenPos = i.spos.xy / i.spos.w;
				screenPos *= _ScreenParams.xy;
				screenPos = floor(screenPos);

				float4 norm = -facing * i.worldNormal;
				float3 normalDirection = normalize(norm.xyz);
				float4 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float4 LightDirection = normalize(_WorldSpaceLightPos0);
				float4 DiffuseLight = saturate(dot(LightDirection, -normalDirection))*_LightColor0;
				float4 col = float4(AmbientLight + DiffuseLight) * _Color;
				col.a = _Color.a;

				// Form the 
				int childIndex = (int)_FragmentSortedTransparencyLinkedList.IncrementCounter();
				if (childIndex != LINKEDLIST_END) {
					
					int headIndex = screenPos.y * _ScreenParams.x + screenPos.x;
					int oldHeadIndex;
					
					InterlockedExchange(_FragmentSortedTransparencyHead[headIndex], childIndex, oldHeadIndex);

					LinkedListNode n;
					n.color = col;
					n.depth = i.pos.z;
					n.childIndex = oldHeadIndex;
					_FragmentSortedTransparencyLinkedList[childIndex] = n;
				}


				return col;
			}

			ENDCG
		}
	}
}