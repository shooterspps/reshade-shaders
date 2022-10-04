/*
    Magic Bloom by luluco250
    Attempts to simulate a natural-looking bloom.

    Features:

    --Wide bloom blurring, derived from the gaussian function
      defined here: https://en.wikipedia.org/wiki/Gaussian_blur#Mathematics

    --Eye adaptation, decreases or increases the brightness 
      of bloom according to the overall image luminance.

    --Lens dirt, as standard I suppose. Really not much here. 
      It uses an image named "MagicBloom_Dirt.png" so make 
      sure you have one in your textures directory.

    --Unwanted features can be disabled through 
      preprocessor definitions, saving performance.
    
    Preprocessor definitions:

    --MAGICBLOOM_ADAPT_RESOLUTION:
        Determines the width/height of the texture used for adaptation.
        It is recommended to use 256, but you can use as far as 1024 without issues.
        Too low resolutions will make adaptation seem "unstable".
        Must be a power of two value: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 etc.

    --MAGICBLOOM_BLUR_PRECALCULATED:
        If set to 0 the gaussian blur will be calculated inside the shader.
        Otherwise, it uses a pre-calculated kernel (array).
    
    --MAGICBLOOM_NODIRT:
        If set to 1 all lens dirt related features are disabled.
        Beneficial for performance if you don't wish to use lens dirt.

    --MAGICBLOOM_NOADAPT:
        If set to 1 all adaptation related features are disabled.
        Beneficial for performance if you don't wish to use adaptation.

    MIT Licensed:

    Copyright (c) 2017 luluco250

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

#include "ReShade.fxh"

//Statics

#ifndef MAGICBLOOM_ADAPT_RESOLUTION
    #define MAGICBLOOM_ADAPT_RESOLUTION 256
#endif

#ifndef MAGICBLOOM_BLUR_PRECALCULATED
    #define MAGICBLOOM_BLUR_PRECALCULATED 1
#endif

#ifndef MAGICBLOOM_NODIRT
    #define MAGICBLOOM_NODIRT 0
#endif

#ifndef MAGICBLOOM_NOADAPT
    #define MAGICBLOOM_NOADAPT 0
#endif

static const int iBlurSamples = 4;
static const int iAdaptResolution = MAGICBLOOM_ADAPT_RESOLUTION;

#define CONST_LOG2(v) (((v) & 0xAAAAAAAA) != 0) | ((((v) & 0xFFFF0000) != 0) << 4) | ((((v) & 0xFF00FF00) != 0) << 3) | ((((v) & 0xF0F0F0F0) != 0) << 2) | ((((v) & 0xCCCCCCCC) != 0) << 1)

static const float sigma = float(iBlurSamples) / 2.0;
static const float double_pi = 6.283185307179586476925286766559;
static const int lowest_mip = CONST_LOG2(iAdaptResolution) + 1;
static const float3 luma_value = float3(0.2126, 0.7152, 0.0722);

//Uniforms

#include "ReShadeUI.fxh"

uniform float fBloom_Intensity < __UNIFORM_SLIDER_FLOAT1
    ui_label = "绽放 强度";
    ui_tooltip = "应用于图像的绽放量。";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.0;

uniform float fBloom_Threshold <
    ui_label = "绽放 阈值";
    ui_tooltip =
    "阈值(限制)暗像素从被解释为绽放。\n"
    "本质上，它增加了绽放的对比度，并使较深的像素变黑。\n"
    "在1.0时，所有像素都被用于绽放。\n"
    "这个值不是归一化的，它是指数的，因此低值的变化比高值的变化更明显。";
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 10.0;
    ui_step = 0.1;
> = 2.0;

#if !MAGICBLOOM_NODIRT
uniform float fDirt_Intensity < __UNIFORM_SLIDER_FLOAT1
    ui_label = "污垢 强度";
    ui_tooltip = 
    "大量的镜片污垢应用于绽放。\n"
    "从你的纹理目录使用名为\"MagicBloom_Dirt.png\"的文件 。";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.0;
#endif

#if !MAGICBLOOM_NOADAPT
uniform float fExposure < __UNIFORM_SLIDER_FLOAT1
    ui_label = "曝光";
    ui_tooltip = 
    "绽放适应的目标曝光。\n"
    "建议将它设置为0.5，除非你希望得到更亮(1.0)或更暗(0.0)的图像。";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdapt_Speed <
    ui_label = "适应速度";
    ui_tooltip = 
    "快速绽放适应图像亮度的变化。\n"
    "在1.0时，变化是瞬时的。\n"
    "建议使用较低的值，介于0.01和0.1之间。\n"
    "0.1将提供一个快速而自然的适应。\n"
    "0.01将提供一种缓慢形式的适应。";
    ui_type = "drag";
    ui_min = 0.001;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.1;

uniform float fAdapt_Sensitivity < __UNIFORM_SLIDER_FLOAT1
    ui_label = "适应灵敏度";
    ui_tooltip = 
    "适应性对亮度的敏感性。\n"
    "在较高的值，速绽可以在最轻微的亮度变暗。\n"
    "在较低的值速绽将需要大量的图像亮度前，它完全变暗。"
    "1.0将不会修改亮度的数量，这是考虑到适应。\n"
    "0.5是一个不错的值，但可能会错过某些亮点。";
    ui_min = 0.0;
    ui_max = 3.0;
    ui_step = 0.001;
> = 1.0;

uniform float2 f2Adapt_Clip < __UNIFORM_SLIDER_FLOAT2
    ui_label = "适应最小/最大";
    ui_tooltip = 
    "决定了适应能决定调整绽放的最小值和最大值。\n"
    "减少最大值将导致绽放更明亮(因为它是不适应)。\n"
    "增加最小值将导致绽放变暗(因为它更适应)。\n"
    "使最大值大于或等于最小值，反之亦然。";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = float2(0.0, 1.0);

uniform int iAdapt_Precision < __UNIFORM_SLIDER_INT1
    ui_label = "适应精度";
    ui_tooltip = 
    "确定绽放如何准确地适应图像中心。\n"
    "在0处，自适应是从整个图像的平均值计算的。\n"
    "在最高值(可能有所不同)时，适应只关注屏幕的中心像素。\n"
    "建议使用接近0的值。";
    ui_min = 0;
    ui_max = lowest_mip;
    ui_step = 0.1;
> = lowest_mip * 0.3;
#endif

uniform uint iDebug <
    ui_label = "调试选项";
    ui_tooltip = "包含调试选项，如显示绽放纹理。";
    ui_type = "combo";
    ui_items = "无\0显示纹理\0";
> = 0;

//Textures

texture tMagicBloom_1 < pooled = true; > { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
texture tMagicBloom_2 < pooled = true; > { Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = RGBA16F; };
texture tMagicBloom_3 < pooled = true; > { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
texture tMagicBloom_4 < pooled = true; > { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = RGBA16F; };
texture tMagicBloom_5 < pooled = true; > { Width = BUFFER_WIDTH / 32; Height = BUFFER_HEIGHT / 32; Format = RGBA16F; };
texture tMagicBloom_6 < pooled = true; > { Width = BUFFER_WIDTH / 64; Height = BUFFER_HEIGHT / 64; Format = RGBA16F; };
texture tMagicBloom_7 < pooled = true; > { Width = BUFFER_WIDTH / 128; Height = BUFFER_HEIGHT / 128; Format = RGBA16F; };
texture tMagicBloom_8 < pooled = true; > { Width = BUFFER_WIDTH / 256; Height = BUFFER_HEIGHT / 256; Format = RGBA16F; };
#if !MAGICBLOOM_NOADAPT
texture tMagicBloom_Small { Width = iAdaptResolution; Height = iAdaptResolution; Format = R32F; MipLevels = lowest_mip; };
texture tMagicBloom_Adapt { Format = R32F; };
texture tMagicBloom_LastAdapt { Format = R32F; };
#endif
#if !MAGICBLOOM_NODIRT
texture tMagicBloom_Dirt <source="MagicBloom_Dirt.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
#endif

//Samplers

sampler sMagicBloom_1 { Texture = tMagicBloom_1; };
sampler sMagicBloom_2 { Texture = tMagicBloom_2; };
sampler sMagicBloom_3 { Texture = tMagicBloom_3; };
sampler sMagicBloom_4 { Texture = tMagicBloom_4; };
sampler sMagicBloom_5 { Texture = tMagicBloom_5; };
sampler sMagicBloom_6 { Texture = tMagicBloom_6; };
sampler sMagicBloom_7 { Texture = tMagicBloom_7; };
sampler sMagicBloom_8 { Texture = tMagicBloom_8; };
#if !MAGICBLOOM_NOADAPT
sampler sMagicBloom_Small { Texture = tMagicBloom_Small; };
sampler sMagicBloom_Adapt { Texture = tMagicBloom_Adapt; MinFilter = POINT; MagFilter = POINT; };
sampler sMagicBloom_LastAdapt { Texture = tMagicBloom_LastAdapt; MinFilter = POINT; MagFilter = POINT; };
#endif
#if !MAGICBLOOM_NODIRT
sampler sMagicBloom_Dirt { Texture = tMagicBloom_Dirt; };
#endif

//Functions

#if !MAGICBLOOM_BLUR_PRECALCULATED
float gaussian_function(float2 i) {
    static const float first_part = 1.0 / (double_pi * pow(sigma, 2.0));
    static const float second_part_a = 1.0 / (2.0 * pow(sigma, 2.0));
    float second_part_b = (pow(i.x, 2.0) + pow(i.y, 2.0)) * second_part_a;
    return first_part * exp(-second_part_b);
}
#endif

//Why use a single-pass blur? To reduce the amount of textures used in half.
//Scale should be the original resolution divided by target resolution.
float3 blur(sampler sp, float2 uv, float scale) {
    float2 ps = BUFFER_PIXEL_SIZE * scale;
    
    #if MAGICBLOOM_BLUR_PRECALCULATED
    static const float kernel[9] = { 
        0.0269955, 0.0647588, 0.120985, 0.176033, 0.199471, 0.176033, 0.120985, 0.0647588, 0.0269955 
    };
    static const float accum = 1.02352;
    #else
    float accum = 0.0;
    #endif
    
    float gaussian_weight = 0.0;
    float3 col = 0.0;
    
    [loop]
    for (int x = -iBlurSamples; x <= iBlurSamples; ++x) {
        for (int y = -iBlurSamples; y <= iBlurSamples; ++y) {
            #if MAGICBLOOM_BLUR_PRECALCULATED
            gaussian_weight = kernel[x + iBlurSamples] * kernel[y + iBlurSamples];
            #else
            gaussian_weight = gaussian_function(float2(x, y));
            accum += gaussian_weight;
            #endif
            col += tex2D(sp, uv + ps * float2(x, y)).rgb * gaussian_weight;
        }
    }

    #if MAGICBLOOM_BLUR_PRECALCULATED
    return col * accum;
    #else
    return col / accum;
    #endif
}

/*
    Uncharted 2 Tonemapper

    Thanks John Hable and Naughty Dog.
*/
float3 tonemap(float3 col, float exposure) {
    static const float A = 0.15; //shoulder strength
    static const float B = 0.50; //linear strength
	static const float C = 0.10; //linear angle
	static const float D = 0.20; //toe strength
	static const float E = 0.02; //toe numerator
	static const float F = 0.30; //toe denominator
	static const float W = 11.2; //linear white point value

    col *= exposure;

    col = ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
    static const float white = 1.0 / (((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F);
    col *= white;
    return col;
}

float3 blend_screen(float3 a, float3 b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
}

/*
    The function below is a leftover from debugging.
    It just draws a line on the screen, it's horizontal position being
    the value you specify (from 0.0-1.0, becoming left-right).
    No use now but might be useful later on so I just left it here.
*/
/*void debug_value(inout float3 col, float2 uv, float value, float3 needle_color) {
    static const float2 ps = BUFFER_PIXEL_SIZE;
    col = (uv.x + ps.x > value && uv.x - ps.x < value) ? needle_color : col;
}*/

//Shaders

/*
    Thresholding is performed on the first blur for two reasons:
    --Save an entire texture from being used to threshold.
    --Being the smallest blur it also results in the least amount of artifacts.
*/
float4 PS_Blur1(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    float3 col = blur(ReShade::BackBuffer, uv, 2.0);
    col = pow(abs(col), fBloom_Threshold);
    col *= fBloom_Intensity;
    return float4(col, 1.0);
}

float4 PS_Blur2(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_1, uv, 4.0), 1.0);
}

