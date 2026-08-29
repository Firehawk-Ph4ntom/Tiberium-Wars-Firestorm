//-----------------------------------------------------------------------------
// ©2006 Electronic Arts Inc
//-----------------------------------------------------------------------------

#include "Common.fxh"

float4x4 World       : World;
float4x4 View        : View;
float4x3 ViewInverse : ViewInverse;
float4x4 Projection  : Projection;

float Time : Time;

// ----------------------------------------------------------------------------
// Rain Box Size
// ----------------------------------------------------------------------------

float RainBoxWidth
<
    string UIName = "Rain Box Width";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 1600.0;

float RainBoxLength
<
    string UIName = "Rain Box Length";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 1600.0;

float RainBoxHeight
<
	string UIName = "Rain Box Height";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 350.0;

// ----------------------------------------------------------------------------
// Size
// ----------------------------------------------------------------------------

float MinWidth
<
	string UIName = "Min Width";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 0.5;

float MaxWidth
<
	string UIName = "Max Width";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 1.5;

float MinHeight
<
	string UIName = "Min Height";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 5.0;

float MaxHeight
<
	string UIName = "Max Height";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 15.0;

// ----------------------------------------------------------------------------
// Speed
// ----------------------------------------------------------------------------

float MinSpeed
<
	string UIName = "Min Speed";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 50.0;

float MaxSpeed
<
	string UIName = "Max Speed";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 150.0;

// ----------------------------------------------------------------------------
// Alpha
// ----------------------------------------------------------------------------

float MinAlpha
<
	string UIName = "Min Alpha";
    float UIMin = 0.0;
    float UIMax = 1.0;
> = 0.1;

float MaxAlpha
<
	string UIName = "Max Alpha";
    float UIMin = 0.0;
    float UIMax = 1.0;
> = 0.5;

// ----------------------------------------------------------------------------
// Wind
// ----------------------------------------------------------------------------

float WindStrength
<
	string UIName = "Wind Strength";
    float UIMin = 0.0;
    float UIMax = 10000.0;
> = 1.0;

// Firestorm/C&C4-style shader-side controls.
// TW's Weather schema exposes WindStrength but not a vector direction.
static const float2 WindDirection = float2(1.0, 0.35);
static const float WorldStretchFactor = 1.0;
static const float RainBrightness = 1.0;

// ----------------------------------------------------------------------------
// Diffuse Texture
// ----------------------------------------------------------------------------

SAMPLER_2D_BEGIN( DiffuseTexture,
    string UIWidget = "None";
	)
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
SAMPLER_2D_END

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

//-----------------------------------------------------------------------------
// Vertex Shader structure
//-----------------------------------------------------------------------------

struct VSInput
{
    float3 Position                              : POSITION;
    float4 Width_Height_Speed_Alpha_Interpolants : COLOR0;
    float2 DiffuseTexCoord                       : TEXCOORD0;
};

struct VSOutput
{
    float4 Position        : POSITION;
    float4 Color           : COLOR0;
    float2 DiffuseTexCoord : TEXCOORD0;
    float2 ShroudTexCoord  : TEXCOORD1;
};

//-----------------------------------------------------------------------------
// Vertex Shader
//-----------------------------------------------------------------------------

