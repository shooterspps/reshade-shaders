// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
// *** PPFX SSDO 2.0 for ReShade
// *** SHADER AUTHOR: Pascal Matthäus ( Euda )
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++

//+++++++++++++++++++++++++++++
// DEV_NOTES
//+++++++++++++++++++++++++++++
// Updated for compatibility with ReShade 4 and isolated by Marot Satil.
// Reshade.fxh Preprocessor Definition Support added by JJXB
#include "ReShade.fxh"
//+++++++++++++++++++++++++++++
// CUSTOM PARAMETERS
//+++++++++++++++++++++++++++++

// ** SSDO **

#ifndef pSSDOSamplePrecision
#define		pSSDOSamplePrecision		RGBA16F // SSDO Sample Precision - The texture format of the source texture used to calculate the effect. RGBA8 is generally too low, RGBA16F should be the sweet-spot. RGBA32F is overkill and heavily kills your FPS.
#endif

#ifndef pSSDOLOD
#define		pSSDOLOD					1.0		// SSDO LOD - A scale factor for the resolution which the effect is calculated in - 1.0: Full Resolution, 0.5: Half Resolution, 0.25: Quarter, etc.
#endif

#ifndef pSSDOFilterScale
#define		pSSDOFilterScale			1.0		// SSDO Filter Scale Factor - Resolution control for the filter where noise the technique produces gets removed. Performance-affective. 0.5 means half resolution, 0.25 = quarter res,  1 = full-res. etc. Values above 1.0 yield a downsampled blur which doesn't make sense and is not recommended. | 0.1 - 4.0
#endif

#ifndef qSSDOFilterPrecision
#define		qSSDOFilterPrecision		RGBA16	// SSDO Filter Precision - The texture format used when filtering out the SSDO's noise. Use this to prevent banding artifacts that you may see in combination with very high ssdoIntensity values. RGBA16F, RGBA32F or, standard, RGBA8. Strongly suggest the latter to keep high framerates.
#endif

uniform float pSSDOIntensity <
    ui_label = "强度";
    ui_tooltip = "应用于效果的强度曲线。当与RGBA8滤波精度一起使用时，高值可能会产生条带。\n由于增加RGBA16F的精度将严重影响性能，如果你想要高可视性，最好结合强度和数量。";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 20.0;
    ui_step = 0.001;
> = 1.5;

uniform float pSSDOAmount <
    ui_label = "数量";
    ui_tooltip = "在计算遮挡/光照因子时应用乘数。\n高值会增加效果的可见性，但也会暴露出伪影和噪声。";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 10.0;
    ui_step = 0.01;
> = 1.5;

uniform float pSSDOBounceMultiplier <
    ui_label = "间接反弹颜色乘数";
    ui_tooltip = "屏空间定向遮挡包括光的间接反射，这意味着物体的颜色可能相互作用。这个值控制效果的可见性。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.8;

uniform float pSSDOBounceSaturation <
    ui_label = "间接反射色饱和度";
    ui_tooltip = "高值可能看起来很奇怪。";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 2.0;
    ui_step = 0.01;
> = 1.0;

uniform int pSSDOSampleAmount <
    ui_label = "采样计数";
    ui_tooltip = "积累屏空间定向遮挡的样本量。\n影响质量，降低噪音和几乎线性影响性能。\n目前的高端系统应该在全高清模式下最大达到32个样本以达到理想的帧率。";
    ui_type = "slider";
    ui_min = 1;
    ui_max = 256;
    ui_step = 1;
> = 10;

uniform float pSSDOSampleRange <
    ui_label = "采样范围";
    ui_tooltip = "遮挡器遮挡几何体的最大距离。\n高值会降低缓存一致性，导致缓存丢失，从而降低性能，所以保持在~150以下。\n您可以通过增加源LOD来防止这种性能下降。";
    ui_type = "slider";
    ui_min = 4.0;
    ui_max = 1000.0;
    ui_step = 0.1;
> = 70.0;

