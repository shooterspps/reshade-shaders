//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LICENSE AGREEMENT AND DISTRIBUTION RULES:
//1 Copyrights of the Master Effect exclusively belongs to author - Gilcher Pascal aka Marty McFly.
//2 Master Effect (the SOFTWARE) is DonateWare application, which means you may or may not pay for this software to the author as donation.
//3 If included in ENB presets, credit the author (Gilcher Pascal aka Marty McFly).
//4 Software provided "AS IS", without warranty of any kind, use it on your own risk. 
//5 You may use and distribute software in commercial or non-commercial uses. For commercial use it is required to warn about using this software (in credits, on the box or other places). Commercial distribution of software as part of the games without author permission prohibited.
//6 Author can change license agreement for new versions of the software.
//7 All the rights, not described in this license agreement belongs to author.
//8 Using the Master Effect means that user accept the terms of use, described by this license agreement.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// For more information about license agreement contact me:
// https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Advanced Depth of Field 4.2 by Marty McFly 
// Version for release
// Copyright © 2008-2015 Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Credits :: Matso (Matso DOF), PetkaGtA, gp65cj042
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform bool DOF_AUTOFOCUS <
	ui_label = "自动对焦";
	ui_tooltip = "使自动对焦识别基于样品周围的自动对焦中心。";
> = true;
uniform bool DOF_MOUSEDRIVEN_AF <
	ui_label = "鼠标驱动自动对焦";
	ui_tooltip = "启用鼠标驱动的自动对焦。如果从鼠标坐标中读取自动对焦焦点，则使用聚焦点。";
> = false;
uniform float2 DOF_FOCUSPOINT < __UNIFORM_SLIDER_FLOAT2
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "聚焦点";
	ui_tooltip = "自动对焦中心的X和Y坐标。坐标轴从屏幕左上角开始。";
> = float2(0.5, 0.5);
uniform int DOF_FOCUSSAMPLES < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 10;
	ui_label = "聚焦样品";
	ui_tooltip = "聚焦点周围的样本量，用于更平滑的焦平面检测。";
> = 6;
uniform float DOF_FOCUSRADIUS < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.02; ui_max = 0.20;
	ui_label = "聚焦半径";
	ui_tooltip = "样本围绕焦点的半径。";
> = 0.05;
uniform float DOF_NEARBLURCURVE <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 1000.0;
	ui_label = "近模糊曲线";
	ui_tooltip = "模糊曲线比焦平面更接近。越高，模糊越少。";
> = 1.60;
uniform float DOF_FARBLURCURVE <
	ui_type = "drag";
	ui_min = 0.05; ui_max = 5.0;
	ui_label = "远模糊曲线";
	ui_tooltip = "焦平面后的模糊曲线。越高，模糊越少。";
> = 2.00;
uniform float DOF_MANUALFOCUSDEPTH < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "手动对焦深度";
	ui_tooltip = "关闭自动对焦时焦平面的深度。0.0表示摄像头，1.0表示无限距离。";
> = 0.02;
uniform float DOF_INFINITEFOCUS <
	ui_type = "drag";
	ui_min = 0.01; ui_max = 1.0;
	ui_label = "无限焦点";
	ui_tooltip = "深度被认为是无限的距离。1.0标准。\n低值仅在对焦对象非常接近相机时产生失焦模糊。推荐游戏。";
> = 1.00;
uniform float DOF_BLURRADIUS <
	ui_type = "drag";
	ui_min = 2.0; ui_max = 100.0;
	ui_label = "模糊半径";
	ui_tooltip = "最大模糊半径(像素)。";
> = 15.0;

// Ring DOF Settings
uniform int iRingDOFSamples < __UNIFORM_SLIDER_INT1
	ui_min = 5; ui_max = 30;
	ui_label = "采样";
	ui_tooltip = "第一个环形的样品。周围的其他环有更多的样本。";
> = 6;
uniform int iRingDOFRings < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 8;
	ui_label = "环数";
	ui_tooltip = "环数";
> = 4;
uniform float fRingDOFThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 3.0;
	ui_label = "阈值";
	ui_tooltip = "散景增亮阈值。\n1.0是像GTASA这样的LDR游戏的最大值，更高的值只适用于像《天际》这样的HDR游戏。";
> = 0.7;
uniform float fRingDOFGain < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 30.0;
	ui_label = "增加";
	ui_tooltip = "比阈值更亮的像素的亮度。";
> = 27.0;
uniform float fRingDOFBias < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "乖离率";
	ui_tooltip = "外焦偏差";
> = 0.0;
uniform float fRingDOFFringe < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "边缘";
	ui_tooltip = "彩色像差的数量";
> = 0.5;

// Magic DOF Settings
uniform int iMagicDOFBlurQuality < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 30;
	ui_label = "模糊质量";
	ui_tooltip = "模糊质量作为控制值超过点击计数。质量15产生721个点击，到目前为止，其他景深着色器是不可能的，大多数他们可以做大约150个。";
> = 8;
uniform float fMagicDOFColorCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 10.0;
	ui_label = "颜色曲线";
	ui_tooltip = "景深权重曲线";
