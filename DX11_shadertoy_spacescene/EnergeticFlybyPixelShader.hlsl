Texture2D g_texture0 : register(t0);
Texture2D g_texture1 : register(t1);
SamplerState g_sampler : register(s0);

cbuffer SamplingPixelConstantData : register(b0)
{
    float dx;
    float dy;
    float threshold;
    float strength;
    float time;
    float dummy[3];
};


struct PixelShaderInput
{
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD;
};

//float4 main(PixelShaderInput input) : SV_TARGET {
//
//    // float x = input.texcoord.x;
//    // float y = input.texcoord.y;
//
//    // float f = (x - 0.5 - xSplit) * (x - 0.5 - xSplit) + (y - 0.5) * (y - 0.5)
//    // -
//    //           0.3 * 0.3;
//
//    // float4 color = g_texture0.Sample(g_sampler, input.texcoord);
//
//    // if (f < 0.0)
//    //     return color * 1.5;
//    // else
//    //     return color;
//
//    // return g_texture0.Sample(g_sampler, input.texcoord - float2(0.0,
//    // xSplit)); return g_texture0.Sample(g_sampler, input.texcoord * 10.0);
//
//    return input.texcoord.x > xSplit
//               ? g_texture0.Sample(g_sampler, input.texcoord)
//               : g_texture1.Sample(g_sampler, input.texcoord);
//}

//#define time iTime
#define resolution iResolution
#define so frac(sin(time) * 123.456)

static float det = .001, br = 0., tub = 0., hit = 0.;
static float3 pos, sphpos;
float3x3 lookat(float3 dir, float3 up) {
    float3 rt = normalize(cross(dir, up));
    return float3x3(rt, cross(rt, dir), dir);
}
float3 path(float t) { return float3(sin(t + cos(t) * .5) * .5, cos(t * .5), t); }
float2x2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, s, -s, c);
}
float3 fractal(float2 p) {
    p = frac(p * .1);
    float m = 1000.;
    for (int i = 0; i < 7; i++) {
        p = abs(p) / clamp(abs(p.x * p.y), .25, 2.) - 1.2;
        m = min(m, abs(p.y) + frac(p.x * .3 + time * .5 + float(i) * .25));
    }
    m = exp(-6. * m);
    return m * float3(abs(p.x), m, abs(p.y));
}

float coso(float3 pp) {
    pp *= .7;
    pp.xy = mul(pp.xy, rot(pp.z * 2.));
    pp.xz = mul(pp.xz, rot(time * 2.));
    pp.yz = mul(pp.yz, rot(time));
    float sph = length(pp) - .04;
    sph -= length(sin(pp * 40.)) * .05;
    sph = max(sph, -length(pp) + .11);
    float br2 = length(pp) - .03;
    br2 = min(br2, length(pp.xy) + .005);
    br2 = min(br2, length(pp.xz) + .005);
    br2 = min(br2, length(pp.yz) + .005);
    br2 = max(br2, length(pp) - 1.);
    br = min(br2, br);
    float d = min(br, sph);
    return d;
}

float de(float3 p) {
    hit = 0.;
    br = 1000.;
    float3 pp = p - sphpos;
    p.xy -= path(p.z).xy;
    p.xy = mul(p.xy, rot(p.z + time * .5));
    float s = sin(p.z * .5 + time * .5);
    p.xy *= 1.3 - s * s * .7;

    for (int i = 0; i < 6; i++) {
        p = abs(p) - .4;
    }
    pos = p;
    tub = -length(p.xy) + .45 +
          sin(p.z * 10.) * .1 *
              smoothstep(.4, .5, abs(.5 - frac(p.z * .05)) * 2.);
    float co = coso(pp);
    co = min(co, coso(pp + .7));
    co = min(co, coso(pp - .7));
    float d = min(tub, co);
    if (d == tub)
        hit = step(frac(.1 * length(sin(p * 10.))), .05);
    return d * .3;
}

float3 march(float3 from, float3 dir) {
    float2 uv =
        float2(atan2(dir.x, dir.y) + time * .5, length(dir.xy) + sin(time * .2));
    float3 col = fractal(uv);
    float d = 0., td = 0., g = 0., ref = 0., ltd = 0., li = 0.;
    float3 p = from;
    for (int i = 0; i < 200; i++) {
        p += dir * d;
        d = de(p);
        if (d < det && ref == 0. && hit == 1.) {
            float2 e = float2(0., .1);
            float3 n = normalize(
                float3(de(p + e.yxx), de(p + e.xyx), de(p + e.xxy)) - de(p));
            p -= dir * d * 2.;
            dir = reflect(dir, n);
            ref = 1.;
            td = 0.;
            ltd = td;
            continue;
        }
        if (d < det || td > 5.)
            break;
        td += d;
        g += .1 / (.1 + br * 13.);
        li += .1 / (.1 + tub * 5.);
    }
    g = max(g, li * .15);
    float f = 1. - td / 3.;
    if (ref == 1.)
        f = 1. - ltd / 3.;
    if (d < .01) {
        col = float3(1.0, 1.0, 1.0);
        float2 e = float2(0., det);
        float3 n = normalize(float3(de(p + e.yxx), de(p + e.xyx), de(p + e.xxy)) -
                           de(p));
        col = float3(n.x, n.x, n.x) * .7;
        col += frac(pos.z * 5.) * float3(.2, .1, .5);
        col += fractal(pos.xz * 2.);
        if (tub > .01)
            col = float3(0.0, 0.0, 0.0);
    }
    col *= f;
    float3 glo = g * .1 * float3(2., 1., 2.) * (.5 + so * 1.5) * .5;
    glo.rb = mul(glo.rb, rot(dir.y * 1.5));
    col += glo;
    col *= float3(.8, .7, .7);
    col = lerp(col, float3(1.0, 1.0, 1.0), ref * .3);
    return col;
}

float4 main(PixelShaderInput input) : SV_TARGET {

    float2 uv = input.texcoord;
    uv.x *= 1.3333;
        //float2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    //uv.x *= 1.333; // aspect ratio
    //uv /= float2(resolution.y / resolution.x, 1);
    float t = time;
    float3 from = path(t);
    if (fmod(time, 10.) > 5.)
        from = path(floor(t / 4. + .5) * 4.);
    sphpos = path(t + .5);
    from.x += .2;
    float3 fw = normalize(path(t + .5) - from);
    float3 dir = normalize(float3(uv, .5));
    dir = mul(dir, lookat(fw, float3(fw.x * 2., 1., 0.)));
    dir.xz += sin(time) * .3;
    float3 col = march(from, dir);
    col = lerp(float3(0.5, 0.5, 0.5) * length(col), col, 0.8);
    return float4(col, 1.);
}
