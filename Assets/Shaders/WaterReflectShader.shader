﻿// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "WaterReflectShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_CubeMap("Cube map of surrounding", CUBE) = "white" {}
		_ColorWater("Color of water", Color) = (1.0, 1.0, 0.0, 1.0)
		_MainTex("Height map that represent water height", 2D) = "black" {}
		_ScaleHeight("Scale height", Float) = 0
		_RowWidth("Row width", Float) = 0
		_ColWdith("Column width", Float) = 0
		_DispRow("Float distance between adjacent vertices", Float) = 0
		_DispCol("Float distance between adjacent vertices", Float) = 0
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
	#pragma geometry geom
	#pragma fragment frag
	#pragma target 5.0

	#include "UnityCG.cginc"
	#include "Lighting.cginc"

			struct vertexInput
			{
			float4 vertex: POSITION;
			float3 normal: NORMAL;
			float4 texcoord: TEXCOORD0;
			};
			struct vertexOutput
			{
				float4 pos: SV_POSITION;
				float4 worldPosition: TEXCOORD4;
				float3 objPos: TEXCOORD2;
				float4 tex: TEXCOORD0;
				float3 normal: NORMAL;
				float3 lightDir: TEXCOORD1;
				float4 test: TEXCOORD3;
			};

			samplerCUBE _CubeMap;
			float4   _ColorWater;
			sampler2D _MainTex;
			float _ScaleHeight;
			float _RowWidth;
			float _ColWidth;
			float _DispRow;
			float _DispCol;
			// works
			float2 vertexLocalToUV(float2 vertex)
			{
				return float2(vertex.x / _RowWidth, vertex.y / _ColWidth);
			}
			// works
			float2 vertexLocalToUV(float4 vertex)
			{
				return vertexLocalToUV(vertex.xz);
			}
			// works
			float4 extractWorldPos(float4 vertPos)
			{
				return mul(UNITY_MATRIX_M, vertPos);
			}
			// works
			float extractTexelGreen(float2 vertex)
			{
				return tex2Dlod(_MainTex, float4(vertexLocalToUV(vertex), 0.0, 0.0)).g * _ScaleHeight;
			}

			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				float2 uv = vertexLocalToUV(input.vertex);
				//float4 texel = tex2Dlod(_MainTex, float4(uv.x, uv.y, 0.0, 0.0));

				float4 vertPos = float4(input.vertex.x, extractTexelGreen(input.vertex.xz),
					input.vertex.z, input.vertex.w);

				output.objPos = vertPos;
				output.pos = UnityObjectToClipPos(vertPos);
				output.worldPosition = extractWorldPos(vertPos);

				output.normal = input.normal;
				output.tex = float4(uv, 0.0, 0.0);
				// Light direction in object coordinates.
				output.lightDir = normalize(ObjSpaceLightDir(vertPos));
				output.test = float4(uv.x, uv.y, 0, 0);
				return output;
			}
			// it should work
			float3 extractNewVertexWorldPos(float vertexX, float vertexZ)
			{
				float3 newVertObjPos = float3(vertexX, extractTexelGreen(float2(vertexX, vertexZ)), vertexZ);
				return extractWorldPos(float4(newVertObjPos, 1.0)).xyz;
			}
			// works
			float3 calculateNormal(float3 vertex0, float3 vertex1, float3 vertex2)
            {
				return normalize(cross(vertex1 - vertex0, vertex2 - vertex0));
			}

			float3 calculaterInterpolateNormal(float3 vertex, float3 vertexWorld)
			{
 				float3 leftVertex = extractNewVertexWorldPos(vertex.x - _DispRow, vertex.z);
				float3 rightVertex = extractNewVertexWorldPos(vertex.x + _DispRow, vertex.z);
				float3 topVertex = extractNewVertexWorldPos(vertex.x, vertex.z + _DispCol);
				float3 bottomVertex = extractNewVertexWorldPos(vertex.x, vertex.z - _DispCol);
				float3 topLeftVertex = extractNewVertexWorldPos(vertex.x - _DispRow, vertex.z + _DispCol);
				float3 bottomRightVertex = extractNewVertexWorldPos(vertex.x + _DispRow, vertex.z - _DispCol);
				float3 sum = calculateNormal(vertexWorld, leftVertex, topLeftVertex);
				sum += calculateNormal(vertexWorld, topLeftVertex, topVertex);
				sum += calculateNormal(vertexWorld, bottomVertex, leftVertex);
				sum += calculateNormal(bottomRightVertex, bottomVertex, vertexWorld);
				sum += calculateNormal(bottomRightVertex, vertexWorld, rightVertex);
				sum += calculateNormal(rightVertex, vertexWorld, topVertex);
				sum /= 6.0f;
				return sum;
			}

			[maxvertexcount(3)]
			void geom(triangle vertexOutput input[3], inout TriangleStream<vertexOutput> OutputStream)
			{
				vertexOutput result;
				float3 normal = calculateNormal(input[0].worldPosition, input[1].worldPosition,
												input[2].worldPosition);
				for (int i = 0; i < 3; i++)
				{
					result = input[i];
					result.normal = mul(unity_WorldToObject, 
								calculaterInterpolateNormal(input[i].objPos, input[i].worldPosition.xyz));
					OutputStream.Append(result);
				}
			}

			float4 extractCubeMapColor(vertexOutput fragIn, float3 viewDirObjSpace)
			{
				// Reflects vector to based on view direction and normal on that point.
				float3 reflectCamera = reflect(-viewDirObjSpace, normalize(fragIn.normal));
				// Represents uv coordinate in cube matrix.
				float3 uv = mul(UNITY_MATRIX_M, float4(reflectCamera, 0));
				float4 col = texCUBE(_CubeMap, uv);
				return col;
			}

			float4 addSpecularLightToReflect(float4 color, vertexOutput fragIn, float3 viewDirObjSpace)
			{
				float lambert = max(0, dot(normalize(fragIn.normal),
					normalize(fragIn.lightDir)));
				float3 reflectLight = reflect(-fragIn.lightDir, fragIn.normal);
				float spec = pow(max(dot(viewDirObjSpace, normalize(reflectLight)), 0.0), 32);
				float specStrength = 0.7;
				float minLightStrength = 0.1;
				float3 specular = (_LightColor0 * spec * specStrength).rgb;
				specular = float3(max(specular.r, minLightStrength),
					max(specular.g, minLightStrength),
					max(specular.b, minLightStrength));
				return float4(color.rgb * lambert + float3(spec, spec, spec), color.a);
			}

			float4 convertToGrayscale(float4 color)
			{
				float average = (color.r + color.g + color.b) / 3.0;
				return float4(average, average, average, 1.0);
			}

			float4 colorize(float4 fragColor, float4 color)
			{
				return (convertToGrayscale(fragColor) * color);
			}

			float4 addTransperencyAngle(float4 color, float3 normalToSurface, float3 viewDirObjSpace)
			{
				color.a = 1 - clamp(dot(viewDirObjSpace, normalize(normalToSurface)), 0, 1);
				return color;
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				// Represents vector of direction of vertex 
				// towards camera in object space that is normalized.
				float3 viewDirObjSpace = normalize(ObjSpaceViewDir(float4(fragIn.objPos, 1))).xyz;
				float4 col = extractCubeMapColor(fragIn, viewDirObjSpace);
				col = addSpecularLightToReflect(col, fragIn, viewDirObjSpace);

				// Changes colour of the output
				float4 colorizedOutput = colorize(col, _ColorWater);
				// Transperency has to be added after changing the color.
				float4 transpEffectColor = addTransperencyAngle(colorizedOutput,
					fragIn.normal, viewDirObjSpace);
				//return float4(fragIn.test.x, fragIn.test.y, 0, 1);
				return transpEffectColor;
			}
			ENDCG
		}
	}
} 