> = 4.0;

// GP65CJ042 DOF Settings
uniform int iGPDOFQuality < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 7;
	ui_label = "质量";
	ui_tooltip = "0 =只有轻微的高斯模糊，但没有散景。1-7散景模糊，越高意味着模糊质量越好，但帧数越低。";
> = 6;
uniform bool bGPDOFPolygonalBokeh <
	ui_label = "多边形散景";
	ui_tooltip = "启用多边形散景形状，例如POLYGON_NUM 5表示五边形散景形状。将此值设置为false会得到圆形散景图。";
> = true;
uniform int iGPDOFPolygonCount < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 9;
	ui_label = "多边形数";
	ui_tooltip = "控制多边形散边框形状的多边形数量。3 =三角形，4 =正方形，5 =五边形等等。";
> = 5;
uniform float fGPDOFBias < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 20.0;
	ui_label = "偏斜";
	ui_tooltip = "移散景加权到散景形状边缘。为明亮的焦色形状设置为0，为中心较暗的焦色形状和边缘较亮的焦色形状提高为0。";
> = 10.0;
uniform float fGPDOFBiasCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "偏斜曲线";
	ui_tooltip = "散景的强度。在散景形状的边缘升起以得到更多定义的散景轮廓。";
> = 2.0;
uniform float fGPDOFBrightnessThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "亮度阈值";
	ui_tooltip = "散景增亮阈值。高于这个值，一切都变得更加明亮。\n1.0是GTASA等LDR游戏的最大值，更高的值只适用于《天际》等HDR游戏。";
> = 0.5;
uniform float fGPDOFBrightnessMultiplier < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "亮度系数";
	ui_tooltip = "亮度高于亮度阈值的像素的亮度增加量。";
> = 2.0;
uniform float fGPDOFChromaAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.4;
	ui_label = "色差量";
	ui_tooltip = "在模糊区域上应用的颜色移动量。 ";
> = 0.15;

// MATSO DOF Settings
uniform bool bMatsoDOFChromaEnable <
	ui_label = "启用色差";
	ui_tooltip = "允许色差。";
> = true;
uniform float fMatsoDOFChromaPow < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.2; ui_max = 3.0;
	ui_label = "偏移";
	ui_tooltip = "色差色移量。";
> = 1.4;
uniform float fMatsoDOFBokehCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 20.0;
	ui_label = "焦外成像曲线";
	ui_tooltip = "焦外成像曲线";
> = 8.0;
uniform int iMatsoDOFBokehQuality < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 10;
	ui_label = "焦外成像质量";
	ui_tooltip = "模糊质量作为控制值超过点击计数。";
> = 2;
uniform float fMatsoDOFBokehAngle < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 360; ui_step = 1;
	ui_label = "焦外成像角度";
	ui_tooltip = "焦外成像形状的旋转角度。";
> = 0;

// MCFLY ADVANCED DOF Settings - SHAPE
#ifndef bADOF_ShapeTextureEnable
	#define bADOF_ShapeTextureEnable 0 // Enables the use of a texture overlay. Quite some performance drop.
	#define iADOF_ShapeTextureSize 63 // Higher texture size means less performance. Higher quality integers better work with detailed shape textures. Uneven numbers recommended because even size textures have no center pixel.
#endif

#ifndef iADOF_ShapeVertices
	#define iADOF_ShapeVertices 5 // Polygon count of bokeh shape. 4 = square, 5 = pentagon, 6 = hexagon and so on.
#endif

uniform int iADOF_ShapeQuality < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 255;
	ui_label = "形状质量";
	ui_tooltip = "自由度形状的质量水平。更高意味着更多的偏移，更清晰的形状，但也更低的性能。编译时间保持不变。";
> = 17;
uniform float fADOF_ShapeRotation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 360; ui_step = 1;
	ui_label = "形状旋转";
	ui_tooltip = "静态旋转散景形状。";
> = 15;
uniform bool bADOF_RotAnimationEnable <
	ui_label = "启用动画";
	ui_tooltip = "能够在时间内恒定的形状旋转。";
> = false;
uniform float fADOF_RotAnimationSpeed < __UNIFORM_SLIDER_FLOAT1
	ui_min = -5; ui_max = 5;
	ui_label = "动画速度";
	ui_tooltip = "形状旋转的速度。负数改变方向。";
> = 2.0;
uniform bool bADOF_ShapeCurvatureEnable <
	ui_label = "启用形状弯曲";
	ui_tooltip = "将多边形形状的边缘向外(或向内)弯曲。圆形最好用顶点> 7";
> = false;
uniform float fADOF_ShapeCurvatureAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "形状弯曲量";
	ui_tooltip = "折边量。1.0的结果是圆形。小于0的值产生星形形状。";
> = 0.3;
uniform bool bADOF_ShapeApertureEnable <
	ui_label = "启用孔径形状";
	ui_tooltip = "使散景形状变形成漩涡状光圈。当你尝试它的时候，你会认出它。最好是大的散景形状。";
