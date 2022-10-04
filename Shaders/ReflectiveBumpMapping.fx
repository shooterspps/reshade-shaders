//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Reflective Bumpmapping "RBM" 3.0 beta by Marty McFly. 
// For ReShade 3.X only!
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform float fRBM_BlurWidthPixels <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 400.00;
	ui_step = 1;
	ui_label = "模糊像素宽度";
	ui_tooltip = "控制反射扩散的距离。如果你得到重复的工件，降低它或者提高样本数量。";
> = 100.0;

uniform int iRBM_SampleCount < __UNIFORM_SLIDER_INT1
	ui_min = 16; ui_max = 128;
	ui_label = "采样计数";
	ui_tooltip = "控制多少光泽反射样品被采取。如果您得到重复的工件，则提出此问题。性能下降。";
> = 32;

uniform float fRBM_ReliefHeight < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.00;
	ui_label = "表面起伏高度";
	ui_tooltip = "控制表面浮雕的强度。0.0表示镜像反射。";
> = 0.3;

uniform float fRBM_FresnelReflectance < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "菲涅尔反射";
	ui_tooltip = "这个值越低，视图到表面的角度就越低，以获得显著的反射。1.0意味着每个表面都有100%的光泽。";
> = 0.3;

uniform float fRBM_FresnelMult < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "菲涅尔衍射";
	ui_tooltip = "物理上一点都不精确:在最低视面角度反射强度的倍增器。";
> = 0.5;

uniform float  fRBM_LowerThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "下阈值";
	ui_tooltip = "任何比这更暗的东西都不会被反射。反射功率从下限到上限呈线性增加。";
> = 0.1;

uniform float  fRBM_UpperThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "上阈值";
	ui_tooltip = "任何比这个亮度更亮的东西都有助于反射。反射功率从下限到上限呈线性增加。 ";
> = 0.2;

uniform float  fRBM_ColorMask_Red < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "红色";
	ui_tooltip = "在红色表面反射多重。降低这个值以消除红色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Orange < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "橙色";
	ui_tooltip = "橙色表面反射多重。降低这个值以去除橙色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Yellow < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "黄色";
	ui_tooltip = "黄色表面反射多重。降低这个值以去除黄色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Green < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "绿色";
	ui_tooltip = "绿色表面反射多重。降低这个值以去除绿色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Cyan < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "青色";
	ui_tooltip = "在青色表面反射多重。降低这一点，以消除来自青色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Blue < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "蓝色";
	ui_tooltip = "蓝色表面反射多重。降低这个值以去除蓝色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Magenta < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.00;
	ui_label = "洋红";
	ui_tooltip = "洋红色表面上的反射多重。降低这个值以消除洋红色表面的反射。";
> = 1.0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float GetLinearDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords);
}

