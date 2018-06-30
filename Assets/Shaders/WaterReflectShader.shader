Shader "WaterReflectShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_CubeMap("Cube map of surrounding", CUBE) = "white" {}
		_Color("Color", Color) = (1.0, 1.0, 0.0, 1.0)
	}

	SubShader
	{
		Pass
		{
			Tags{ "Queue" = "Transparent" "LightMode" = "ForwardBase" }

			Blend SrcAlpha OneMinusSrcAlpha

			ZWrite Off
			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

			struct vertexInput
			{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float4 texcoord: TEXCOORD0;
				//float4 tangent: TANGENT;
			};
			struct vertexOutput
			{
				float4 pos: SV_POSITION;
				float3 tex: TEXCOORD0;
				float3 normal: NORMAL;
				
				/*
				float4 pos: TEXCOORD1;

				float3 tangentWorld: TEXCOORD3;
				float3 binormalWorld: TEXCOORD4;
				*/
			};
			// This is a type of texture seen by shader.
			samplerCUBE _CubeMap;
			half3   _Color;


			// TODO: Rethink how to optimize the code.
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				output.pos = UnityObjectToClipPos(input.vertex);
				output.tex = input.vertex;
				output.normal = input.normal;
				return output;
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				float3 viewDir = normalize(ObjSpaceViewDir(float4(fragIn.tex, 1))).xyz;

				float3 uv = reflect(-viewDir, normalize(fragIn.normal));

				uv = mul(UNITY_MATRIX_M, float4(uv, 0));

				fixed4 col = texCUBE(_CubeMap, uv);
				col.a = 1;
				//col.a = (1 - dot(viewDir, fragIn.normal))*(1 - _Transparency);
				return col;
			}
			ENDCG
		}
	}
}