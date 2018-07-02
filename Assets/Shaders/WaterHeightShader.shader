Shader "WaterHeightShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_MainTex("Base (RGB)", 2D) = "black" {}
		_CubeMap("Cube map of surrounding", CUBE) = "white" {}
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
			ZWrite Off
			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

			struct vertexInput 
			{
				float4 vertex: POSITION;
				float4 texcoord: TEXCOORD0;
			};
			struct vertexOutput 
			{	
				float4 posWorld: SV_POSITION;
				float4 tex: TEXCOORD0;
			};
			// This is a type of texture seen by shader.
			sampler2D  _MainTex;
			samplerCUBE _CubeMap;
			half3   _Color;
			float4 _IsClicked;
			float4 _xPos;
			float4 _yPos;
			float _Radius;

			vertexOutput vert(vertexInput input) 
			{
				vertexOutput output;
				output.posWorld = UnityObjectToClipPos(input.vertex);
				output.tex = input.texcoord;
				return output;
			}

			float scaleToTexture(float fragPos)
			{
				return fragPos / 256.0;
			}

			bool isInRadius(float x, float y, float radius, int idx)
			{
				return (((x - _xPos[idx]) * (x - _xPos[idx]) + (y - _yPos[idx]) * (y - _yPos[idx])) <= radius);
			}

			bool isInClickRadius(float x, float y, float radius)
			{
				for (int idx = 0; idx < 4; idx++)
				{
					if (_IsClicked[idx] && isInRadius(x, y, radius, idx))
					{
						return true;
					}
				}
				return false;
			}
			
			float4 frag(vertexOutput fragIn) : SV_Target
			{

				float4 texel = tex2D(_MainTex, fragIn.tex);
				float4 t;
				float f;
				float upY = scaleToTexture(fragIn.posWorld.y + 1);
				float downY = scaleToTexture(fragIn.posWorld.y - 1);
				float leftX = scaleToTexture(fragIn.posWorld.x - 1);
				float rightX = scaleToTexture(fragIn.posWorld.x + 1);
				float texX = scaleToTexture(fragIn.posWorld.x);
				float texY = scaleToTexture(fragIn.posWorld.y);

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
					if (isInClickRadius(fragIn.posWorld.x, fragIn.posWorld.y, _Radius))
					{
						t.r = -t.r;
						//t.g = t.g - 0.001;
						//t.g = t.g - 0.05;
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