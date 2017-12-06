Shader "Fragment Sorted Transparency" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
	}

	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "ForwardBase" }

		Pass {
			Cull Off

			CGPROGRAM 
			#include "UnityCG.cginc"
			#pragma vertex vert
			#pragma fragment frag

			uniform fixed4 _LightColor0;
			float4 _Color;

			struct LinkedListHead {
				uint childIndex;
			};

			struct LinkedListNode {
				float4 color;
				float depth;
				uint childIndex;
			};
			
			struct v2f {
				float4 pos      : POSITION;
				float4 worldNormal : TEXCOORD0;
				float4 spos     : TEXCOORD1;
			};

			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.spos = ComputeScreenPos(o.pos);
				o.worldNormal = mul(unity_ObjectToWorld, v.normal);
				o.worldNormal.xyz = normalize(o.worldNormal.xyz);

				return o;
			}

			float4 frag(v2f i, fixed facing: VFACE) : COLOR {
				float4 norm = -facing * i.worldNormal;
				float3 normalDirection = normalize(norm.xyz);
				float4 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float4 LightDirection = normalize(_WorldSpaceLightPos0);
				float4 DiffuseLight = saturate(dot(LightDirection, -normalDirection))*_LightColor0;
				float4 col = float4(AmbientLight + DiffuseLight) * _Color;

				return col;
			}

			ENDCG
		}
	}
}