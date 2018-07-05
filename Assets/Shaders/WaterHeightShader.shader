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
		_RendTexSize("Size of render texture", Float) = 0
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
			float2 _IsClicked;
			float2 _xPos;
			float2 _yPos;
			float _Radius;
			float _RendTexSize;

			vertexOutput vert(vertexInput input) 
			{
				vertexOutput output;
				output.posWorld = UnityObjectToClipPos(input.vertex);
				output.tex = input.texcoord;
				return output;
			}

			float scaleToTexture(float fragPos)
			{
				return fragPos / _RendTexSize;
			}

			bool isInRadius(float xCenter, float yCenter, float x, float y, float radius)
			{
				return (((x - xCenter) * (x - xCenter) + (y - yCenter) * (y - yCenter)) <= radius);
			}

			bool isInRadius(float x, float y, float radius, int idx)
			{
				return isInRadius(_xPos[idx], _yPos[idx], x, y, radius);
			}

			bool isInClickRadius(float x, float y, float radius)
			{
				return (_IsClicked[0] && isInRadius(x, y, radius, 0));
			}

			float interpolate(float dim1, float dim2, float a)
			{
				return a * dim1 + (1 - a) * dim2;
			}

			float2 translateTo(float x, float y, float2 center)
			{
				return float2(x - center.x, y - center.y);
			}

			bool isInQuadRadius(float x, float y, float radius)
			{
				float2 center = float2(interpolate(_xPos[0], _xPos[1], 0.5f),
									   interpolate(_yPos[0], _yPos[1], 0.5f));
				float2 leftTop = abs(translateTo(_xPos[0], _yPos[0], center));
				float2 pointCheck = abs(translateTo(x, y, center));
				return ((pointCheck.x < leftTop.x) && (pointCheck.y < leftTop.y)) ||
					((pointCheck.x < leftTop.x) && (pointCheck.y < leftTop.y + radius)) ||
					((pointCheck.x < leftTop.x + radius) && (pointCheck.y < leftTop.y)) ||
					isInRadius(leftTop.x, leftTop.y, pointCheck.x, pointCheck.y, radius);
			}

			bool isInQuadRadiusClick(float x, float y, float radius)
			{
				return (_IsClicked[0] && _IsClicked[1] && isInQuadRadius(x, y, radius));
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
						f = -0.1;
					}
					t.r = texel.r + f;	
					t.g = texel.g + t.r;
					if (isInQuadRadiusClick(fragIn.posWorld.x, fragIn.posWorld.y, _Radius)
						|| isInClickRadius(fragIn.posWorld.x, fragIn.posWorld.y, _Radius))
					{
						t.r = -t.r;
						t.g = t.g - 0.001;
						//t.g = t.g - 0.05;		
						//t.x = 0.5;
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