> = false;
uniform float fADOF_ShapeApertureAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = -0.05; ui_max = 0.05;
	ui_label = "孔径形状数量";
	ui_tooltip = "变形量。负值反映了这种效果。 ";
> = 0.01;
uniform bool bADOF_ShapeAnamorphEnable <
	ui_label = "启用变形形状";
	ui_tooltip = "减少形状的水平宽度，以模拟电影中看到的变形散景形状。";
> = false;
uniform float fADOF_ShapeAnamorphRatio < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "变形形状比例";
	ui_tooltip = "水平宽度的因素。1.0表示100%宽度，0.0表示0%宽度(散景形状将是垂直线)。";
> = 0.2;
uniform bool bADOF_ShapeDistortEnable <
	ui_label = "启用扭曲形状";
	ui_tooltip = "在屏幕边缘变形焦景形状以模拟镜头变形。屏幕上的散景形状看起来像一个鸡蛋。";
> = false;
uniform float fADOF_ShapeDistortAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "扭曲形状量";
	ui_tooltip = "变形量";
> = 0.2;
uniform bool bADOF_ShapeDiffusionEnable <
	ui_label = "启用扩散形状";
	ui_tooltip = "使散景的形状有些模糊，使它不太清楚定义。";
> = false;
uniform float fADOF_ShapeDiffusionAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "扩散形状量";
	ui_tooltip = "形状扩散量。高值看起来像散景形状爆炸。";
> = 0.1;
uniform bool bADOF_ShapeWeightEnable <
	ui_label = "启用重量形状";
	ui_tooltip = "允许散景形状权重偏移，并将颜色转移到形状边界。";
> = false;
uniform float fADOF_ShapeWeightCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 8.0;
	ui_label = "重量形状曲线";
	ui_tooltip = "形状重量偏差曲线。";
> = 4.0;
uniform float fADOF_ShapeWeightAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 8.0;
	ui_label = "重量形状量";
	ui_tooltip = "形状重量偏差量。";
> = 1.0;
uniform float fADOF_BokehCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 20.0;
	ui_label = "散景曲线";
	ui_tooltip = "散景的因素。较高的数值会为分离的亮点产生更明确的散景形状。";
> = 4.0;

// MCFLY ADVANCED DOF Settings - CHROMATIC ABERRATION
uniform bool bADOF_ShapeChromaEnable <
	ui_label = "启用形状浓度";
	ui_tooltip = "使散景形状边界的色差。这意味着3倍以上的样本=更低的性能。";
> = false;
uniform int iADOF_ShapeChromaMode <
	ui_type = "combo";
	ui_items = "模式 1\0模式 2\0模式 3\0模式 4\0模式 5\0模式 6\0";
	ui_label = "形状浓度模式";
	ui_tooltip = "通过可能的rg转换开关。";
> = 3;
uniform float fADOF_ShapeChromaAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "形状浓度量";
	ui_tooltip = "颜色移动量。";
> = 0.125;
uniform bool bADOF_ImageChromaEnable <
	ui_label = "启用图像色度";
	ui_tooltip = "使图像色差在屏幕角。\n这个比形状色度(和网络上的任何其他色度)要复杂得多。";
> = false;
uniform int iADOF_ImageChromaHues < __UNIFORM_SLIDER_INT1
	ui_min = 2; ui_max = 20;
	ui_label = "图像色度色调";
	ui_tooltip = "样品量通过光谱得到平滑的梯度。";
> = 5;
uniform float fADOF_ImageChromaCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "图像色度曲线";
	ui_tooltip = "图像色差曲线。更高意味着屏幕中心区域的色度更低。";
> = 1.0;
uniform float fADOF_ImageChromaAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 10.0;
	ui_label = "图像色度量";
	ui_tooltip = "线性增加图像色差量。";
> = 3.0;

// MCFLY ADVANCED DOF Settings - POSTFX
uniform float fADOF_SmootheningAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "平滑量";
	ui_tooltip = "散景后的盒模糊的模糊乘法器来平滑形状。盒模糊比高斯模糊更好。";
> = 1.0;

#ifndef bADOF_ImageGrainEnable
	#define bADOF_ImageGrainEnable 0 // Enables some fuzzyness in blurred areas. The more out of focus, the more grain
#endif

#if bADOF_ImageGrainEnable
uniform float fADOF_ImageGrainCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 5.0;
	ui_label = "图像颗粒曲线";
	ui_tooltip = "图像粒度分布曲线。在中度模糊区域，高数值会减少颗粒。";
> = 1.0;
uniform float fADOF_ImageGrainAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 2.0;
	ui_label = "图像颗粒量";
	ui_tooltip = "线性乘以应用的图像纹理的数量。";
> = 0.55;
uniform float fADOF_ImageGrainScale < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "图像颗粒规模";
	ui_tooltip = "颗粒纹理规模. 低值产生更粗的噪声。";
> = 1.0;
#endif