float3 GetPosition(float2 coords)
{
	float EyeDepth = GetLinearDepth(coords.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	return float3((coords.xy * 2.0 - 1.0)*EyeDepth,EyeDepth);
}

float3 GetNormalFromDepth(float2 coords) 
{
	float3 centerPos = GetPosition(coords.xy);
	float2 offs = BUFFER_PIXEL_SIZE*1.0;
	float3 ddx1 = GetPosition(coords.xy + float2(offs.x, 0)) - centerPos;
	float3 ddx2 = centerPos - GetPosition(coords.xy + float2(-offs.x, 0));

	float3 ddy1 = GetPosition(coords.xy + float2(0, offs.y)) - centerPos;
	float3 ddy2 = centerPos - GetPosition(coords.xy + float2(0, -offs.y));

	ddx1 = lerp(ddx1, ddx2, abs(ddx1.z) > abs(ddx2.z));
	ddy1 = lerp(ddy1, ddy2, abs(ddy1.z) > abs(ddy2.z));

	float3 normal = cross(ddy1, ddx1);
	
	return normalize(normal);
}

float3 GetNormalFromColor(float2 coords, float2 offset, float scale, float sharpness)
{
	const float3 lumCoeff = float3(0.299,0.587,0.114);

    	float hpx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	float hmx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	float hpy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;
    	float hmy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;

    	float dpx = GetLinearDepth(coords + float2(offset.x,0.0));
    	float dmx = GetLinearDepth(coords - float2(offset.x,0.0));
    	float dpy = GetLinearDepth(coords + float2(0.0,offset.y));
    	float dmy = GetLinearDepth(coords - float2(0.0,offset.y));

	float2 xymult = float2(abs(dmx - dpx), abs(dmy - dpy)) * sharpness; 
	xymult = max(0.0, 1.0 - xymult);
    	
    	float ddx = (hmx - hpx) / (2.0 * offset.x) * xymult.x;
    	float ddy = (hmy - hpy) / (2.0 * offset.y) * xymult.y;
    
    	return normalize(float3(ddx, ddy, 1.0));
}

float3 GetBlendedNormals(float3 n1, float3 n2)
{
	 return normalize(float3(n1.xy*n2.z + n2.xy*n1.z, n1.z*n2.z));
}

float3 RGB2HSV(float3 RGB)
{
    	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    	float4 p = RGB.g < RGB.b ? float4(RGB.bg, K.wz) : float4(RGB.gb, K.xy);
    	float4 q = RGB.r < p.x ? float4(p.xyw, RGB.r) : float4(RGB.r, p.yzx);

    	float d = q.x - min(q.w, q.y);
    	float e = 1.0e-10;
    	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSV2RGB(float3 HSV)
{
    	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    	float3 p = abs(frac(HSV.xxx + K.xyz) * 6.0 - K.www);
    	return HSV.z * lerp(K.xxx, saturate(p - K.xxx), HSV.y); //HDR capable
}

float GetHueMask(in float H)	
{
	float SMod = 0.0;
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SMod += fRBM_ColorMask_Orange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SMod += fRBM_ColorMask_Yellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SMod += fRBM_ColorMask_Green * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Cyan * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Blue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Magenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SMod;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_RBM_Gen(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float scenedepth 		= GetLinearDepth(texcoord.xy);
	float3 SurfaceNormals 		= GetNormalFromDepth(texcoord.xy).xyz;
	float3 TextureNormals 		= GetNormalFromColor(texcoord.xy, 0.01 * BUFFER_PIXEL_SIZE / scenedepth, 0.0002 / scenedepth + 0.1, 1000.0);
	float3 SceneNormals		= GetBlendedNormals(SurfaceNormals, TextureNormals);
	SceneNormals 			= normalize(lerp(SurfaceNormals,SceneNormals,fRBM_ReliefHeight));
	float3 ScreenSpacePosition 	= GetPosition(texcoord.xy);
	float3 ViewDirection 		= normalize(ScreenSpacePosition.xyz);

	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float3 bump = 0.0;

	for(float i=1; i<=iRBM_SampleCount; i++)
	{
		float2 currentOffset 	= texcoord.xy + SceneNormals.xy * BUFFER_PIXEL_SIZE * i/(float)iRBM_SampleCount * fRBM_BlurWidthPixels;
		float4 texelSample 	= tex2Dlod(ReShade::BackBuffer, float4(currentOffset,0,0));	
		
		float depthDiff 	= smoothstep(0.005,0.0,scenedepth-GetLinearDepth(currentOffset));
		float colorWeight 	= smoothstep(fRBM_LowerThreshold,fRBM_UpperThreshold+0.00001,dot(texelSample.xyz,float3(0.299,0.587,0.114)));
		bump += lerp(color.xyz,texelSample.xyz,depthDiff*colorWeight);
	}

	bump /= iRBM_SampleCount;

	float cosphi = dot(-ViewDirection, SceneNormals);
	//R0 + (1.0 - R0)*(1.0-cosphi)^5;
	float SchlickReflectance = lerp(pow(1.0-cosphi,5.0), 1.0, fRBM_FresnelReflectance);
	SchlickReflectance = saturate(SchlickReflectance)*fRBM_FresnelMult; // *should* be 0~1 but isn't for some pixels.

	float3 hsvcol = RGB2HSV(color.xyz);
	float colorMask = GetHueMask(hsvcol.x);
	colorMask = lerp(1.0,colorMask, smoothstep(0.0,0.2,hsvcol.y) * smoothstep(0.0,0.1,hsvcol.z));
	color.xyz = lerp(color.xyz,bump.xyz,SchlickReflectance*colorMask);

	res.xyz = color.xyz;
	res.w = 1.0;

}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique ReflectiveBumpmapping
<
	ui_label = "反光绘图";
>
{
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_RBM_Gen;
	}
}
