Shader "WaterHeightInit"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_MainTex("Base (RGB)", 2D) = "black" {}
		_Color("Color", Color) = (1.0, 1.0, 0.0, 1.0)
	}

	SubShader
	{

		Pass
		{
			ZWrite On ZTest LEqual
			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

			struct vertexInput
			{
				float4 vertex: POSITION;
				//float3 normal: NORMAL;
				float4 texcoord: TEXCOORD0;
				//float4 tangent: TANGENT;
			};
			struct vertexOutput
			{
				float4 pos: SV_POSITION;
				float4 tex: TEXCOORD0;
				/*
				float4 posWorld: TEXCOORD1;
				float3 normalWorld: TEXCOORD2;
				float3 tangentWorld: TEXCOORD3;
				float3 binormalWorld: TEXCOORD4;
				*/
			};
			// This is a type of texture seen by shader.
			sampler2D  _MainTex;
			half3   _Color;
			const int idxVel = 0;
			const int idxHeight = 1;

			vertexOutput vert(vertexInput input)
			{
				vertexOutput o;
				o.pos = UnityObjectToClipPos(input.vertex);
				o.tex = input.texcoord;
				return o;
			}

			float scaleToTexture(float fragPos)
			{
				return 2 * (fragPos / 256.0 - 0.5);
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				float4 texel = tex2D(_MainTex, fragIn.tex);
				float4 t;
				float texX = scaleToTexture(fragIn.pos.x);
				float texY = scaleToTexture(fragIn.pos.y);
				t.r = 0;
				t.g = sin(sqrt(texX * texX + texY * texY));
				//t.g = 0;
				t.b = 0;
				// DEBUGGING PURPOSES
				t.a = 100000;
				// red is a velocity
				// green is a height
				return t;
			}
			ENDCG
		}
	}
}