/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if bADOF_ImageGrainEnable
texture texNoise < source = "mcnoise.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerNoise { Texture = texNoise; };
#endif
#if bADOF_ShapeTextureEnable
texture texMask < source = "mcmask.png"; > { Width = iADOF_ShapeTextureSize; Height = iADOF_ShapeTextureSize; Format = R8; };
sampler SamplerMask { Texture = texMask; };
#endif

#define DOF_RENDERRESMULT 0.6

texture texHDR1 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; };
texture texHDR2 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; }; 
sampler SamplerHDR1 { Texture = texHDR1; };
sampler SamplerHDR2 { Texture = texHDR2; };

/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform float2 MouseCoords < source = "mousepoint"; >;

float GetCoC(float2 coords)
{
	float scenedepth = ReShade::GetLinearizedDepth(coords);
	float scenefocus, scenecoc = 0.0;

	if (DOF_AUTOFOCUS)
	{
		scenefocus = 0.0;

		float2 focusPoint = DOF_MOUSEDRIVEN_AF ? MouseCoords * BUFFER_PIXEL_SIZE : DOF_FOCUSPOINT;

		[loop]
		for (int r = DOF_FOCUSSAMPLES; 0 < r; r--)
		{
			sincos((6.2831853 / DOF_FOCUSSAMPLES) * r, coords.y, coords.x);
			coords.y *= BUFFER_ASPECT_RATIO;
			scenefocus += ReShade::GetLinearizedDepth(coords * DOF_FOCUSRADIUS + focusPoint);
		}
		scenefocus /= DOF_FOCUSSAMPLES;
	}
	else
	{
		scenefocus = DOF_MANUALFOCUSDEPTH;
	}

	scenefocus = smoothstep(0.0, DOF_INFINITEFOCUS, scenefocus);
	scenedepth = smoothstep(0.0, DOF_INFINITEFOCUS, scenedepth);

	float farBlurDepth = scenefocus * pow(4.0, DOF_FARBLURCURVE);

	if (scenedepth < scenefocus)
	{
		scenecoc = (scenedepth - scenefocus) / scenefocus;
	}
	else
	{
		scenecoc = (scenedepth - scenefocus) / (farBlurDepth - scenefocus);
		scenecoc = saturate(scenecoc);
	}

	return saturate(scenecoc * 0.5 + 0.5);
}

/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void PS_Focus(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	float4 scenecolor = tex2D(ReShade::BackBuffer, texcoord);
	scenecolor.w = GetCoC(texcoord);
	hdr1R = scenecolor;
}

// RING DOF
void PS_RingDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 scenecolor = tex2D(SamplerHDR1, texcoord);

	float centerDepth = scenecolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	float2 blurRadius = discRadius * BUFFER_PIXEL_SIZE / iRingDOFRings;
	scenecolor.x = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.000,  1.0) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).x;
	scenecolor.y = tex2Dlod(SamplerHDR1, float4(texcoord + float2(-0.866, -0.5) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).y;
	scenecolor.z = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.866, -0.5) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).z;

	scenecolor.w = centerDepth;
	hdr2R = scenecolor;
}
void PS_RingDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = tex2D(SamplerHDR2, texcoord);
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);

	float centerDepth = GetCoC(texcoord);

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor.xyz, centerDepth);
		return;
	}

	blurcolor.w = 1.0;

	float s = 1.0;
	int ringsamples;

	[loop]
	for (int g = 1; g <= iRingDOFRings; g += 1)
	{
		ringsamples = g * iRingDOFSamples;

		[loop]
		for (int j = 0; j < ringsamples; j += 1)
		{
			float step = 6.283 / ringsamples;
			float2 sampleoffset = 0.0;
			sincos(j * step, sampleoffset.y, sampleoffset.x);
			float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleoffset * BUFFER_PIXEL_SIZE * discRadius * g / iRingDOFRings, 0, 0));

			float tapluma = dot(tap.xyz, 0.333);
			float tapthresh = max((tapluma - fRingDOFThreshold) * fRingDOFGain, 0.0);
			tap.xyz *= 1.0 + tapthresh * blurAmount;

			tap.w = (tap.w >= centerDepth * 0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);
			tap.w *= lerp(1.0, g / iRingDOFRings, fRingDOFBias);
			blurcolor.xyz += tap.xyz * tap.w;
			blurcolor.w += tap.w;
		}
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius)); // smooth transition between full res color and lower res blur
	blurcolor.w = centerDepth;
}

