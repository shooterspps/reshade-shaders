
//High Pass Sharpening by Ioxa
//Version 1.5 for ReShade 3.0

//Settings

#include "ReShadeUI.fxh"

uniform int HighPassSharpRadius < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 3;
	ui_label = "锐化半径";
	ui_tooltip = "1 = 3x3 掩膜, 2 = 5x5 掩膜, 3 = 7x7 掩膜.";
> = 1;

uniform float HighPassSharpOffset < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "锐化偏移";
	ui_tooltip = "额外调整模糊半径。值小于1.00将减少半径，将锐化限制为更精细的细节";
> = 1.00;

uniform int HighPassBlendMode <
	ui_type = "combo";
	ui_items = "柔光\0覆盖\0充分\0强光\0艳光\0屏幕\0线性光\0加法";
	ui_label = "混合模式";
	ui_tooltip = "混合模式决定如何将锐化蒙版应用于原始图像";
> = 1;

uniform int HighPassBlendIfDark < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 255;
	ui_label = "暗混合系数";
	ui_tooltip = "Any pixels below this value will be excluded from the effect. Set to 50 to target mid-tones.";
> = 0;

uniform int HighPassBlendIfLight < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 255;
	ui_label = "光混合系数";
	ui_tooltip = "任何高于此值的像素将从效果中排除。设置为205以目标中间色调。";
> = 255;

uniform bool HighPassViewBlendIfMask <
	ui_label = "显示混合掩码";
	ui_tooltip = "显示混合掩码。该效果将不适用于黑色覆盖的区域";
> = false;

uniform float HighPassSharpStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "锐化强度";
	ui_tooltip = "调整效果的强度";
> = 0.400;

uniform float HighPassDarkIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 5.00;
	ui_label = "暗强";
	ui_tooltip = "调整黑光的强度。";
> = 1.0;

uniform float HighPassLightIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 5.00;
	ui_label = "光强";
	ui_tooltip = "调整光晕强度。";
> = 1.0;

uniform bool HighPassViewSharpMask <
	ui_label = "预览锐化遮罩";
	ui_tooltip = "显示锐化遮罩。在调整设置时很有用";
> = false;

#include "ReShade.fxh"

float3 SharpBlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 orig = color;
	float luma = dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
	float3 chroma = orig.rgb/luma;
	
	if (HighPassSharpRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
			color += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
		}
	}
	
	if (HighPassSharpRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
			color += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
		}
	}

	if (HighPassSharpRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
			color += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * BUFFER_RCP_WIDTH, sampleOffsetsY[i] * BUFFER_RCP_HEIGHT) * HighPassSharpOffset).rgb * sampleWeights[i];
		}
	}	
		
	float sharp = dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
	sharp = 1.0 - sharp;
	sharp = (luma+sharp)*0.5;

	float sharpMin = lerp(0,1,smoothstep(0,1,sharp));
	float sharpMax = sharpMin;
	sharpMin = lerp(sharp,sharpMin,HighPassDarkIntensity);
	sharpMax = lerp(sharp,sharpMax,HighPassLightIntensity);
	sharp = lerp(sharpMin,sharpMax,step(0.5,sharp));

	if(HighPassViewSharpMask)
	{
		//View sharp mask
		orig.rgb = sharp;
		luma = sharp;
		chroma = 1.0;
	}
	else 
	{	
		if(HighPassBlendMode == 0)
		{
			//softlight
			sharp = lerp(2*luma*sharp + luma*luma*(1.0-2*sharp), 2*luma*(1.0-sharp)+pow(luma,0.5)*(2*sharp-1.0), step(0.49,sharp));
		}
		
		if(HighPassBlendMode == 1)
		{
			//overlay
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,luma));
		}
		
		if(HighPassBlendMode == 2)
		{
			//Hardlight
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,sharp));
		}
		
		if(HighPassBlendMode == 3)
		{
			//Multiply
			sharp = saturate(2 * luma * sharp);
		}
		
		if(HighPassBlendMode == 4)
		{
			//vivid light
			sharp = lerp(2*luma*sharp, luma/(2*(1-sharp)), step(0.5,sharp));
		}
		
		if(HighPassBlendMode == 5)
		{
			//Linear Light
			sharp = luma + 2.0*sharp-1.0;
		}
		
		if(HighPassBlendMode == 6)
		{
			//Screen
			sharp = 1.0 - (2*(1.0-luma)*(1.0-sharp));
		}
		
		if(HighPassBlendMode == 7)
		{
			//Addition
			sharp = saturate(luma + (sharp - 0.5));
		}
	}
	
	if( HighPassBlendIfDark > 0 || HighPassBlendIfLight < 255 || HighPassViewBlendIfMask)
	{
		float BlendIfD = (HighPassBlendIfDark/255.0)+0.0001;
		float BlendIfL = (HighPassBlendIfLight/255.0)-0.0001;
		float mix = dot(orig.rgb, 0.333333);
		float mask = 1.0;
		
		if(HighPassBlendIfDark > 0)
		{
			mask = lerp(0.0,1.0,smoothstep(BlendIfD-(BlendIfD*0.2),BlendIfD+(BlendIfD*0.2),mix));
		}
		
		if(HighPassBlendIfLight < 255)
		{
			mask = lerp(mask,0.0,smoothstep(BlendIfL-(BlendIfL*0.2),BlendIfL+(BlendIfL*0.2),mix));
		}
		
		sharp = lerp(luma,sharp,mask);
		if (HighPassViewBlendIfMask)
		{
			sharp = mask;
			luma = mask;
			chroma = 1.0;
		}
	}
	
	luma = lerp(luma, sharp, HighPassSharpStrength);
	orig.rgb = luma*chroma;

	return saturate(orig);
}

technique HighPassSharp
<
	ui_label = "锐化-高通道锐化";
>
{
	pass Sharp
	{
		VertexShader = PostProcessVS;
		PixelShader = SharpBlurFinal;
	}
}
