Shader "WaterHeightShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_MainTex("Base (RGB)", 2D) = "black" {}
		_Color("Color", Color) = (1.0, 1.0, 0.0, 1.0)
		_IsClicked("Is clicked", Float) = 0
		_xPos("Y position in clicked texture", Float) = 0
		_yPos("Y position in clicked texture", Float) = 0
		_Radius("Radius of click", Float) = 0
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
			float _IsClicked;
			float _xPos;
			float _yPos;
			float _Radius;

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

			bool isInRadius(float x, float y, float radius)
			{
				return (((x - _xPos) * (x - _xPos) + (y - _yPos) * (y - _yPos)) <= radius);
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{

				float4 texel = tex2D(_MainTex, fragIn.tex);
				float4 t;
				float f;
				float upY = scaleToTexture(fragIn.pos.y + 1);
				float downY = scaleToTexture(fragIn.pos.y - 1);
				float leftX = scaleToTexture(fragIn.pos.x - 1);
				float rightX = scaleToTexture(fragIn.pos.x + 1);
				float texX = scaleToTexture(fragIn.pos.x);
				float texY = scaleToTexture(fragIn.pos.y);

				float4 texelUp = tex2D(_MainTex, float2(texX, min(upY, 1)));
				float4 texelDown = tex2D(_MainTex, float2(texX, max(downY, 0)));
				float4 texelLeft = tex2D(_MainTex, float2(max(leftX, 0), texY));
				float4 texelRight = tex2D(_MainTex, float2(min(rightX, 1), texY));

					f = ((texelUp.g + texelDown.g + texelLeft.g
						+ texelRight.g) / 4.0f - texel.g) / 4;
					if (f > 0.1)
					{
						f = 0.1;
					}
					if (f < -0.1)
					{
						f = 0.1;
					}
					t.r = texel.r + f;	
					t.g = texel.g + t.r;
					if ((_IsClicked == 1) && isInRadius(fragIn.pos.x, fragIn.pos.y, _Radius))
					{
						//t.r = -t.r;
						t.g = t.g - 0.001;
					}
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