// MAGIC DOF
void PS_MagicDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (discRadius < 1.2)
	{
		hdr2R = float4(blurcolor.xyz, centerDepth);
	}
	else
	{
		blurcolor = 0.0;

		[loop]
		for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i)
		{
			float2 tapoffset = float2(1, 0) * i;
			float4 tap = tex2Dlod(SamplerHDR1, float4(texcoord + tapoffset * discRadius * BUFFER_RCP_WIDTH / iMagicDOFBlurQuality, 0, 0));
			tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);
			blurcolor.xyz += tap.xyz*tap.w;
			blurcolor.w += tap.w;
		}

		blurcolor.xyz /= blurcolor.w;
		blurcolor.w = centerDepth;
		hdr2R = blurcolor;
	}
}
void PS_MagicDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = 0.0;
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);

	float centerDepth = GetCoC(texcoord); //use fullres CoC data
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor.xyz, centerDepth);
		return;
	}

	[loop]
	for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i)
	{
		float2 tapoffset1 = float2(0.5, 0.866) * i;
		float2 tapoffset2 = float2(-tapoffset1.x, tapoffset1.y);

		float4 tap1 = tex2Dlod(SamplerHDR2, float4(texcoord + tapoffset1 * discRadius * BUFFER_PIXEL_SIZE / iMagicDOFBlurQuality, 0, 0));
		float4 tap2 = tex2Dlod(SamplerHDR2, float4(texcoord + tapoffset2 * discRadius * BUFFER_PIXEL_SIZE / iMagicDOFBlurQuality, 0, 0));

		blurcolor.xyz += pow(abs(min(tap1.xyz, tap2.xyz)), fMagicDOFColorCurve);
		blurcolor.w += 1.0;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = pow(saturate(blurcolor.xyz), 1.0 / fMagicDOFColorCurve);
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius));
}

// GP65CJ042 DOF
void PS_GPDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = max(0.0, blurAmount - 0.1) * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	float3 distortion = float3(-1.0, 0.0, 1.0);
	distortion *= fGPDOFChromaAmount;

	float4 chroma1 = tex2D(SamplerHDR1, texcoord + discRadius * BUFFER_PIXEL_SIZE * distortion.x);
	chroma1.w = smoothstep(0.0, centerDepth, chroma1.w);
	blurcolor.x = lerp(blurcolor.x, chroma1.x, chroma1.w);

	float4 chroma2 = tex2D(SamplerHDR1, texcoord + discRadius * BUFFER_PIXEL_SIZE * distortion.z);
	chroma2.w = smoothstep(0.0, centerDepth, chroma2.w);
	blurcolor.z = lerp(blurcolor.z, chroma2.z, chroma2.w);

	blurcolor.w = centerDepth;
	hdr2R = blurcolor;
}
void PS_GPDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = tex2D(SamplerHDR2, texcoord);
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);

	float centerDepth = GetCoC(texcoord);

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor.xyz, centerDepth);
		return;
	}

	blurcolor.w = dot(blurcolor.xyz, 0.3333);
	blurcolor.w = max((blurcolor.w - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
	blurcolor.xyz *= (1.0 + blurcolor.w * blurAmount);
	blurcolor.xyz *= lerp(1.0, 0.0, saturate(fGPDOFBias));
	blurcolor.w = 1.0;

	int sampleCycle = 0;
	int sampleCycleCounter = 0;
	int sampleCounterInCycle = 0;
	float basedAngle = 360.0 / iGPDOFPolygonCount;
	float2 currentVertex, nextVertex;

	int	dofTaps = bGPDOFPolygonalBokeh ? (iGPDOFQuality * (iGPDOFQuality + 1) * iGPDOFPolygonCount / 2.0) : (iGPDOFQuality * (iGPDOFQuality + 1) * 4);

	for (int i = 0; i < dofTaps; i++)
	{
		//dumb step incoming
		bool dothatstep = sampleCounterInCycle == 0;
		if (sampleCycle != 0)
		{
			if (sampleCounterInCycle % sampleCycle == 0)
				dothatstep = true;
		}
		//until here
		//ask yourself why so complicated? if(sampleCounterInCycle % sampleCycle == 0 ) gives warnings when sampleCycle=0
		//but it can only be 0 when sampleCounterInCycle is also 0 so it essentially is no division through 0 even if
		//the compiler believes it, it's 0/0 actually but without disabling shader optimizations this is the only way to workaround that.

		if (dothatstep)
		{
			sampleCounterInCycle = 0;
			sampleCycleCounter++;

			if (bGPDOFPolygonalBokeh)
			{
				sampleCycle += iGPDOFPolygonCount;
				currentVertex.xy = float2(1.0, 0.0);
				sincos(basedAngle* 0.017453292, nextVertex.y, nextVertex.x);
			}
			else
			{
				sampleCycle += 8;
			}
		}

		sampleCounterInCycle++;

		float2 sampleOffset;

		if (bGPDOFPolygonalBokeh)
		{
			float sampleAngle = basedAngle / float(sampleCycleCounter) * sampleCounterInCycle;
			float remainAngle = frac(sampleAngle / basedAngle) * basedAngle;

			if (remainAngle < 0.000001)
			{
				currentVertex = nextVertex;
				sincos((sampleAngle + basedAngle) * 0.017453292, nextVertex.y, nextVertex.x);
			}

			sampleOffset = lerp(currentVertex.xy, nextVertex.xy, remainAngle / basedAngle);
		}
		else
		{
			float sampleAngle = 0.78539816 / float(sampleCycleCounter) * sampleCounterInCycle;
			sincos(sampleAngle, sampleOffset.y, sampleOffset.x);
		}

		sampleOffset *= sampleCycleCounter;

		float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleOffset * discRadius * BUFFER_PIXEL_SIZE / iGPDOFQuality, 0, 0));

		float brightMultipiler = max((dot(tap.xyz, 0.333) - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
		tap.xyz *= 1.0 + brightMultipiler * abs(tap.w * 2.0 - 1.0);

		tap.w = (tap.w >= centerDepth * 0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);
		float BiasCurve = 1.0 + fGPDOFBias * pow(abs((float)sampleCycleCounter / iGPDOFQuality), fGPDOFBiasCurve);

		blurcolor.xyz += tap.xyz * tap.w * BiasCurve;
		blurcolor.w += tap.w * BiasCurve;

	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius));
}