uniform int pSSDOSourceLOD <
    ui_label = "LOD源";
    ui_tooltip = "用于计算遮挡/间接光的源纹理的mipmap级别。\n0 =全分辨率，1 =半轴分辨率，2 =四分之一轴分辨率等。\n结合高的样本范围值，这可能会提高性能，但质量略有损失。";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 3;
    ui_step = 1;
> = 2;

uniform int pSSDOBounceLOD <
    ui_label = "间接反弹LOD";
    ui_tooltip = "用于计算光反射的颜色纹理的mipmap级别。\n0 =全分辨率，1 =半轴分辨率，2 =四分之一轴分辨率等。\n结合高的样本范围值，这可能会在略微降低质量的情况下提高性能。";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 3;
    ui_step = 1;
> = 3;

uniform float pSSDOFilterRadius <
    ui_label = "过滤半径";
    ui_tooltip = "用于过滤技术产生的噪声的模糊半径。\n不要把它推得太高，建议在8 - 24小时之间\n(根据采样量，采样范围，强度和数量)。";
    ui_type = "slider";
    ui_min = 2.0;
    ui_max = 100.0;
    ui_step = 1.0;
> = 8.0;

uniform float pSSDOAngleThreshold <
    ui_label = "角度阈值";
    ui_tooltip = "定义点在计算遮挡时贡献的最小角度。这类似于其他环境遮挡着色器中的深度偏差参数。";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 0.5;
    ui_step = 0.01;
> = 0.125;

uniform float pSSDOFadeStart <
    ui_label = "绘制距离:淡出开始";
    ui_tooltip = "影响开始减弱的距离。使用此滑块与淡出结束滑块组合创建平滑的淡出效果。";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 0.95;
    ui_step = 0.01;
> = 0.9;

uniform float pSSDOFadeEnd <
    ui_label = "绘制距离:淡出结束";
    ui_tooltip = "这个值定义了效果被截断的距离。使用此滑块与渐退开始滑块组合，创建平滑的渐退效果。";
    ui_type = "slider";
    ui_min = 0.15;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.95;

uniform int pSSDODebugMode <
    ui_label = "调试视图";
    ui_type = "combo";
    ui_items = "调试模式关闭\0输出过滤的SSDO组件\0向你展示原始的，嘈杂的SSDO在散射遮挡/光照后\0";
> = 0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TEXTURES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
texture texColorLOD { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 4; };
texture texDepth : DEPTH;

// *** FX RTs ***
texture texViewSpace < pooled = true; > 
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = pSSDOSamplePrecision;
	MipLevels = 4;
};
texture texSSDOA
{
	Width = BUFFER_WIDTH*pSSDOLOD;
	Height = BUFFER_HEIGHT*pSSDOLOD;
	Format = qSSDOFilterPrecision;
};
texture texSSDOB
{
	Width = BUFFER_WIDTH*pSSDOFilterScale;
	Height = BUFFER_HEIGHT*pSSDOFilterScale;
	Format = qSSDOFilterPrecision;
};
texture texSSDOC < pooled = true; > 
{
	Width = BUFFER_WIDTH*pSSDOFilterScale;
	Height = BUFFER_HEIGHT*pSSDOFilterScale;
	Format = qSSDOFilterPrecision;
};

// *** EXTERNAL TEXTURES ***
texture texNoise < source = "ssdonoise.png"; >
{
	Width = 4;
	Height = 4;
	Format = R8;
	#define NOISE_SCREENSCALE float2((BUFFER_WIDTH*pSSDOLOD)/4.0,(BUFFER_HEIGHT*pSSDOLOD)/4.0)
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   SAMPLERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
sampler SamplerColorLOD
{
	Texture = texColorLOD;
	SRGBTexture = true;
};

sampler2D SamplerDepth
{
	Texture = texDepth;
};

// *** FX RTs ***
sampler SamplerViewSpace
{
	Texture = texViewSpace;
};
sampler SamplerSSDOA
{
	Texture = texSSDOA;
};
sampler SamplerSSDOB
{
	Texture = texSSDOB;
};
sampler SamplerSSDOC
{
	Texture = texSSDOC;
};

// *** EXTERNAL TEXTURES ***
sampler SamplerNoise
{
	Texture = texNoise;
	MipFilter = POINT;
	MinFilter = POINT;
	MagFilter = POINT;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VARIABLES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static const float2 pxSize = float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT);
static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);
#define ZNEAR 0.1
#define ZFAR 30.0

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