float4 PS_Blur3(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_2, uv, 8.0), 1.0);
}

float4 PS_Blur4(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_3, uv, 8.0), 1.0);
}

float4 PS_Blur5(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_4, uv, 16.0), 1.0);
}

float4 PS_Blur6(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_5, uv, 32.0), 1.0);
}

float4 PS_Blur7(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_6, uv, 64.0), 1.0);
}

float4 PS_Blur8(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return float4(blur(sMagicBloom_7, uv, 128.0), 1.0);
}

//Final blend shader
float4 PS_Blend(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 bloom = tex2D(sMagicBloom_1, uv).rgb
                 + tex2D(sMagicBloom_2, uv).rgb
                 + tex2D(sMagicBloom_3, uv).rgb
                 + tex2D(sMagicBloom_4, uv).rgb
                 + tex2D(sMagicBloom_5, uv).rgb
                 + tex2D(sMagicBloom_6, uv).rgb
                 + tex2D(sMagicBloom_7, uv).rgb
                 + tex2D(sMagicBloom_8, uv).rgb;
    //Dunno if making the division by 8 a static multiplication helps, but whatever.
    static const float bloom_accum = 1.0 / 8.0;
    bloom *= bloom_accum;

    #if !MAGICBLOOM_NOADAPT
    float exposure = fExposure / max(tex2D(sMagicBloom_Adapt, 0.0).x, 0.00001);
    bloom = tonemap(bloom, exposure);
    #else
    //Without adaptation it seems 100.0 exposure is needed for bloom to look bright enough.
    bloom = tonemap(bloom, 100.0);
    #endif

    #if !MAGICBLOOM_NODIRT
    float3 dirt = tex2D(sMagicBloom_Dirt, uv).rgb;
    dirt *= fDirt_Intensity;
    bloom = blend_screen(bloom, dirt * bloom);
    #endif

    col = blend_screen(col, bloom);

    //If we're to display the bloom texture, we replace col with it.
    col = iDebug == 1 ? bloom : col;

    return float4(col, 1.0);
}