// MATSO DOF
float4 GetMatsoDOFCA(sampler col, float2 tex, float CoC)
{
	float3 chroma = pow(float3(0.5, 1.0, 1.5), fMatsoDOFChromaPow * CoC);

	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(tex2Dlod(col, float4(tr,0,0)).r, tex2Dlod(col, float4(tg,0,0)).g, tex2Dlod(col, float4(tb,0,0)).b) * (1.0 - CoC);
	
	return float4(color, 1.0);
}
float4 GetMatsoDOFBlur(int axis, float2 coord, sampler SamplerHDRX)
{
	float4 blurcolor = tex2D(SamplerHDRX, coord.xy);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	blurcolor = 0.0;

	const float2 tdirs[4] = { 
		float2(-0.306,  0.739),
		float2( 0.306,  0.739),
		float2(-0.739,  0.306),
		float2(-0.739, -0.306)
	};

	for (int i = -iMatsoDOFBokehQuality; i < iMatsoDOFBokehQuality; i++)
	{
		float2 taxis =  tdirs[axis];

		taxis.x = cos(fMatsoDOFBokehAngle * 0.0175) * taxis.x - sin(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		taxis.y = sin(fMatsoDOFBokehAngle * 0.0175) * taxis.x + cos(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		
		float2 tcoord = coord.xy + (float)i * taxis * discRadius * BUFFER_PIXEL_SIZE * 0.5 / iMatsoDOFBokehQuality;

		float4 ct = bMatsoDOFChromaEnable ? GetMatsoDOFCA(SamplerHDRX, tcoord.xy, discRadius * BUFFER_RCP_WIDTH * 0.5 / iMatsoDOFBokehQuality) : tex2Dlod(SamplerHDRX, float4(tcoord.xy, 0, 0));

		// my own pseudo-bokeh weighting
		float b = dot(ct.rgb, 0.333) + length(ct.rgb) + 0.1;
		float w = pow(abs(b), fMatsoDOFBokehCurve) + abs((float)i);

		blurcolor.xyz += ct.xyz * w;
		blurcolor.w += w;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.w = centerDepth;
	return blurcolor;
}

void PS_MatsoDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(2, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	hdr1R = GetMatsoDOFBlur(3, texcoord, SamplerHDR2);	
}
void PS_MatsoDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(0, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);
	blurcolor = GetMatsoDOFBlur(1, texcoord, SamplerHDR2);
	float centerDepth = GetCoC(texcoord); //fullres coc data

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 

	//not 1.2 - 2.0 because matso's has a weird bokeh weighting that is almost like a tonemapping and border between blur and no blur appears to harsh
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(0.2,2.0,discRadius)); 
}

// MARTY MCFLY DOF
float2 GetDistortedOffsets(float2 intexcoord, float2 sampleoffset)
{
	float2 tocenter = intexcoord - float2(0.5, 0.5);
	float3 perp = normalize(float3(tocenter.y, -tocenter.x, 0.0));

	float rotangle = length(tocenter) * 2.221 * fADOF_ShapeDistortAmount;  
	float3 oldoffset = float3(sampleoffset, 0);

	float3 rotatedoffset =  oldoffset * cos(rotangle) + cross(perp, oldoffset) * sin(rotangle) + perp * dot(perp, oldoffset) * (1.0 - cos(rotangle));

	return rotatedoffset.xy;
}

float4 tex2Dchroma(sampler2D tex, float2 sourcecoord, float2 offsetcoord)
{
	float4 res = 0.0;

	float4 sample1 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 - fADOF_ShapeChromaAmount), 0, 0));
	float4 sample2 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy, 0, 0));
	float4 sample3 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 + fADOF_ShapeChromaAmount), 0, 0));

	if (iADOF_ShapeChromaMode == 0)		
		res.xyz = float3(sample1.x, sample2.y, sample3.z);
	else if (iADOF_ShapeChromaMode == 1)	
		res.xyz = float3(sample2.x, sample3.y, sample1.z);
	else if (iADOF_ShapeChromaMode == 2)
		res.xyz = float3(sample3.x, sample1.y, sample2.z);
	else if (iADOF_ShapeChromaMode == 3)
		res.xyz = float3(sample1.x, sample3.y, sample2.z);
	else if (iADOF_ShapeChromaMode == 4)
		res.xyz = float3(sample2.x, sample1.y, sample3.z);
	else if (iADOF_ShapeChromaMode == 5)
		res.xyz = float3(sample3.x, sample2.y, sample1.z);

	res.w = sample2.w;
	return res;
}