VSOutput VS( VSInput Input )
{
    VSOutput Out;

    // Per-particle authored random interpolants.
    float width_interpolant  = Input.Width_Height_Speed_Alpha_Interpolants.x;
    float height_interpolant = Input.Width_Height_Speed_Alpha_Interpolants.y;
    float speed_interpolant  = Input.Width_Height_Speed_Alpha_Interpolants.z;
    float alpha_interpolant  = Input.Width_Height_Speed_Alpha_Interpolants.w;

    float width  = lerp( MinWidth,  MaxWidth,  width_interpolant );
    float speed  = lerp( MinSpeed,  MaxSpeed,  speed_interpolant );

    // Borrow the C&C4 idea that faster particles tend to become longer streaks.
    float random_height = lerp( MinHeight, MaxHeight, height_interpolant );
    float speed_height  = lerp( MinHeight, MaxHeight, speed_interpolant );
    float height = lerp( random_height, speed_height, 0.60 );

    float alpha = lerp( MinAlpha, MaxAlpha, alpha_interpolant );

    // TW supplies actual particle geometry through World. Unlike C&C4 we do not
    // have normalized tile coordinates or native WW3D.Weather.TileOffset.
    float3 base_world_pos = mul( float4( Input.Position, 1 ), World ).xyz;

    // Recreate C&C4's ForwardDirection concept from TW's existing scalar
    // WindStrength plus a shader-side horizontal direction.
    float2 horizontal_wind = normalize(WindDirection) * WindStrength;
    float3 velocity = float3(horizontal_wind.x, horizontal_wind.y, -speed);

    // Simulate position continuously in true world XYZ.
    float3 simulated_world_pos = base_world_pos + velocity * Time;

    // C&C4-inspired camera-centered periodic weather tile.
    // This is the key architectural difference from vanilla TW:
    // all THREE axes wrap inside a periodic volume every frame.
    float3 box_size = max(
        float3(RainBoxWidth, RainBoxLength, RainBoxHeight),
        float3(1.0, 1.0, 1.0)
    );

    // Center XY on camera. Keep the vertical tile extending around the camera
    // as well, so aggressive pan/rotation cannot expose a finite edge.
    float3 camera_pos = ViewInverse[3];
    float3 tile_origin = camera_pos - box_size * 0.5;

    float3 local_pos = simulated_world_pos - tile_origin;

    // Positive periodic wrap. frac avoids negative-fmod edge behavior.
    local_pos = frac(local_pos / box_size) * box_size;

    float3 world_pos_center = tile_origin + local_pos;

    // Fade near tile boundaries to reduce visible teleporting as particles wrap.

    // Center authored quad UVs around the particle center.
    float2 quad_offset = Input.DiffuseTexCoord - float2(0.5, 0.5);

    // World-space streak follows the actual particle velocity, mirroring the
    // C&C4 RandomDirectionStretch.w = 1 behavior.
    float3 streak_dir = normalize(velocity);

    // Width remains camera-readable using a true 3D axis perpendicular to both
    // motion and the camera direction.
    float3 view_dir = normalize(camera_pos - world_pos_center);
    float3 streak_right = cross(streak_dir, view_dir);

    float right_len2 = dot(streak_right, streak_right);
    if (right_len2 > 0.0001)
        streak_right *= rsqrt(right_len2);
    else
        streak_right = float3(1.0, 0.0, 0.0);

    float3 final_world_pos =
          world_pos_center
        + streak_dir   * (quad_offset.y * height * WorldStretchFactor)
        + streak_right * (quad_offset.x * width);

    // Standard view/projection.
    float3 vertex_view_pos = mul( float4( final_world_pos, 1 ), View ).xyz;
    Out.Position = mul( float4( vertex_view_pos, 1 ), Projection );

    Out.DiffuseTexCoord = Input.DiffuseTexCoord;
    Out.Color = float4(1, 1, 1, alpha);

    // Shroud from actual world-space rain position.
    Out.ShroudTexCoord = CalculateShroudTexCoord( Shroud, final_world_pos );

    return Out;
}

//-----------------------------------------------------------------------------
// Pixel Shader
//-----------------------------------------------------------------------------

float4 PS( VSOutput Input ) : Color
{
    float4 color = Input.Color;

    // Apply Diffuse Texture
    float4 diffuse_texture = tex2D( SAMPLER(DiffuseTexture), Input.DiffuseTexCoord );
    color *= diffuse_texture;
    color.xyz *= RainBrightness;

    // V4.1 diagnostic: do NOT mask rain alpha by Terrain.Shroud.
    // The camera-centered XYZ wrap can place weather vertices outside the
    // terrain's map-space shroud domain, especially at a map edge. A clamped/
    // empty border texel can otherwise erase perfectly valid rain particles.
    //
    // float shroud = tex2D( SAMPLER(ShroudTexture), Input.ShroudTexCoord ).x;
    // color.w *= shroud;

    return color;
}

//-----------------------------------------------------------------------------
// Techniques
//-----------------------------------------------------------------------------

technique Default
{
    pass pass0
    {
        VertexShader = compile VS_VERSION_LOW VS();
        PixelShader  = compile PS_VERSION_LOW PS();

        ZEnable          = false;
        ZWriteEnable     = false;
        ZFunc            = ZFUNC_INFRONT;
        AlphaBlendEnable = true;

        CullMode         = none;
        AlphaTestEnable  = false;
        SrcBlend         = SrcAlpha;
        DestBlend        = InvSrcAlpha;

#if !defined( _NO_FIXED_FUNCTION_ )
        FogEnable = false;
#endif
    }
}
