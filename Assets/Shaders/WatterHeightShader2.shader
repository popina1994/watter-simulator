Shader "WaterHeightShaderOposite"
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

		struct vertexInput {
		float4 vertex: POSITION;
		//float3 normal: NORMAL;
		float4 texcoord: TEXCOORD0;
		//float4 tangent: TANGENT;
	};
	struct vertexOutput {
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

	vertexOutput vert(vertexInput input) {
		vertexOutput o;
		// TODO: Understand.
		o.pos = UnityObjectToClipPos(input.vertex);
		o.tex = input.texcoord;
		return o;
	}

		float4 frag(vertexOutput IN) : COLOR
		{
			float4 texcol = tex2D(_MainTex, IN.tex);
			texcol.g = 1-  texcol.g;
			texcol.b = texcol.b;
			texcol.r = 1- texcol.r;
			texcol.a = texcol.a;
			return texcol;
			//return fixed4(0, 1, 0, 1);
		}
			ENDCG
	}
	}
}