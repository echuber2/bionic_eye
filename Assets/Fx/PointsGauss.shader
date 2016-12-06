Shader "Unlit/PointsGauss"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	// _DotTex("Dot", 2D) = "white" {}
	_DotSize("Dot Freq", Float) = 1 // not implemented
	_DotFreq("Dot Freq", Float) = 10
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

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

	float _DotFreq, _DotSize;
	sampler2D _MainTex;

	// sampler2D _DotTex;

	float4 _MainTex_ST;

	float numDots;
	int useHexMode;

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}

	float4 calcColor(float2 uv, float2 key) {

		// adding in Ada's hex hack
		if (useHexMode) {
			if (floor(key * numDots).y % 2 == 0) {
				key.x = key.x - 0.5*_DotFreq;
			}
		}

		float4 col = tex2D(_MainTex, key); // sample the main texture (underlying effects)

		//return col;
		float2 offset = (uv - key)*_DotSize; // vec from pt to cell center in DotSize units

		float dist = length(offset); // dist from point to cell center in DotSize units

		// offset += 0.5; // make it uv space..
		// offset=saturate(offset);
		//return float4(offset,0,1);
		//return float4(dist,dist,dist,1);

		// // green weight shouldn't matter for grayscale, but anyway:
		// float intensity = saturate(dot(col, float4(0.3, 0.4, 0.3, 0)));
		// // sample the value from the dot lookup texture, designed to give gaussian falloff:
		// float4 f = tex2D(_DotTex, float2(dist, 1 - intensity));

		// METHOD 1: cell center value falls off with normal distribution
		//    using fixed Gaussian falloff
		// float stdev = .3; // .3 looked okay
		// float pdf = 1/(stdev*sqrt(2*3.14159))*exp(-(dist*dist)/(2*stdev*stdev));
		// float val = col*pdf;
		// float4 f = float4(val,val,val,1);

		// METHOD 2: cell center value determines the falloff stdev as well.
		// Mapped range: min to max
		float min_sigma = 0.001;
		float max_sigma = 0.5;
		float sigma_range = max_sigma-min_sigma;
		float stdev = min_sigma + col*sigma_range;
		float pdf = 1/(stdev*sqrt(2*3.14159))*exp(-(dist*dist)/(2*stdev*stdev));
		float val = col*pdf;
		float4 f = float4(val,val,val,1);

		return f;

		// float w = f.r;
		// return float4(w, w, w, 1);

		/*
		w *= 2;
		//w *= w < 1;
		//w = saturate(0.2+ .4*intensity - dist);
		const float std = 0.07;
		const float PI = 3.1415;
		w = exp(-w*w / (2 * std*std)) / sqrt(2 * std*std*PI);
		*/

		// w = 0.5 - dist;
		// w = w < 0.5;
		//w = tex2D(_DotTex, offset).r; // grayscale.


		//w = saturate(.4- pow(dist,0.5));

		//w = pow(w, 3);

		//w *= w; // makes it apear square
		//w = w > 0.1;	 //saturate(w);
		//scol.a = intensity;

		// float4 c = w*col;
		// //c.a = w;
		// return c;

	}

	fixed4 frag(v2f i) : SV_Target
	{
		// sample the texture. maybe do lod???

		float2 nearestPoint = i.uv;

		nearestPoint = floor(nearestPoint/_DotFreq)+0.5;
		nearestPoint *= _DotFreq;

		//float2 nearestPoint = floor(i.uv*_DotFreq) / _DotFreq;
		//nearestPoint += 0.5*_DotFreq;

		float cell_weight = 0.11f; // (1/9)
		cell_weight = 1; // full weight
		const float w = _DotFreq; // + 0.1; // small offset to avoid screen-door

		float4 acc = float4(0, 0, 0, 0);
		acc += calcColor(i.uv, nearestPoint	)*cell_weight;
		// float4 alt_acc = acc;
		float col;
		// float nbor_min = acc;

		// Version that sums contributions
		col = calcColor(i.uv, nearestPoint + float2(-w, 0))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(w, 0))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(0, w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(0, -w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(-w, w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(w, w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(-w, -w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		col = calcColor(i.uv, nearestPoint + float2(w, -w))*cell_weight;
		acc += col;
		// nbor_min = min(nbor_min,col);
		// acc /= acc.a;
		acc.a = 1;

		// Version that takes max contribution of any neighbor:
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(-w, 0))); // this was missing, I think
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(w, 0)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(0, w)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(0, -w)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(-w, w)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(w, w)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(-w, -w)));
		// alt_acc = max(alt_acc, calcColor(i.uv, nearestPoint + float2(w, -w)));
		// alt_acc.a = 1;

		// acc = max(acc,alt_acc);

		// simple gaussian filter boost
		{
			// acc *= 9;
			// acc = saturate(acc*9*(nbor_min));
			// acc = pow(acc,.5);
		}

		// Reinhard operator experiments
		// acc = 2 * (acc/(1+acc));
		// acc = 2 * (acc/(1+acc));
		// acc = 1/(((1+acc)/(2*acc+0.01))+0.01);

		return saturate(acc);
	}
		ENDCG
	}
	}
}
