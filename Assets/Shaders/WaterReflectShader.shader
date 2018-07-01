Shader "WaterReflectShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_CubeMap("Cube map of surrounding", CUBE) = "white" {}
		_ColorWater("Color of water", Color) = (1.0, 1.0, 0.0, 1.0)
		_NormalSurface("Normal to the surface of water", Vector) = (0, 0, 0, 0)
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
			float4   _ColorWater;
			float4 _NormalSurface;	


			// TODO: Rethink how to optimize the code.
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				output.pos = UnityObjectToClipPos(input.vertex);
				output.tex = input.vertex;
				output.normal = input.normal;
				return output;
			}

			float4 convertToGrayscale(float4 color)
			{
				float average = (color.r + color.g + color.b) / 3.0;
				return float4(average, average, average, 1.0);
			}

			float4 colorize(float4 grayscale, float4 color)
			{
				return (grayscale * color);
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				// Represents vector of direction of vertex 
				// towards camera in object space that is normalized.
				float3 viewDirObjSpace = normalize(ObjSpaceViewDir(float4(fragIn.tex, 1))).xyz;
				float3 viewDirWorldSpace = normalize(WorldSpaceViewDir(float4(fragIn.tex, 1))).xyz;
				// Reflects vector to based on view direction and normal on that point.
				float3 uv = reflect(-viewDirObjSpace, normalize(fragIn.normal));

				// Do not understand this part.
				uv = mul(UNITY_MATRIX_M, float4(uv, 0));

				fixed4 col = texCUBE(_CubeMap, uv);
				
				// Changes colour of the output
				float4 grayscale = convertToGrayscale(col);
				float4 colorizedOutput = colorize(grayscale, _ColorWater);
				// Transperency has to be added after changing the color. 
				colorizedOutput.a = dot(viewDirObjSpace, fragIn.normal);
				return colorizedOutput;
				// The other approach for colouring.
				//return col + float4(1, 0, 0, 1)*col	.a;;
			}
			ENDCG
		}
	}
}