//////////////////////////////////////////////////////////////////////////////
// ©2005 Electronic Arts Inc
//
// FX Shader for simple unlit rendering
//////////////////////////////////////////////////////////////////////////////
#include "Common.fxh"

// ----------------------------------------------------------------------------
// MATERIAL PARAMATERS
// ----------------------------------------------------------------------------
SAMPLER_2D_BEGIN( RiverTexture,
	string UIName = "River Texture";
	)
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
SAMPLER_2D_END

SAMPLER_2D_BEGIN( NormalTexture,
	string UIName = "Normal Texture";
	)
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
SAMPLER_2D_END

float4 Opacity
<
	string UIName = "Opacity";
> = float4(1, 1, 1, 1);

float2 UVScrollPerSecond
<
	string UIName = "UVScrollPerSecond";
> = float2(1, 1);

// Firestorm river-water tuning.
// Keep these inexpensive: RiverWater uses ps_2_0 for its main runtime paths.
float RiverReflectionStrength
<
	string UIName = "River Reflection Strength";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
> = 0.30f;

float RiverReflectionPerturbation
<
	string UIName = "River Reflection Perturbation";
	float UIMin = 0.0f;
	float UIMax = 0.5f;
> = 0.12f;

float RiverSunSpecularStrength
<
	string UIName = "River Sun Specular Strength";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
> = 0.10f;

float RiverSunSpecularExponent
<
	string UIName = "River Sun Specular Exponent";
	float UIMin = 1.0f;
	float UIMax = 256.0f;
> = 64.0f;

bool IsAdditiveBlended
<
	string UIName = "Additive";
> = false;

// ----------------------------------------------------------------------------
// Directional light (used for subtle sun sheen)
// ----------------------------------------------------------------------------
static const int NumRiverDirectionalLights = 1;
SasDirectionalLight DirectionalLight[NumRiverDirectionalLights]
<
	string SasBindAddress = "Sas.DirectionalLight[*]";
	string UIWidget = "None";
> =
{
	DEFAULT_DIRECTIONAL_LIGHT_1
};

// ----------------------------------------------------------------------------
// Reflection
// ----------------------------------------------------------------------------

SAMPLER_2D_BEGIN( WaterReflectionTexture,
	string UIWidget = "None";
	string SasBindAddress = "WaterDraw.ReflectionTexture";
	)
    MipFilter = Point;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = CLAMP;
    AddressV = CLAMP;
SAMPLER_2D_END

// ----------------------------------------------------------------------------
// Environment map
// ----------------------------------------------------------------------------
SAMPLER_CUBE_BEGIN( EnvironmentTexture,
	string UIWidget = "None";
	string SasBindAddress = "Terrain.EnvironmentTexture";
    string ResourceType = "Cube";
	)
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;
SAMPLER_CUBE_END

// ----------------------------------------------------------------------------
// Shroud
// ----------------------------------------------------------------------------
ShroudSetup Shroud
<
	string UIWidget = "None";
	string SasBindAddress = "Terrain.Shroud";
> = DEFAULT_SHROUD;


SAMPLER_2D_BEGIN( ShroudTexture,
	string UIWidget = "None";
	string SasBindAddress = "Terrain.Shroud.Texture";
	string ResourceName = "ShaderPreviewShroud.dds";
	)
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
SAMPLER_2D_END

// ----------------------------------------------------------------------------
// Transformations
// ----------------------------------------------------------------------------
float4x4 WorldViewProjection : WorldViewProjection;
float4x4 World : World;
float4x4 ViewI : ViewInverse;
float Time : Time;

// ----------------------------------------------------------------------------
// Fog
// ----------------------------------------------------------------------------
WW3DFog Fog
<
	string UIWidget = "None";
	string SasBindAddress = "WW3D.Fog";
> = DEFAULT_FOG_DISABLED;


// ----------------------------------------------------------------------------
// SHADER: Default
// ----------------------------------------------------------------------------
struct VSOutput
{
	float4 Position           : POSITION;
	float4 Color              : COLOR0;
	float  Fog                : COLOR1;
	float4 RiverTexCoord      : TEXCOORD0;
	float4 NormalTexCoord     : TEXCOORD1;
	float2 ShroudTexCoord     : TEXCOORD2;
	float4 ReflectionTexCoord : TEXCOORD3;
    float  SunSpecular        : TEXCOORD4;
};

