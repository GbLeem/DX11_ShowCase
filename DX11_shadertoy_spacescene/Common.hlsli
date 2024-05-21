#ifndef __COMMON_HLSLI__
#define __COMMON_HLSLI__

#define MAX_LIGHTS 3 
#define NUM_DIR_LIGHTS 1
#define NUM_POINT_LIGHTS 1
#define NUM_SPOT_LIGHTS 1

// 재질
struct Material
{
    float3 ambient;
    float shininess;
    float3 diffuse;
    float dummy1; // 16 bytes 맞춰주기 위해 추가
    float3 specular;
    float dummy2;
    float3 fresnelR0;
    float dummy3;
};

// 조명
struct Light
{
    float3 strength;
    float fallOffStart;
    float3 direction;
    float fallOffEnd;
    float3 position;
    float spotPower;
};

float3 BlinnPhong(float3 lightStrength, float3 lightVec, float3 normal,
                   float3 toEye, Material mat)
{
    float3 halfway = normalize(toEye + lightVec);
    float hdotn = dot(halfway, normal);
    float3 specular = mat.specular * pow(max(hdotn, 0.0f), mat.shininess);

    return mat.ambient + (mat.diffuse + specular) * lightStrength;
}

float3 ComputeDirectionalLight(Light L, Material mat, float3 normal,
                                float3 toEye)
{
    float3 lightVec = -L.direction;

    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.strength * ndotl;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
    // Linear falloff
    return saturate((falloffEnd - d) / (falloffEnd - falloffStart));
}

float3 ComputePointLight(Light L, Material mat, float3 pos, float3 normal,
                          float3 toEye)
{
    float3 lightVec = L.position - pos;

    // 쉐이딩할 지점부터 조명까지의 거리 계산
    float d = length(lightVec);

    // 너무 멀면 조명이 적용되지 않음
    if (d > L.fallOffEnd)
    {
        return float3(0.0, 0.0, 0.0);
    }
    else
    {
        lightVec /= d;

        float ndotl = max(dot(lightVec, normal), 0.0f);
        float3 lightStrength = L.strength * ndotl;

        float att = CalcAttenuation(d, L.fallOffStart, L.fallOffEnd);
        lightStrength *= att;

        return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
    }
}

float3 ComputeSpotLight(Light L, Material mat, float3 pos, float3 normal,
                         float3 toEye)
{
    float3 lightVec = L.position - pos;

    // 쉐이딩할 지점부터 조명까지의 거리 계산
    float d = length(lightVec);

    // 너무 멀면 조명이 적용되지 않음
    if (d > L.fallOffEnd)
    {
        return float3(0.0f, 0.0f, 0.0f);
    }
    else
    {
        lightVec /= d;

        float ndotl = max(dot(lightVec, normal), 0.0f);
        float3 lightStrength = L.strength * ndotl;

        float att = CalcAttenuation(d, L.fallOffStart, L.fallOffEnd);
        lightStrength *= att;

        float spotFactor = pow(max(-dot(lightVec, L.direction), 0.0f), L.spotPower);
        lightStrength *= spotFactor;

        return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
    }
    
}

struct VertexShaderInput
{
    float3 posModel : POSITION; //모델 좌표계의 위치 position
    float3 normalModel : NORMAL; // 모델 좌표계의 normal    
    float2 texcoord : TEXCOORD0; // <- 다음 예제에서 사용
    
    // float3 color : COLOR0; <- 불필요 (쉐이딩)
};

struct PixelShaderInput
{
    float4 posProj : SV_POSITION; // Screen position
    float3 posWorld : POSITION; // World position (조명 계산에 사용)
    float3 normalWorld : NORMAL;
    float2 texcoord : TEXCOORD;
    float3 color : COLOR; // Normal lines 쉐이더에서 사용
};

#endif // __COMMON_HLSLI__