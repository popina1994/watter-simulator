Shader "WaterReflectShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_CubeMap("Cube map of surrounding", CUBE) = "white" {}
		_ColorWater("Color of water", Color) = (1.0, 1.0, 0.0, 1.0)
		_NormalSurface("Normal to the surface of water", Vector) = (0, 0, 0, 0)
		_MainTex("Height map that represent water height", 2D) = "black" {}
		_ScaleHeight("Scale height", Float) = 0
		_RowWidth("Row width", Float) = 0
		_ColWdith("Column width", Float) = 0
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
	float4 _NormalSurface;
	sampler2D _MainTex;
	float _ScaleHeight;
	float _RowWidth;
	float _ColWidth;

	float2 vertexLocalToUV(float4 vertex)
	{
		return float2(vertex.x / _RowWidth, vertex.z / _ColWidth);
	}

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;
		float2 uv = vertexLocalToUV(input.vertex);
		float4 texel = tex2Dlod(_MainTex, float4(uv.x, uv.y, 0.0, 0.0));

		float4 vertPos = float4(input.vertex.x, texel.g * _ScaleHeight,
			input.vertex.z, input.vertex.w);

		output.objPos = vertPos;
		output.pos = UnityObjectToClipPos(vertPos);
		output.worldPosition = mul(UNITY_MATRIX_M, vertPos);

		output.normal = input.normal;
		output.tex = float4(uv, 0.0, 0.0);
		// Light direction in world coordinates.
		output.lightDir = normalize(ObjSpaceLightDir(vertPos));
		output.test = float4(0, texel.g, 0, 0);
		output.test = float4(uv.x, uv.y, 0, 0);
		return output;
	}

	[maxvertexcount(3)]
	void geom(triangle vertexOutput input[3], inout TriangleStream<vertexOutput> OutputStream)
	{
		vertexOutput test = (vertexOutput)0;
		float3 normal = normalize(cross(input[1].worldPosition.xyz - input[0].worldPosition.xyz, input[2].worldPosition.xyz - input[0].worldPosition.xyz));
		for (int i = 0; i < 3; i++)
		{
			test = input[i];
			test.normal = normal;
			OutputStream.Append(test);
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