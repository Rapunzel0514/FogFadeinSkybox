//This is modified based on Kino Fog
//https://github.com/keijiro/KinoFog
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DepthTest" {  


	Properties
    {
   		 _MainTex ("-", 2D) = "" {}
        _FogColor ("-", Color) = (0, 0, 0, 0)
        _SkyTint ("-", Color) = (.5, .5, .5, .5)
        [Gamma] _SkyExposure ("-", Range(0, 8)) = 1.0
        [NoScaleOffset] _SkyCubemap ("-", Cube) = "" {}
    }

    CGINCLUDE  
    #include "UnityCG.cginc"  

    #pragma multi_compile _ USE_SKYBOX
    //#pragma multi_compile FOG_LINEAR FOG_EXP FOG_EXP2
    #pragma multi_compile _ RADIAL_DIST

    sampler2D _CameraDepthTexture;  
    sampler2D _MainTex;  
    float4    _MainTex_TexelSize;  
    samplerCUBE _SkyCubemap;
    half4 _SkyCubemap_HDR;
    half _SkyExposure;
    float _SkyRotation;
    float _DistanceOffset = 1;
    float _Density;
    half4 _FogColor;
    half4 _SkyTint;
	 
    float3 RotateAroundYAxis(float3 v, float deg)
    {
        float alpha = deg * UNITY_PI / 180.0;
        float sina, cosa;
        sincos(alpha, sina, cosa);
        float2x2 m = float2x2(cosa, -sina, sina, cosa);
        return float3(mul(m, v.xz), v.y).xzy;
    }

    // Distance-based fog
    float ComputeDistance(float3 ray, float depth)
    {
		float dist;
		#if RADIAL_DIST
			dist = length(ray * depth);
		#else
			dist = depth * _ProjectionParams.z;
		#endif
		// Built-in fog starts at near plane, so match that by
		// subtracting the near value. Not a perfect approximation
		// if near plane is very large, but good enough.
		dist -= _ProjectionParams.y;
        return dist;
    }

    half ComputeFogFactor(float coord)
    {
        float fog = 0.0;
		#if FOG_LINEAR
			// factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
			fog = coord * _LinearGrad + _LinearOffs;
		#elif FOG_EXP
			// factor = exp(-density*z)
			fog = _Density * coord;
			fog = exp2(-fog);
		#else // FOG_EXP2
			// factor = exp(-(density*z)^2)
			fog = _Density * coord;
			fog = exp2(-fog * fog);
		#endif
			return saturate(fog);
    }

    struct v2f  
    {  
        float4 pos : SV_POSITION;  
        float2 uv  : TEXCOORD0;  
        float2 uv_depth : TEXCOORD1;
        float3 ray : TEXCOORD2;
    };  
  
    v2f vert(appdata_full v)  
    {  
        v2f o;  
        o.pos = UnityObjectToClipPos(v.vertex);  
        o.uv.xy = v.texcoord.xy;  
        o.uv_depth = v.texcoord.xy;
        o.ray = RotateAroundYAxis(v.texcoord1.xyz, -_SkyRotation);
        return o;  
    }  
  
    fixed4 frag(v2f i) : SV_Target  
    {  

    	half4 sceneColor = tex2D(_MainTex, i.uv);

        float zsample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
        float depth = Linear01Depth(zsample * (zsample < 1.0));

        half3 skyColor = DecodeHDR(texCUBE(_SkyCubemap, i.ray ), _SkyCubemap_HDR);
        skyColor *= _SkyTint.rgb * _SkyExposure * unity_ColorSpaceDouble;
        // Lerp between source color to skybox color with fog amount.
        return lerp(half4(skyColor, 1), sceneColor, (1 - (depth - _DistanceOffset) ));
    }  
  
    ENDCG  
  
    SubShader  
    {  
        Pass  
        {  
  
            ZTest Off  
            Cull Off  
            ZWrite Off  
            Fog{ Mode Off }  
  
            CGPROGRAM  
            #pragma vertex vert  
            #pragma fragment frag  
            ENDCG  
        }  
  
    }  
}  