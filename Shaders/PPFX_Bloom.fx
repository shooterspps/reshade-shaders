// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
// *** PPFX Bloom from the Post-Processing Suite 1.03.29 for ReShade
// *** SHADER AUTHOR: Pascal Matthäus ( Euda )
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++

//+++++++++++++++++++++++++++++
// DEV_NOTES
//+++++++++++++++++++++++++++++
// Updated for compatibility with ReShade 4 and isolated by Marot Satil.

#include "ReShade.fxh"

//+++++++++++++++++++++++++++++
// CUSTOM PARAMETERS
//+++++++++++++++++++++++++++++

// ** HDR **
uniform bool pEnableHDR <
   ui_category = "HDR和色调映射";
   ui_label = "开启HDR和色调映射";
   ui_tooltip = "由于像光绽放这样的亮度增加效果会使颜色超过标准显示器的最大亮度，\n从而导致颜色过度饱和，并导致明亮区域出现难看的白色“补丁”，这些颜色必须“重新映射”到显示器范围内。\n有几种方法可以解决这个问题，实际上这是一个完整的科学领域。当然可配置。";
> = 0;

// ** TONEMAP **
uniform int pTonemapMode <
    ui_category = "HDR和色调映射";
    ui_label = "色调映射模式";
    ui_tooltip = "选择一个适合你个人品味的色调映射算法。";
    ui_type = "combo";
    ui_items="线性的，推荐用于非常低的光绽放强度值\0平方\0log10-对数+曝光校正\0";
> = 0;

uniform float pTonemapCurve <
    ui_category = "HDR和色调映射";
    ui_label = "色调映射曲线";
    ui_tooltip = "鲜艳的颜色是如何压缩的。高值可能会使阴影和中间色调变暗，同时保留明亮区域的细节(例如几乎明亮的天空)。";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 100.0;
    ui_step = 0.5;
> = 3.0;

uniform float pTonemapExposure <
    ui_category = "HDR和色调映射";
    ui_label = "色调映射曝光调整";
    ui_tooltip = "每个像素在被映射之前都乘以这个值。\n您可以使用它作为亮度控制或为色调映射对比度指定一个中灰度值。";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.2;

uniform float pTonemapContrast <
    ui_category = "HDR和色调映射";
    ui_label = "色调映射对比强度";
    ui_tooltip = "大于1的像素被调暗，高于1的像素被曝光。\n结合更高(2 - 7)色调映射曝光值，以创建一个理想的外观。";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.020;

uniform float pTonemapSaturateBlacks <
    ui_category = "HDR和色调映射";
    ui_label = "色调映射黑色饱和";
    ui_tooltip = "一些映射算法可能会降低你的阴影饱和度-这个选项修正了这个问题。\n不要使用太高的值，这是一个微妙的修正。";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.0;

// ** BLOOM **
#ifndef   pBloomDownsampling
#define		pBloomDownsampling		4		// Bloom Downsampling Factor - Downscales the image before calculating the bloom, thus drastically increasing performance. '1' is fullscreen which doesn't really make sense. I suggest 2-4. High values will cause temporal aliasing | 1 - 16
#endif

#ifndef   pBloomPrecision
#define		pBloomPrecision			RGBA16	// Bloom Sampling Precision - Options: RGBA8 (low quality, high performance) / RGBA16 (high quality, slightly slower depending on your system) / RGBA32F (overkill)
#endif

uniform float pBloomRadius <
    ui_category = "光绽放";
    ui_label = "光绽放采样半径";
    ui_tooltip = "像素之间的最大距离相互影响-直接影响性能:结合pBloomDownsampling增加你的有效半径，同时保持高帧率。";
    ui_type = "slider";
    ui_min = 2.0;
    ui_max = 250.0;
    ui_step = 1.0;
> = 64.0;

uniform float pBloomIntensity <
    ui_category = "光绽放";
    ui_label = "光绽放整体强度";
    ui_tooltip = "光绽放的曝光度，我强烈建议将它与色调映射结合，如果你在这里选择一个高值。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.2;
> = 0.5;

