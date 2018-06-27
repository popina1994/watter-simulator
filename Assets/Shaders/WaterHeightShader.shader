Shader "WaterHeightShader"
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
				return fragPos / 256.0;
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				float4 texel = tex2D(_MainTex, fragIn.tex);
				float4 t;
				float upY = scaleToTexture(fragIn.pos.y + 1);
				float downY = scaleToTexture(fragIn.pos.y - 1);
				float leftX = scaleToTexture(fragIn.pos.x - 1);
				float rightX = scaleToTexture(fragIn.pos.x + 1);
				float texX = scaleToTexture(fragIn.pos.x);
				float texY = scaleToTexture(fragIn.pos.y);

				float4 texelUp = tex2D(_MainTex, float2(texX, min(upY, 1)));
				float4 texelDown = tex2D(_MainTex, float2(texX, max(downY, 0)));
				float4 texelLeft= tex2D(_MainTex, float2(max(leftX, 0), texY));
				float4 texelRight = tex2D(_MainTex, float2(min(rightX, 1), texY));
				
				t.r = (texelUp.g + texelDown.g + texelLeft.g 						
					+ texelRight.g) / 4.0f - texel.g;
				t.r *= 0.99;
				t.g = texel.g + t.r;
				t.a = 1;
				t.b = 0;
				//t.g = 0;
				return t;
			}
			ENDCG
		}
	}
}