#if !MAGICBLOOM_NOADAPT
/*
    How adaptation works:
    --Calculate image luminance.
    --Save it to a smaller, mipmapped texture.
    --Mipmaps require a power of 2 texture.
    --Fetch a mipmap level according to a specfied amount of precision.
    --The lowest mipmap is simply an average of the entire image.
*/
float PS_GetSmall(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return dot(tex2D(ReShade::BackBuffer, uv).rgb, luma_value);
}

float PS_GetAdapt(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    float curr = tex2Dlod(sMagicBloom_Small, float4(0.5, 0.5, 0, lowest_mip - iAdapt_Precision)).x;
    curr *= fAdapt_Sensitivity;
    curr = clamp(curr, f2Adapt_Clip.x, f2Adapt_Clip.y);
    float last = tex2D(sMagicBloom_LastAdapt, 0.0).x;
    //Using the frametime/delta here would actually scale adaptation with the framerate.
    //We don't want that, so we don't even bother with it.
    return lerp(last, curr, fAdapt_Speed);
}

float PS_SaveAdapt(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return tex2D(sMagicBloom_Adapt, 0.0).x;
}
#endif

technique MagicBloom 
<
	ui_label = "魔法绽放";
>
{
    pass Blur1 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur1;
        RenderTarget = tMagicBloom_1;
    }
    pass Blur2 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur2;
        RenderTarget = tMagicBloom_2;
    }
    pass Blur3 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur3;
        RenderTarget = tMagicBloom_3;
    }
    pass Blur4 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur4;
        RenderTarget = tMagicBloom_4;
    }
    pass Blur5 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur5;
        RenderTarget = tMagicBloom_5;
    }
    pass Blur6 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur6;
        RenderTarget = tMagicBloom_6;
    }
    pass Blur7 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur7;
        RenderTarget = tMagicBloom_7;
    }
    pass Blur8 {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blur8;
        RenderTarget = tMagicBloom_8;
    }
    pass Blend {
        VertexShader = PostProcessVS;
        PixelShader = PS_Blend;
    }
    #if !MAGICBLOOM_NOADAPT
    pass GetSmall {
        VertexShader = PostProcessVS;
        PixelShader = PS_GetSmall;
        RenderTarget = tMagicBloom_Small;
    }
    pass GetAdapt {
        VertexShader = PostProcessVS;
        PixelShader = PS_GetAdapt;
        RenderTarget = tMagicBloom_Adapt;
    }
    pass SaveAdapt {
        VertexShader = PostProcessVS;
        PixelShader = PS_SaveAdapt;
        RenderTarget = tMagicBloom_LastAdapt;
    }
    #endif
}