#if bADOF_ShapeTextureEnable
	#undef iADOF_ShapeVertices
	#define iADOF_ShapeVertices 4
#endif

uniform float Timer < source = "timer"; >;

float3 BokehBlur(sampler2D tex, float2 coord, float CoC, float centerDepth)
{
	float4 res = float4(tex2Dlod(tex, float4(coord.xy, 0.0, 0.0)).xyz, 1.0);
	int ringCount = round(lerp(1.0, (float)iADOF_ShapeQuality, CoC / DOF_BLURRADIUS));
	float rotAngle = fADOF_ShapeRotation;
	float2 discRadius = CoC * BUFFER_PIXEL_SIZE;
	float2 edgeVertices[iADOF_ShapeVertices + 1];

	if (bADOF_ShapeWeightEnable)
		res.w = (1.0 - fADOF_ShapeWeightAmount);

	res.xyz = pow(abs(res.xyz), fADOF_BokehCurve)*res.w;

	if (bADOF_ShapeAnamorphEnable)
		discRadius.x *= fADOF_ShapeAnamorphRatio;

	if (bADOF_RotAnimationEnable)
		rotAngle += fADOF_RotAnimationSpeed * Timer * 0.005;

	float2 Grain;
	if (bADOF_ShapeDiffusionEnable)
	{
		Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0), frac(cos(coord.x - coord.y * 573.31) * 289013.0));
		Grain = (Grain - 0.5) * fADOF_ShapeDiffusionAmount + 1.0;
	}

	[unroll]
	for (int z = 0; z <= iADOF_ShapeVertices; z++)
	{
		sincos((6.2831853 / iADOF_ShapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
	}

	[fastopt]
	for (float i = 1; i <= ringCount; i++)
	{
		[fastopt]
		for (int j = 1; j <= iADOF_ShapeVertices; j++)
		{
			float radiusCoeff = i / ringCount;
			float blursamples = i;

#if bADOF_ShapeTextureEnable
			blursamples *= 2;
#endif

			[fastopt]
			for (float k = 0; k < blursamples; k++)
			{
				if (bADOF_ShapeApertureEnable)
					radiusCoeff *= 1.0 + sin(k / blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.

				float2 sampleOffset = lerp(edgeVertices[j - 1], edgeVertices[j], k / blursamples) * radiusCoeff;

				if (bADOF_ShapeCurvatureEnable)
					sampleOffset = lerp(sampleOffset, normalize(sampleOffset) * radiusCoeff, fADOF_ShapeCurvatureAmount);

				if (bADOF_ShapeDistortEnable)
					sampleOffset = GetDistortedOffsets(coord, sampleOffset);

				if (bADOF_ShapeDiffusionEnable)
					sampleOffset *= Grain;

				float4 tap = bADOF_ShapeChromaEnable ? tex2Dchroma(tex, coord, sampleOffset * discRadius) : tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));
				tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);

				if (bADOF_ShapeWeightEnable)
					tap.w *= lerp(1.0, pow(length(sampleOffset), fADOF_ShapeWeightCurve), fADOF_ShapeWeightAmount);

#if bADOF_ShapeTextureEnable
				tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset + 0.707) * 0.707, 0, 0)).x;
#endif

				res.xyz += pow(abs(tap.xyz), fADOF_BokehCurve) * tap.w;
				res.w += tap.w;
			}
		}
	}

	res.xyz = max(res.xyz / res.w, 0.0);
	return pow(res.xyz, 1.0 / fADOF_BokehCurve);
}

void PS_McFlyDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	texcoord /= DOF_RENDERRESMULT;

	float4 blurcolor = tex2D(SamplerHDR1, saturate(texcoord));

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (max(texcoord.x, texcoord.y) <= 1.05 && discRadius >= 1.2)
	{
		//doesn't bring that much with intelligent tap calculation
		blurcolor.xyz = (discRadius >= 1.2) ? BokehBlur(SamplerHDR1, texcoord, discRadius, centerDepth) : blurcolor.xyz;
		blurcolor.w = centerDepth;
	}

	hdr2R = blurcolor;
}
void PS_McFlyDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 scenecolor : SV_Target)
{   
	scenecolor = 0.0;
	float4 blurcolor = tex2D(SamplerHDR2, texcoord*DOF_RENDERRESMULT);
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);
	
	float centerDepth = GetCoC(texcoord); 
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

#if __RENDERER__ < 0xa000 && !__RESHADE_PERFORMANCE_MODE__
	[flatten]
