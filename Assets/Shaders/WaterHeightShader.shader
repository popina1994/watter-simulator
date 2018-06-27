Shader "Unlit/WaterHeightShader"
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

		struct vertInput
	{
		float4 pos : POSITION;
		float2 uv: TEXCOORD0;
	};

	struct vertOutput
	{
		float4 pos : SV_POSITION;
		float2 texcoord: TEXCOORD0;
	};
	// This is a type of texture seen by shader.
	sampler2D  _MainTex;
	half3   _Color;

	vertOutput vert(vertInput input) {
		vertOutput o;
		// TODO: Understand.
		o.pos = UnityObjectToClipPos(input.pos);
		o.texcoord = input.uv;
		return o;
	}

	float4 frag(vertOutput IN) : COLOR
	{
		fixed4 mainColor = tex2D(_MainTex, IN.texcoord);
		return mainColor + _Time / 10;
	// RGBA
		//return fixed4(0, 0, 1, 1);
	}
		ENDCG
	}
	}
}