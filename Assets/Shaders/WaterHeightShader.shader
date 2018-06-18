// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WaterHeightShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,0)
		_MainTex("InputTex", 2D) = "black" {}
	}

	SubShader
	{
		Lighting Off
		Blend One Zero

		Pass
		{
			CGPROGRAM

			#pragma vertex vert             
			#pragma fragment frag

			struct vertInput 
			{
				float4 pos : POSITION;
				float2 texcoord: TEXCOORD0;
			};

			struct vertOutput 
			{
				float4 pos : SV_POSITION;
				float2 texcoord: TEXCOORD0;
			};
			float4 _Color;
			sampler2D  _MainTex;

			vertOutput vert(vertInput input) {
				vertOutput o;
				o.pos = UnityObjectToClipPos(input.pos);
				o.texcoord = input.texcoord;
				return o;
			}

			float4 frag(vertOutput output) : COLOR{
				
				float4 mainColour = tex2D(_MainTex, output.texcoord);
				return mainColour * _Color;
			}
			ENDCG
		}
	}
}