Shader "Hidden/DepthEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Speed("Speed", Float) = 3
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata vpos)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, vpos.vertex);
				// o.uv = v.uv;
				o.uv.x = vpos.uv.x;
				o.uv.y = vpos.uv.y;
				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float _Speed;
			fixed4 frag (v2f i) : SV_Target
			{
				float de = tex2D(_CameraDepthTexture, i.uv).r;
				// float depth = LinearEyeDepth(de);
				float depth = Linear01Depth(de);
				// float x = depth % 1; // 1 m mod
				// x = LinearEyeDepth(3);
				// float x = depth*.02;
				float timeval = frac((_Time.y+1)/1.5);
				float x = 1-depth; // get white:near, black:far
				float versionA;
				float versionB;
				float finalx;

				// float refDist = _ProjectionParams.z*frac(_Time.y*0.5);
				float refDist = 1/timeval;
				refDist = refDist / (2+refDist); // Reinhard function
				x = saturate(x-refDist);
				versionA = x;
				// x = pow(x,15.0);
				// x *= .1;
				// x = x / (x+20);
				// x = 0.1*abs(depth - refDist);
				
				//x = saturate(depth*_Speed);
				//x = pow(depth, _Speed);

				// const float far = _ProjectionParams.z;
				// x = 1-(pow((1/depth),-0.4));
				x = 1-depth;
				timeval = 1/(timeval);
				timeval *= 5;
				x = pow(x,timeval);
				versionB = x;

				finalx = versionB; // versionA or versionB

				return float4(finalx, finalx, finalx, 1);
				//now with technicolor!!!
				// return float4(depth, depth/10, 1/ depth, 1)%1;
			}
			ENDCG
		}
	}
}