// ----------------------------------------------------------------------------
VSOutput VS( float3 Position       : POSITION,
             float4 Color          : COLOR0,
             float2 RiverTexCoord  : TEXCOORD0,
             float2 NormalTexCoord : TEXCOORD1 )
{
	VSOutput Out;

    // Position
	Out.Position = mul( float4(Position, 1), WorldViewProjection );

    // Color
	float4 color = Color * 0.68; // Firestorm: slightly darker base to avoid reflection washout

    // Clamp the alpha so that it's never completely opaque
    color.w *= Opacity.w;
	color.w = clamp( color.w, 0, 0.95 );

	Out.Color = color;

    // Fog
	float3 worldPosition = mul( float4(Position, 1), World );
	Out.Fog = CalculateFog( Fog, worldPosition, ViewI[3] );

    // RiverTexCoord
    Out.RiverTexCoord.xy = NormalTexCoord * float2( 1.0, 0.55 ) + float2(  0.0015 * Time, -0.005 * Time );
    Out.RiverTexCoord.zw = (NormalTexCoord * float2( 0.72, 1.15 ) + float2( -0.0025 * Time, -0.014 * Time )).yx;

    // NormalTexCoord: fine/fast layer plus broader/slower opposing layer.
    Out.NormalTexCoord.xy = NormalTexCoord * float2( 1.10, 0.82 ) + float2(  0.006 * Time,  0.022 * Time );
    Out.NormalTexCoord.zw = (NormalTexCoord * float2( 0.72, 1.55 ) + float2( -0.009 * Time, -0.050 * Time )).yx;

    // ShroudTexCoord
	Out.ShroudTexCoord = CalculateShroudTexCoord( Shroud, worldPosition );

    // ReflectionTexCoord
   	Out.ReflectionTexCoord.xy = 0.5 * ( Out.Position.xy + Out.Position.w * float2(1.0, 1.0) );
   	Out.ReflectionTexCoord.z = Out.Position.w;

    // Cheap vertex Fresnel: rivers face upward, so this costs nothing in the pixel budget.
    float3 worldEyeDir = normalize(ViewI[3] - worldPosition);
    float3 worldNormal = float3(0, 0, 1);
    float riverNdotV = saturate(dot(worldEyeDir, worldNormal));
    Out.ReflectionTexCoord.w = (1.0f - riverNdotV) * (1.0f - riverNdotV);

    // Tiny world-sun sheen. Compute in VS to avoid spending ps_2_0 budget.
    float3 lightDir = normalize(-DirectionalLight[0].Direction);
    float3 halfDir = normalize(worldEyeDir + lightDir);
    Out.SunSpecular = pow(saturate(dot(worldNormal, halfDir)), RiverSunSpecularExponent) * RiverSunSpecularStrength;

	return Out;
}

// ----------------------------------------------------------------------------
float4 PS( VSOutput In ) : COLOR
{
	// Sample the base texture
	float4 color = tex2D( SAMPLER(RiverTexture), In.RiverTexCoord.xy ) + tex2D( SAMPLER(RiverTexture), In.RiverTexCoord.wz );

	// Apply vertex color
	color *= In.Color;

	// Sample the normal map and convert to the range -1 to 1
	float2 normalMapSample1 = tex2D( SAMPLER(NormalTexture), In.NormalTexCoord.xy ) * 2 - 1;
	float2 normalMapSample2 = tex2D( SAMPLER(NormalTexture), In.NormalTexCoord.wz ) * 2 - 1;

    // Apply the reflection map
	float2 reflectionCoord = In.ReflectionTexCoord.xy / In.ReflectionTexCoord.z;
	reflectionCoord += ( normalMapSample1 + normalMapSample2 ) * RiverReflectionPerturbation;

	float3 reflectionColor = tex2D( SAMPLER(WaterReflectionTexture), reflectionCoord );
    float reflectionAmount = saturate(In.ReflectionTexCoord.w * RiverReflectionStrength);
	color.xyz = lerp(color.xyz, reflectionColor, reflectionAmount);

    // Subtle sun glint, tinted by the actual directional light color.
    color.xyz += DirectionalLight[0].Color * In.SunSpecular;

    // Apply fog
    color.xyz = lerp( Fog.Color, color.xyz, In.Fog );

    // Apply shroud
	float3 shroud = tex2D( SAMPLER(ShroudTexture), In.ShroudTexCoord ).xyz;
	color.xyz *= shroud;

	return color;
}

// ----------------------------------------------------------------------------

