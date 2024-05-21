// Star Nest by Pablo Roman Andrioli
// License: MIT

#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   0.850
#define speed  0.010 

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

cbuffer SamplingPixelConstantData : register(b0)
{
	float dx;
	float dy;
	float threshold;
	float strength;
	float iTime;
	float dummy[3]; //padding
};

struct PixelShaderInput
{
	float4 position : SV_POSITION;
	float2 texcoord : TEXCOORD;
};

//void mainImage(out float4 fragColor, in float2 fragCoord)
float4 main(PixelShaderInput input) : SV_TARGET
{
	//get coords and direction
	float2 fragCoord = input.texcoord;
	float4 fragColor = float4(1.0, 1.0, 1.0, 1.0);
	float2 iResolution = float2(1, 1);
	float2 uv = fragCoord.xy / iResolution.xy - .5;
	uv.y *= iResolution.y / iResolution.x;
	uv.y = 1.0 - uv.y;
	float3 dir = float3(uv * zoom, 1.);
	float time = iTime * speed + .25;

	//mouse rotation
	float2 iMouse = float2(0.5, 0.5);
	float a1 = .5 + iMouse.x / iResolution.x * 2.;
	float a2 = .8 + iMouse.y / iResolution.y * 2.;
	float2x2 rot1 = float2x2(cos(a1), sin(a1), -sin(a1), cos(a1));
	float2x2 rot2 = float2x2(cos(a2), sin(a2), -sin(a2), cos(a2));
	dir.xz = mul(dir.xz, rot1);
	dir.xy = mul(dir.xy, rot2);
	float3 from = float3(1., .5, 0.5);
	from += float3(time * 2., time, -2.);
	from.xz = mul(from.xz, rot1);
	from.xy = mul(from.xy, rot2);
	
	//volumetric rendering
	float s = 0.1, fade = 1.;
	float3 v = float3(0.0, 0.0, 0.0);
	for (int r = 0; r < volsteps; r++)
	{
		float3 p = from + s * dir * .5;
		p = abs(float3(tile, tile, tile) - fmod(p, float3(tile * 2.0, tile * 2.0, tile * 2.0))); // tiling fold
		float pa, a = pa = 0.;
		for (int i = 0; i < iterations; i++)
		{
			p = abs(p) / dot(p, p) - formuparam; // the magic formula
			a += abs(length(p) - pa); // absolute sum of average change
			pa = length(p);
		}
		float dm = max(0., darkmatter - a * a * .001); //dark matter
		a *= a * a; // add contrast
		if (r > 6)
			fade *= 1. - dm; // dark matter, don't render near
		//v+=float3(dm,dm*.5,0.);
		v += fade;
		v += float3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
		fade *= distfading; // distance fading
		s += stepsize;
	}
	v = lerp(float3(length(v), length(v), length(v)), v, saturation); //color adjust
	fragColor = float4(v * .01, 1.);
	
	return fragColor;
}