Shader "WaterHeightUpdateShader"
{
	Properties
	{
		// Type of the texture seen by unity editor.
		_MainTex("Height map that represent water height", 2D) = "black" {}
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
	#pragma target 5.0
#pragma enable_d3d11_debug_symbols


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
				float3 objPos: TEXCOORD0;
				float3 normal: NORMAL;
				float3 lightDir: TEXCOORD1;
				float  test : TEXCOORD2;
			};

			sampler2D _MainTex;

			// TODO: Rethink how to optimize the code.
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				

				float4 texel = tex2Dlod(_MainTex, float4(input.texcoord.x, input.texcoord.y, 0, 1));
				
				float4 vertPos = float4(input.vertex.x, texel.g * 2,
					input.vertex.z, input.vertex.w);
				
				output.objPos = vertPos;
				output.pos = UnityObjectToClipPos(vertPos);

				output.normal = input.normal;
				// Light direction in world coordinates.
				output.lightDir = normalize(ObjSpaceLightDir(input.vertex));
				output.test = texel.g * 2;
				return output;
			}

			float4 frag(vertexOutput fragIn) : SV_Target
			{
				// Represents vector of direction of vertex 
				// towards camera in object space that is normalized.
				if (fragIn.test < 0.5)
				{
					return float4(0, fragIn.test, 0, 1);
				}
				else
				{
					return float4(0, fragIn.test, 1, 1);
				}		
				
			}
			ENDCG
		}
	}
}