technique Default_U
{
	pass P0
	<
		USE_EXPRESSION_EVALUATOR("RiverWater")
	>
	{
		VertexShader = compile VS_VERSION_HIGH VS();
		PixelShader  = compile PS_VERSION_HIGH PS();

		ZEnable = true;
		ZFunc = ZFUNC_INFRONT;
		ZWriteEnable = false;
		CullMode = None;
		AlphaBlendEnable = true;
		AlphaTestEnable = false;
		ColorWriteEnable = 7;

		// In additive blending we also need to use the alpha at the edges of river to darken rgb instead.
		SrcBlend = SRCALPHA;

#if !EXPRESSION_EVALUATOR_ENABLED
        DestBlend = ( IsAdditiveBlended ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );
#endif
	}
}

#if ENABLE_LOD

// ----------------------------------------------------------------------------
// SHADER: Default Medium Quality
// ----------------------------------------------------------------------------
struct VSOutput_M
{
	float4 Position           : POSITION;
	float4 Color              : COLOR0;
	float  Fog                : COLOR1;
	float4 RiverTexCoord      : TEXCOORD0;
	float2 NormalTexCoord     : TEXCOORD1;
	float2 ShroudTexCoord     : TEXCOORD2;
	float4 ReflectionTexCoord : TEXCOORD3;
    float  SunSpecular        : TEXCOORD4;
};

// ----------------------------------------------------------------------------
VSOutput_M VS_M( float3 Position       : POSITION,
             float4 Color          : COLOR0,
             float2 RiverTexCoord  : TEXCOORD0,
             float2 NormalTexCoord : TEXCOORD1 )
{
	VSOutput_M Out;

    // Position
	Out.Position = mul( float4(Position, 1), WorldViewProjection );

    // Color
	float4 color = Color * 0.68; // Firestorm: slightly darker base to avoid reflection washout

    // Clamp the alpha so that it's never completely opaque
    color.w *= Opacity.w;
	color.w = clamp( color.w, 0, 0.95 );

	Out.Color = color;

    // Fog
	float3 worldPosition = mul( float4(Position, 1), World );
	Out.Fog = CalculateFog( Fog, worldPosition, ViewI[3] );

    // RiverTexCoord
    Out.RiverTexCoord.xy = NormalTexCoord * float2( 1.0, 0.55 ) + float2(  0.0015 * Time, -0.005 * Time );
    Out.RiverTexCoord.zw = (NormalTexCoord * float2( 0.72, 1.15 ) + float2( -0.0025 * Time, -0.014 * Time )).yx;

    // NormalTexCoord
    Out.NormalTexCoord.xy = NormalTexCoord * float2( 1.10, 0.82 ) + float2(  0.006 * Time,  0.022 * Time );

    // ShroudTexCoord
	Out.ShroudTexCoord = CalculateShroudTexCoord( Shroud, worldPosition );

   	// Compute view direction in world space
	float3 worldEyeDir = normalize(ViewI[3] - worldPosition);
	// Compute env map reflection direction
	float3 worldNormal = float3(0, 0, 1); // Rivers always face up
	Out.ReflectionTexCoord.xyz = -reflect(worldEyeDir, worldNormal);
    float riverNdotV = saturate(dot(worldEyeDir, worldNormal));
    Out.ReflectionTexCoord.w = (1.0f - riverNdotV) * (1.0f - riverNdotV);

    float3 lightDir = normalize(-DirectionalLight[0].Direction);
    float3 halfDir = normalize(worldEyeDir + lightDir);
    Out.SunSpecular = pow(saturate(dot(worldNormal, halfDir)), RiverSunSpecularExponent) * RiverSunSpecularStrength;

	return Out;
}

// ----------------------------------------------------------------------------
float4 PS_M( VSOutput_M In ) : COLOR
{
	// Sample the base texture
	float4 color = tex2D( SAMPLER(RiverTexture), In.RiverTexCoord.xy ) + tex2D( SAMPLER(RiverTexture), In.RiverTexCoord.wz );

	// Apply vertex color
	color *= In.Color;

	// Sample the normal map and convert to the range -1 to 1
	float3 normalMapSample1 = tex2D( SAMPLER(NormalTexture), In.NormalTexCoord.xy ) * 2 - 1;

    // Apply the reflection map
	float3 reflectionDirection = In.ReflectionTexCoord.xyz + float3(normalMapSample1.xy * (RiverReflectionPerturbation * 1.5f), 0);

	float3 reflectionColor = texCUBE(SAMPLER(EnvironmentTexture), reflectionDirection);
    float reflectionAmount = saturate(In.ReflectionTexCoord.w * RiverReflectionStrength);
	color.xyz = lerp(color.xyz, reflectionColor, reflectionAmount);

    color.xyz += DirectionalLight[0].Color * In.SunSpecular;

    // Apply fog
    color.xyz = lerp( Fog.Color, color.xyz, In.Fog );

    // Apply shroud
	float3 shroud = tex2D( SAMPLER(ShroudTexture), In.ShroudTexCoord ).xyz;
	color.xyz *= shroud;

	return color;
}