#endif
	if (bADOF_ImageChromaEnable)
	{
		float2 coord = texcoord * 2.0 - 1.0;
		float centerfact = length(coord);
		centerfact = pow(centerfact, fADOF_ImageChromaCurve) * fADOF_ImageChromaAmount;

		float chromafact = BUFFER_RCP_WIDTH * centerfact * discRadius;
		float3 chromadivisor = 0.0;

		for (float c = 0; c < iADOF_ImageChromaHues; c++)
		{
			float temphue = c / iADOF_ImageChromaHues;
			float3 tempchroma = saturate(float3(abs(temphue * 6.0 - 3.0) - 1.0, 2.0 - abs(temphue * 6.0 - 2.0), 2.0 - abs(temphue * 6.0 - 4.0)));
			float  tempoffset = (c + 0.5) / iADOF_ImageChromaHues - 0.5;
			float3 tempsample = tex2Dlod(SamplerHDR2, float4((coord.xy * (1.0 + chromafact * tempoffset) * 0.5 + 0.5) * DOF_RENDERRESMULT, 0, 0)).xyz;
			scenecolor.xyz += tempsample.xyz*tempchroma.xyz;
			chromadivisor += tempchroma;
		}

		scenecolor.xyz /= dot(chromadivisor.xyz, 0.333);
	}
	else
	{
		scenecolor = blurcolor;
	}

	scenecolor.xyz = lerp(scenecolor.xyz, noblurcolor.xyz, smoothstep(2.0,1.2,discRadius));

	scenecolor.w = centerDepth;
}
void PS_McFlyDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 scenecolor : SV_Target)
{
	scenecolor = tex2D(ReShade::BackBuffer, texcoord);
	float4 blurcolor = 0.0001;
	float outOfFocus = abs(scenecolor.w * 2.0 - 1.0);

	//move all math out of loop if possible
	float2 blurmult = smoothstep(0.3, 0.8, outOfFocus) * BUFFER_PIXEL_SIZE * fADOF_SmootheningAmount;

	float weights[3] = { 1.0,0.75,0.5 };
	//Why not separable? For the glory of Satan, of course!
	for (int x = -2; x <= 2; x++)
	{
		for (int y = -2; y <= 2; y++)
		{
			float2 offset = float2(x, y);
			float offsetweight = weights[abs(x)] * weights[abs(y)];
			blurcolor.xyz += tex2Dlod(ReShade::BackBuffer, float4(texcoord + offset.xy * blurmult, 0, 0)).xyz * offsetweight;
			blurcolor.w += offsetweight;
		}
	}

	scenecolor.xyz = blurcolor.xyz / blurcolor.w;

#if bADOF_ImageGrainEnable
	float ImageGrain = frac(sin(texcoord.x + texcoord.y * 543.31) *  893013.0 + Timer * 0.001);

	float3 AnimGrain = 0.5;
	float2 GrainPixelSize = BUFFER_PIXEL_SIZE / fADOF_ImageGrainScale;
	//My emboss noise
	AnimGrain += lerp(tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + float2(GrainPixelSize.x, 0)).xyz, tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(GrainPixelSize.x, 0)).xyz, ImageGrain) * 0.1;
	AnimGrain -= lerp(tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + float2(0, GrainPixelSize.y)).xyz, tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(0, GrainPixelSize.y)).xyz, ImageGrain) * 0.1;
	AnimGrain = dot(AnimGrain.xyz, 0.333);

	//Photoshop overlay mix mode
	float3 graincolor = (scenecolor.xyz < 0.5 ? (2.0 * scenecolor.xyz * AnimGrain.xxx) : (1.0 - 2.0 * (1.0 - scenecolor.xyz) * (1.0 - AnimGrain.xxx)));
	scenecolor.xyz = lerp(scenecolor.xyz, graincolor.xyz, pow(outOfFocus, fADOF_ImageGrainCurve) * fADOF_ImageGrainAmount);
#endif

	//focus preview disabled!
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique RingDOF
< 
	ui_label = "景深-环形";
>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass RingDOF1 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF1; RenderTarget = texHDR2; }
	pass RingDOF2 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF2; /* renders to backbuffer*/ }
}

technique MagicDOF
< 
	ui_label = "景深-魔法";
>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass MagicDOF1 { VertexShader = PostProcessVS; PixelShader = PS_MagicDOF1; RenderTarget = texHDR2; }
	pass MagicDOF2 { VertexShader = PostProcessVS; PixelShader = PS_MagicDOF2; /* renders to backbuffer*/ }
}

technique GP65CJ042DOF
< 
	ui_label = "景深-变形镜头光晕";
>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass GPDOF1 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF1; RenderTarget = texHDR2; }
	pass GPDOF2 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF2; /* renders to backbuffer*/ }
}

technique MatsoDOF
< 
	ui_label = "景深-马索";
>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass MatsoDOF1 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF1; RenderTarget = texHDR2; }
	pass MatsoDOF2 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF2; RenderTarget = texHDR1; }
	pass MatsoDOF3 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF3; RenderTarget = texHDR2; }
	pass MatsoDOF4 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF4; /* renders to backbuffer*/ }
}

technique MartyMcFlyDOF
< 
	ui_label = "景深-马蒂·麦克弗莱";
>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass McFlyDOF1 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF1; RenderTarget = texHDR2; }
	pass McFlyDOF2 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF2; /* renders to backbuffer*/ }
	pass McFlyDOF3 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF3; /* renders to backbuffer*/ }
}