float linearDepth(float2 txCoords)
{
	return ReShade::GetLinearizedDepth(txCoords);
}

float4 viewSpace(float2 txCoords)
{
	float2 offsetS = float2(0.0,1.0)*pxSize;
	float2 offsetE = float2(1.0,0.0)*pxSize;
	float depth = linearDepth(txCoords);
	float depthS = linearDepth(txCoords+offsetS);
	float depthE = linearDepth(txCoords+offsetE);
	
	float3 vsNormal = cross(float3((-offsetS)*depth,depth-depthS),float3(offsetE*depth,depth-depthE));
	return float4(normalize(vsNormal),depth);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   EFFECTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** SSDO ***
	#define SSDO_CONTRIB_RANGE (pSSDOSampleRange*(pxSize.y/pSSDOLOD))
	#define SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER 0.1
	
	// SSDO - Scatter Illumination
	float4 FX_SSDOScatter( float2 txCoords )
	{
		float	sourceAxisDiv = pow(2.0,pSSDOSourceLOD);
		float2	texelSize = pxSize.xy*pow(2.0,pSSDOSourceLOD).xx;
		float4	vsOrig = tex2D(SamplerViewSpace,txCoords);
		float3	ssdo = 0.0;
		
		float	randomDir = tex2D(SamplerNoise,frac(txCoords*NOISE_SCREENSCALE)).x;
		const float2	stepSize = (pSSDOSampleRange/(pSSDOSampleAmount*sourceAxisDiv))*texelSize;

		for (float offs=1.0;offs<=pSSDOSampleAmount;offs++)
		{
			float2 fetchDir = normalize(frac(float2(randomDir*811.139795*offs,randomDir*297.719157*offs))*2.0-1.0);
			fetchDir *= sign(dot(normalize(float3(fetchDir.x,-fetchDir.y,1.0)),vsOrig.xyz)); // flip directions
			float2 fetchCoords = txCoords+fetchDir*stepSize*offs*max(0.75,offs/pSSDOSampleAmount);
			float4 vsFetch = tex2Dlod(SamplerViewSpace,float4(fetchCoords,0,pSSDOSourceLOD));
			
			float3 albedoFetch = tex2Dlod(SamplerColorLOD,float4(fetchCoords,0,pSSDOBounceLOD)).xyz;
			albedoFetch = pow(albedoFetch,pSSDOBounceSaturation);
			albedoFetch = normalize(albedoFetch);
			albedoFetch *= pSSDOBounceMultiplier;
			albedoFetch = 1.0-albedoFetch;
			
			float3 dirVec = float3(fetchCoords.x-txCoords.x,txCoords.y-fetchCoords.y,vsOrig.w-vsFetch.w);
			dirVec.xy *= vsOrig.w;
			float3 dirVecN = normalize(dirVec);
			float visibility = step(pSSDOAngleThreshold,dot(dirVecN,vsOrig.xyz)); // visibility check w/ angle threshold
			visibility *= sign(max(0.0,abs(length(vsOrig.xyz-vsFetch.xyz))-0.01)); // normal bias
			float distFade = max(0.0,SSDO_CONTRIB_RANGE-length(dirVec))/SSDO_CONTRIB_RANGE; // attenuation
			ssdo += albedoFetch * visibility * distFade * distFade * pSSDOAmount;
		}
		ssdo /= pSSDOSampleAmount;
		
		return float4(saturate(1.0-ssdo*smoothstep(pSSDOFadeEnd,pSSDOFadeStart,vsOrig.w)),vsOrig.w);
	}

	// Depth-Bilateral Gaussian Blur - Horizontal
	float4 FX_BlurBilatH( float2 txCoords, float radius )
	{
		float	texelSize = pxSize.x/pSSDOFilterScale;
		float4	pxInput = tex2D(SamplerSSDOB,txCoords);
		pxInput.xyz *= 0.5;
		float	sampleSum = 0.5;
		
		[loop]
		for (float hOffs=1.5; hOffs<radius; hOffs+=2.0)
		{
			float weight = 1.0;
			float2 fetchCoords = txCoords;
			fetchCoords.x += texelSize * hOffs;
			float4 fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
			float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
			fetchCoords = txCoords;
			fetchCoords.x -= texelSize * hOffs;
			fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
			contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
		}
		pxInput.xyz /= sampleSum;
		
		return pxInput;
	}
	
	// Depth-Bilateral Gaussian Blur - Vertical
	float3 FX_BlurBilatV( float2 txCoords, float radius )
	{
		float	texelSize = pxSize.y/pSSDOFilterScale;
		float4	pxInput = tex2D(SamplerSSDOC,txCoords);
		pxInput.xyz *= 0.5;
		float	sampleSum = 0.5;
		
		[loop]
		for (float vOffs=1.5; vOffs<radius; vOffs+=2.0)
		{
			float weight = 1.0;
			float2 fetchCoords = txCoords;
			fetchCoords.y += texelSize * vOffs;
			float4 fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
			float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
			fetchCoords = txCoords;
			fetchCoords.y -= texelSize * vOffs;
			fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
			contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
		}
		pxInput /= sampleSum;
		
		return pxInput.xyz;
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
    return tex2D(ReShade::BackBuffer,IN.txcoord.xy);
}

// *** SSDO ***
	float4 PS_SSDOViewSpace(VS_OUTPUT_POST IN) : COLOR
	{
		return viewSpace(IN.txcoord.xy);
	}

	float4 PS_SSDOScatter(VS_OUTPUT_POST IN) : COLOR
	{
		return FX_SSDOScatter(IN.txcoord.xy);
	}
	
	float4 PS_SSDOBlurScale(VS_OUTPUT_POST IN) : COLOR
	{
		return tex2D(SamplerSSDOA,IN.txcoord.xy);
	}

	float4 PS_SSDOBlurH(VS_OUTPUT_POST IN) : COLOR
	{
		return FX_BlurBilatH(IN.txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale);
	}

	float4 PS_SSDOBlurV(VS_OUTPUT_POST IN) : COLOR
	{
		return float4(FX_BlurBilatV(IN.txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale).xyz,1.0);
	}
	
	float4 PS_SSDOMix(VS_OUTPUT_POST IN) : COLOR
	{
		float3 ssdo = pow(tex2D(SamplerSSDOB,IN.txcoord.xy).xyz,pSSDOIntensity.xxx);
		
		if (pSSDODebugMode == 1)
			return float4(pow(ssdo,2.2),1.0);
		else if (pSSDODebugMode == 2)
			return float4(pow(tex2D(SamplerSSDOA,IN.txcoord.xy).xyz,2.2),1.0);
		else
      return float4(ssdo * tex2D(SamplerColorLOD,IN.txcoord.xy).xyz,1.0);
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TECHNIQUES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique PPFXSSDO 
< 
	ui_label = "光影-屏空间定向遮挡"; 
	ui_tooltip = "屏空间定向遮挡 | 环境遮挡模拟几何的漫射阴影/自阴影。\n间接照明照亮暴露在特定“光源”下的物体，你可以在下面的参数中指定。\n这种方法考虑了方向信息，模拟了间接的光反射，近似全局光照。"; 
>
{
	pass setOriginal
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SetOriginal;
		RenderTarget0 = texColorLOD;
		
	}
	
	pass ssdoViewSpace
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOViewSpace;
		RenderTarget0 = texViewSpace;
	}
		
	pass ssdoScatter
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOScatter;
		RenderTarget0 = texSSDOA;
	}
		
	pass ssdoBlurScale
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurScale;
		RenderTarget0 = texSSDOB;
	}
		
	pass ssdoBlurH
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurH;
		RenderTarget0 = texSSDOC;
	}
		
	pass ssdoBlurV
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurV;
		RenderTarget0 = texSSDOB;
	}
		
	pass ssdoMix
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOMix;
		SRGBWriteEnable = true;
	}
}