uniform int pBloomBlendMode <
    ui_category = "光绽放";
    ui_label = "光绽放混合模式";
    ui_tooltip = "控制如何将光绽放与原始帧混合。";
    ui_type = "combo";
    ui_items="添加剂(建议与色调映射一起使用)\0点亮(适合于夜景)\0封面(配置/调试)\0";
> = 0;

uniform float pBloomThreshold <
    ui_category = "光绽放";
    ui_label = "光绽放阈值";
    ui_tooltip = "比这个值暗的像素不会产生光绽放。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.4;

uniform float pBloomCurve <
    ui_category = "光绽放";
    ui_label = "光绽放曲线";
    ui_tooltip = "这种效果的伽玛曲线-越高，在黑暗的区域，光绽放越少-反之亦然。";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 4.0;
    ui_step = 0.01;
> = 1.5;

uniform float pBloomSaturation <
    ui_category = "光绽放";
    ui_label = "光绽放色饱和度";
    ui_tooltip = "效果的颜色饱和度。0表示白色，无颜色的光绽放，1500 - 3000产生一个充满活力的效果，而以上的一切应该让你的眼睛流血。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.001;
> = 2.0;

// ** LENSDIRT **
uniform bool pEnableLensdirt <
    ui_category = "镜头污垢";
    ui_label = "启用镜头污垢";
    ui_tooltip = "模拟一个脏镜头。这一效果在2011年的《战地3》中被引入，此后许多游戏工作室也开始使用这一效果。\n如果启用，光绽放纹理将用于亮度检查，从而缩放强度与局部亮度，而不是当前像素的一个。";
> = 0;

uniform float pLensdirtIntensity <
    ui_category = "镜头污垢";
    ui_label = "镜头污垢强度";
    ui_tooltip = "污垢纹理的最大强度。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float pLensdirtCurve <
    ui_category = "镜头污垢";
    ui_label = "镜头污垢曲线";
    ui_tooltip = "污垢纹理强度的曲线-尝试更高的值来限制只在明亮/近乎白色的场景中可见性。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.1;
> = 1.2;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TEXTURES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
texture2D texColor : COLOR;
texture texColorHDRA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture texColorHDRB < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };

// *** FX RTs ***
texture texBloomA 
{
	Width = BUFFER_WIDTH/pBloomDownsampling;
	Height = BUFFER_HEIGHT/pBloomDownsampling;
	// Available formats: R8, R32F, RG8, RGBA8, RGBA16, RGBA16F, RGBA32F
	Format = pBloomPrecision;
};
texture texBloomB < pooled = true; > 
{
	Width = BUFFER_WIDTH/pBloomDownsampling;
	Height = BUFFER_HEIGHT/pBloomDownsampling;
	Format = pBloomPrecision;
};

