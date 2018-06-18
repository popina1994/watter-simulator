Shader "Unlit/WaterHeightShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,0)
		_MainTex("Base (RGB)", 2D) = "black" {}
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
				// TODO: Understand.
				o.pos = UnityObjectToClipPos(input.pos);
				o.texcoord = input.texcoord;
				return o;
			}
			
			float4 frag(vertOutput IN) : COLOR
			{
				float4 mainColor = tex2D(_MainTex, IN.texcoord);
				return _Color + _Time / 10;
			}

			
			ENDCG
		}
	}
}