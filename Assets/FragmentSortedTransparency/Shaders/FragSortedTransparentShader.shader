Shader "Fragment Sorted Transparency" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
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
				half4 color;
				float depth;
				uint childIndex;

				half4 fillColor;
				half4 normal;
				float facing;
			};
			
			struct v2f {
				float4 pos      : POSITION;
				float4 worldNormal : TEXCOORD0;
				float4 spos     : TEXCOORD1;
				float3 viewDir  : TEXCOORD2;
			};

			int LINKEDLIST_END;
			uniform RWStructuredBuffer<int> _FragmentSortedTransparencyHead : register(u1);
			uniform RWStructuredBuffer<LinkedListNode> _FragmentSortedTransparencyLinkedList : register(u2);
			
			uniform fixed4 _LightColor0;
			float4 _Color;
			float _Shininess;

			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.spos = ComputeScreenPos(o.pos);
				o.worldNormal = mul(unity_ObjectToWorld, v.normal);
				o.worldNormal.xyz = normalize(o.worldNormal.xyz);
				o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex).xyz);

				return o;
			}

			float4 frag(v2f i, fixed facing: VFACE) : COLOR {
				// TODO: Discard fragment based on already rendered depth
				// ZTest doesnt seem to prevent this from writing to the
				// buffer?

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

				float attenuation = 1.0;
				float specularReflection;
				if (dot(-normalDirection, LightDirection) < 0.0)
					// light source on the wrong side?
				{
					specularReflection = float3(0.0, 0.0, 0.0);
					// no specular reflection
				}
				else // light source on the right side
				{
					specularReflection = attenuation
						* pow(max(0.0, dot(
							reflect(-LightDirection, normalDirection),
							i.viewDir)), _Shininess);
				}

				col.rgb = _LightColor0;
				col.a = specularReflection;


				// Form the node
				int childIndex = (int)_FragmentSortedTransparencyLinkedList.IncrementCounter();
				if (childIndex != (LINKEDLIST_END - 1)) {
					
					int headIndex = screenPos.y * _ScreenParams.x + screenPos.x;
					int oldHeadIndex;
					
					InterlockedExchange(_FragmentSortedTransparencyHead[headIndex], childIndex + 1, oldHeadIndex);
					 
					LinkedListNode n;
					n.color = col;
					n.depth = Linear01Depth(i.pos.z);
					n.childIndex = oldHeadIndex;

					n.fillColor = _Color;
					n.fillColor.rgb *= _LightColor0.rgb;

					n.normal = float4(mul((float3x3)UNITY_MATRIX_V, normalDirection * facing), 0);
					n.facing = facing;
					_FragmentSortedTransparencyLinkedList[childIndex] = n;
				}

				return col;
			}

			ENDCG
		}
	}
}