// *** EXTERNAL TEXTURES ***
texture texBDirt < source = "DirtA.png"; >
{
	Width = 1920;
	Height = 1080;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   SAMPLERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
sampler2D SamplerColor
{
	Texture = texColor;
	AddressU = BORDER;
	AddressV = BORDER;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
#if BUFFER_COLOR_BIT_DEPTH != 10
	SRGBTexture = TRUE;
#endif
};

sampler SamplerColorHDRA
{
	Texture = texColorHDRA;
	AddressU = BORDER;
	AddressV = BORDER;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler SamplerColorHDRB
{
	Texture = texColorHDRB;
	AddressU = BORDER;
	AddressV = BORDER;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

// *** FX RTs ***
sampler SamplerBloomA
{
	Texture = texBloomA;
};
sampler SamplerBloomB
{
	Texture = texBloomB;
};

// *** EXTERNAL TEXTURES ***
sampler SamplerDirt
{
	Texture = texBDirt;
	SRGBTexture = TRUE;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VARIABLES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static const float2 pxSize = float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT);
static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   STRUCTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

struct VS_OUTPUT_POST
{
	float4 vpos : SV_Position;
	float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
	uint id : SV_VertexID;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   HELPERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 threshold(float3 pxInput, float colThreshold)
{
	return pxInput*max(0.0,sign(max(pxInput.x,max(pxInput.y,pxInput.z))-colThreshold));
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   EFFECTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** Gaussian Blur ***

	// Gaussian Blur - Horizontal
	float3 FX_BlurH( float3 pxInput, sampler source, float2 txCoords, float radius, float downsampling )
	{
		float	texelSize = pxSize.x*downsampling;
		float2	fetchCoords = txCoords;
		float	weight;
		float	weightDiv = 1.0+5.0/radius;
		float	sampleSum = 0.5;
		
		pxInput+=tex2D(source,txCoords).xyz*0.5;
		
		[loop]
		for (float hOffs=1.5; hOffs<radius; hOffs+=2.0)
		{
			weight = 1.0/pow(abs(weightDiv),hOffs*hOffs/radius);
			fetchCoords = txCoords;
			fetchCoords.x += texelSize * hOffs;
			pxInput+=tex2Dlod(source, float4(fetchCoords, 0.0, 0.0)).xyz * weight;
			fetchCoords = txCoords;
			fetchCoords.x -= texelSize * hOffs;
			pxInput+=tex2Dlod(source, float4(fetchCoords, 0.0, 0.0)).xyz * weight;
			sampleSum += 2.0 * weight;
		}
		pxInput /= sampleSum;
		
		return pxInput;
	}
	
	// Gaussian Blur - Vertical
	float3 FX_BlurV( float3 pxInput, sampler source, float2 txCoords, float radius, float downsampling )
	{
		float	texelSize = pxSize.y*downsampling;
		float2	fetchCoords = txCoords;
		float	weight;
		float	weightDiv = 1.0+5.0/radius;
		float	sampleSum = 0.5;
		
		pxInput+=tex2D(source,txCoords).xyz*0.5;
		
		[loop]
		for (float vOffs=1.5; vOffs<radius; vOffs+=2.0)
		{
			weight = 1.0/pow(abs(weightDiv),vOffs*vOffs/radius);
			fetchCoords = txCoords;
			fetchCoords.y += texelSize * vOffs;
			pxInput+=tex2Dlod(source, float4(fetchCoords, 0.0, 0.0)).xyz * weight;
			fetchCoords = txCoords;
			fetchCoords.y -= texelSize * vOffs;
			pxInput+=tex2Dlod(source, float4(fetchCoords, 0.0, 0.0)).xyz * weight;
			sampleSum += 2.0 * weight;
		}
		pxInput /= sampleSum;
		
		return pxInput;
	}

	
// *** Bloom ***
	// Bloom - Mix-pass
	float4 FX_BloomMix( float3 pxInput, float2 txCoords )
	{
		float3 blurTexture = tex2D(SamplerBloomA,txCoords).xyz;

		if (pEnableLensdirt)
			pxInput += tex2D(SamplerDirt, txCoords).xyz*pow(dot(abs(blurTexture),lumaCoeff),pLensdirtCurve)*pLensdirtIntensity; 
		blurTexture = pow(abs(blurTexture),pBloomCurve);
		blurTexture = lerp(dot(blurTexture.xyz,lumaCoeff.xyz),blurTexture,pBloomSaturation);
		blurTexture /= max(1.0,max(blurTexture.x,max(blurTexture.y,blurTexture.z)));
		if (pBloomBlendMode == 0)
		{
			pxInput = pxInput+blurTexture*pBloomIntensity;
			return float4(pxInput,1.0+pBloomIntensity);
		}
		else if (pBloomBlendMode == 1)
		{
			pxInput = max(pxInput,blurTexture*pBloomIntensity);
			return float4(pxInput,max(1.0,pBloomIntensity));
		}
    else
    {
			pxInput = blurTexture;
			return float4(pxInput,pBloomIntensity);
		}
	}
	
// *** Custom Tonemapping ***
	float3 FX_Tonemap( float3 pxInput, float whitePoint )
	{
		pxInput = pow(abs(pxInput*pTonemapExposure),pTonemapContrast);
		whitePoint = pow(abs(whitePoint*pTonemapExposure),pTonemapContrast);
		
		if (pTonemapMode == 1)
			return saturate(pxInput.xyz/(whitePoint*pTonemapCurve));
		else if (pTonemapMode == 2)
			return saturate(lerp(pxInput,pow(abs(pxInput.xyz/whitePoint),whitePoint-pxInput),dot(pxInput/whitePoint,lumaCoeff)));
		else
		{
			float exposureDiv = log10(whitePoint+1.0)/log10(whitePoint+1.0+pTonemapCurve);
			pxInput.xyz = (log10(pxInput+1.0)/log10(pxInput+1.0+pTonemapCurve))/exposureDiv;
			return saturate(lerp(pow(abs(pxInput.xyz), 1.0 + pTonemapSaturateBlacks), pxInput.xyz, sqrt( pxInput.xyz ) ) );
		}
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VERTEX-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;
	OUT.txcoord.x = (IN.id == 2) ? 2.0 : 0.0;
	OUT.txcoord.y = (IN.id == 1) ? 2.0 : 0.0;
	OUT.vpos = float4(OUT.txcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return OUT;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   PIXEL-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** Shader Structure ***
float4 PS_SetOriginal(VS_OUTPUT_POST IN) : COLOR
{
  if (pEnableHDR == 0)
    return tex2D(ReShade::BackBuffer,IN.txcoord.xy);
  else
    return float4(tex2D(SamplerColor,IN.txcoord.xy).xyz,1.0);
}

// *** Bloom ***
	float4 PS_BloomThreshold(VS_OUTPUT_POST IN) : COLOR
	{
		return float4(threshold(tex2D(SamplerColorHDRA,IN.txcoord.xy).xyz,pBloomThreshold),1.0);
	}

	float4 PS_BloomH_RadA(VS_OUTPUT_POST IN) : COLOR
	{
		return float4(FX_BlurH(0.0,SamplerBloomA,IN.txcoord.xy,pBloomRadius,pBloomDownsampling),1.0);
	}

	float4 PS_BloomV_RadA(VS_OUTPUT_POST IN) : COLOR
	{
		return float4(FX_BlurV(0.0,SamplerBloomB,IN.txcoord.xy,pBloomRadius,pBloomDownsampling),1.0);
	}

	float4 PS_BloomMix(VS_OUTPUT_POST IN) : COLOR
	{
		return FX_BloomMix(tex2D(SamplerColorHDRA,IN.txcoord.xy).xyz,IN.txcoord.xy);
	}

// *** Further FX ***
float4 PS_LightFX(VS_OUTPUT_POST IN) : COLOR
{
	float2 pxCoord = IN.txcoord.xy;
	float4 res = tex2D(SamplerColorHDRB,pxCoord);
	
	if (pEnableHDR == 1)
    res.xyz = FX_Tonemap(res.xyz,res.w);
	
	return res;
}

float4 PS_ColorFX(VS_OUTPUT_POST IN) : COLOR
{
	float2 pxCoord = IN.txcoord.xy;
	float4 res = tex2D(SamplerColorHDRA,pxCoord);
	
	return float4(res.xyz,1.0);
}

float4 PS_ImageFX(VS_OUTPUT_POST IN) : COLOR
{
	float2 pxCoord = IN.txcoord.xy;
	float4 res = tex2D(SamplerColorHDRB,pxCoord);
	
	return float4(res.xyz,1.0);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TECHNIQUES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique PPFXBloom 
< 
	ui_label = "光影-光绽放"; 
	ui_tooltip = "光绽放 | 这种效果让明亮的像素将光线照射到周围的环境中。它速度快，高度可定制，适合许多游戏。"; 
>
{
	pass setOriginal
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SetOriginal;
		RenderTarget0 = texColorHDRA;
	}
	pass bloomThresh
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_BloomThreshold;
		RenderTarget0 = texBloomA;
	}
		
	pass bloomH_RadA
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_BloomH_RadA;
		RenderTarget0 = texBloomB;
	}
		
	pass bloomV_RadA
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_BloomV_RadA;
		RenderTarget0 = texBloomA;
	}
		
	pass bloomMix
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_BloomMix;
		RenderTarget0 = texColorHDRB;
	}
	pass lightFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_LightFX;
		RenderTarget0 = texColorHDRA;
	}
	pass colorFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_ColorFX;
		RenderTarget0 = texColorHDRB;
	}
	
	pass imageFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_ImageFX;
	}
}
