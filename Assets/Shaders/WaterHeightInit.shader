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

			float4 frag(vertexOutput fragIn) : COLOR
			{
				float4 texel = tex2D(_MainTex, fragIn.tex);
				float4 t;
				float up = (fragIn.pos.y + 1) / 256.0;
				float down = (fragIn.pos.y - 1) / 256.0;
				float left = (fragIn.pos.x - 1) / 256.0;
				float right = (fragIn.pos.x + 1) / 256.0;

				float4 texelUp = tex2D(_MainTex, float2(fragIn.pos.x, min(up, 1)));
				float4 texelDown = tex2D(_MainTex, float2(fragIn.pos.x, max(down, 0)));
				float4 texelLeft = tex2D(_MainTex, float2(fragIn.pos.x, max(left, 0)));
				float4 texelRight = tex2D(_MainTex, float2(fragIn.pos.x, min(right, 1)));
				t.r = 0;
				t.g = 1;
				t.b = 0;
				t.a = 1;
				// red is a velocity
				// green is a height
				return t;
			}
			ENDCG
		}
	}
}