// ----------------------------------------------------------------------------
// TECHNIQUE: High Quality
// ----------------------------------------------------------------------------
technique _Default
{
	pass P0
	<
		USE_EXPRESSION_EVALUATOR("RiverWater")
	>
	{
		VertexShader = compile VS_VERSION_HIGH VS_M();
		PixelShader  = compile PS_VERSION_HIGH PS_M();

		ZEnable = true;
		ZFunc = ZFUNC_INFRONT;
		ZWriteEnable = false;
		CullMode = None;
		AlphaBlendEnable = true;
		AlphaTestEnable = false;
		ColorWriteEnable = 7;

		// In additive blending we also need to use the alpha at the edges of river to darken rgb instead.
		SrcBlend = SRCALPHA;

#if !EXPRESSION_EVALUATOR_ENABLED
        DestBlend = ( IsAdditiveBlended ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );
#endif
	}
}


// ----------------------------------------------------------------------------
// SHADER: Default Low Quality
// ----------------------------------------------------------------------------
struct VSOutput_L
{
	float4 Position           : POSITION;
	float4 Color              : COLOR0;
	float2 RiverTexCoord0     : TEXCOORD0;
	float2 RiverTexCoord1     : TEXCOORD1;
	float2 ShroudTexCoord     : TEXCOORD2;
};

// ----------------------------------------------------------------------------
VSOutput_L VS_L( float3 Position       : POSITION,
             float4 Color          : COLOR0,
             float2 RiverTexCoord  : TEXCOORD0,
             float2 NormalTexCoord : TEXCOORD1 )
{
	VSOutput_L Out;

    // Position
	Out.Position = mul( float4(Position, 1), WorldViewProjection );
	float3 worldPosition = mul( float4(Position, 1), World );

    // Color
	float4 color = Color * 0.68; // Firestorm: slightly darker base to match higher LODs

	// Clamp the alpha so that it's never completely opaque
    color.w *= Opacity.w;
	color.w = clamp( color.w, 0, 0.95 );
	Out.Color = color;

    // RiverTexCoord
    Out.RiverTexCoord0 = NormalTexCoord * float2( 1.0, 0.55 ) + float2(  0.0015 * Time, -0.005 * Time );
    Out.RiverTexCoord1 = NormalTexCoord * float2( 0.72, 1.15 ) + float2( -0.0025 * Time, -0.014 * Time );

    // ShroudTexCoord
	Out.ShroudTexCoord = CalculateShroudTexCoord( Shroud, worldPosition );

	return Out;
}

// ----------------------------------------------------------------------------
float4 PS_L( VSOutput_L In ) : COLOR
{
	// Sample the base texture
	float4 color = tex2D( SAMPLER(RiverTexture), In.RiverTexCoord0 ) + tex2D( SAMPLER(RiverTexture), In.RiverTexCoord1 );

	// Apply vertex color
	color *= In.Color;

    // Apply shroud
	float3 shroud = tex2D( SAMPLER(ShroudTexture), In.ShroudTexCoord ).xyz;
	color.xyz *= shroud;

	return color;
}

// ----------------------------------------------------------------------------
// TECHNIQUE: Low Quality
// ----------------------------------------------------------------------------
technique _Default_L
{
	pass P0
	<
		USE_EXPRESSION_EVALUATOR("RiverWater")
	>
	{
		VertexShader = compile VS_VERSION_LOW VS_L();
		PixelShader  = compile PS_VERSION_LOW PS_L();

		ZEnable = true;
		ZFunc = ZFUNC_INFRONT;
		ZWriteEnable = false;
		CullMode = None;
		AlphaBlendEnable = true;
		AlphaTestEnable = false;
		ColorWriteEnable = 7;

		// In additive blending we also need to use the alpha at the edges of river to darken rgb instead.
		SrcBlend = SRCALPHA;

#if !EXPRESSION_EVALUATOR_ENABLED
        DestBlend = ( IsAdditiveBlended ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );
#endif
	}
}
#endif
