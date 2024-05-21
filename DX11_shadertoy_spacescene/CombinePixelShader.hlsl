Texture2D g_texture0 : register(t0);
Texture2D g_texture1 : register(t1);
SamplerState g_sampler : register(s0);

cbuffer SamplingPixelConstantData : register(b0)
{
    float dx;
    float dy;
    float threshold;
    float strength;
    float4 options;
};

struct SamplingPixelShaderInput
{
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD;
};

float4 main(SamplingPixelShaderInput input) : SV_TARGET
{
	float3 diffuse = g_texture0.Sample(g_sampler, input.texcoord).rgb;
	float3 bloom = g_texture1.Sample(g_sampler, input.texcoord).rgb;
    
	return float4(diffuse + strength * bloom, 1.0);
}