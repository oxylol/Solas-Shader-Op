// Optimized: Using exp2 which is faster on most GPUs
// exp(x) = exp2(x * 1.4426950408889634)  (1/ln(2))
const float LOG2_E = 1.4426950408889634;

//1.19 Darkness Fog
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * darknessFactor * 0.01;
	// Optimized: exp2 instead of exp
	fog = (1.0 - exp2(-fog * LOG2_E)) * darknessFactor;

    color *= 1.0 - fog;
}
#endif

//Blindness Fog
void getBlindFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * blindFactor * 0.1;
	float fogCubed = fog * fog * fog;
	// Optimized: exp2 instead of exp, pre-multiply constant
	fog = (1.0 - exp2(-5.7707801635 * fogCubed)) * blindFactor;  // -4.0 * LOG2_E = -5.7707801635

	color *= 1.0 - fog;
}

//Powder Snow / Lava Fog
const vec3 densefogCol[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, float lViewPos) {
	float fogMult = 0.15 + float(isEyeInWater == 3) * 0.5;
	float fog = lViewPos * fogMult;
	// Optimized: exp2 instead of exp
	fog = 1.0 - exp2(-2.8853900817 * fog * fog);  // -2.0 * LOG2_E = -2.8853900817

	color = fmix(color, densefogCol[isEyeInWater - 2], fog);
}

//Normal Fog
void getNormalFog(inout vec3 color, in vec3 atmosphereColor, in vec3 viewPos, in vec3 worldPos, in float lViewPos, in float lWorldPos, in float z0) {
    float farPlane = far;

    #ifdef VOXY
            farPlane = max(farPlane, vxRenderDistance * 16.0);
    #endif

    #ifdef DISTANT_HORIZONS
            farPlane = max(farPlane, float(dhRenderDistance));
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
	vec3 fogPos = worldPos + cameraPosition;
	float noise = texture2D(noisetex, (fogPos.xz + fogPos.y) * 0.0005 + frameCounter * 0.00001).r;
            noise *= noise;
    float distanceFactor = 50.0 * (0.5 + timeBrightness * 0.75) + FOG_DISTANCE * (0.75 + caveFactor * 0.25) - wetness * 25.0;
	// Optimized: Pre-compute inverse to use multiplication instead of division
	float invDistanceFactor = 1.0 / distanceFactor;
	float distanceMult = max(256.0 / farPlane, 2.0) * (100.0 * invDistanceFactor);
	float altitudeFactor = FOG_HEIGHT + noise * 10.0 + timeBrightness * 25.0 - isJungle * 15.0;
	// Optimized: Combine exp2 operations
	float heightFalloff = FOG_HEIGHT_FALLOFF + moonVisibility + timeBrightness + wetness - isJungle - isSwamp;
	float altitudeArg = max(worldPos.y + cameraPosition.y - altitudeFactor, 0.0);
	float altitude = 0.25 + exp2(-altitudeArg * exp2(-heightFalloff));
		  //altitude = fmix(1.0, altitude, clamp((cameraPosition.y - altitude) / altitude, 0.0, 1.0));
	float density = FOG_DENSITY * (1.0 + (sunVisibility - timeBrightness) * 0.25 + moonVisibility * 0.5) * (0.5 + noise);
		  density += isLushCaves * 0.25 + (isDesert * 0.15 + isSwamp * 0.20 + isJungle * 0.35);

	#if MC_VERSION >= 12104
    	  density += isPaleGarden * 0.5;
	#endif

    // Optimized: exp2 instead of exp
    float fog = 1.0 - exp2(-0.0072135 * lViewPos * distanceMult);  // -0.005 * LOG2_E = -0.0072135
		  fog = clamp(fog * density * altitude, 0.0, 1.0);

    vec3 nSkyColor = 0.75 * sqrt(normalize(skyColor + 0.000001)) * fmix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
	vec3 fogCol = fmix(caveMinLightCol * (1.0 - isCaveBiome) + caveBiomeColor,
                   fmix(pow(atmosphereColor, vec3(1.0 - sunVisibility * 0.5)), nSkyColor, sunVisibility * min((1.0 - wetness) * (1.0 - fog), 1.0)) * 0.75,
                   caveFactor);

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater == 0) {
		#if MC_VERSION >= 11800
		const float fogOffset = 0.0;
		#else
		const float fogOffset = 12.0;
		#endif

		#if DISTANT_FADE_STYLE == 0
		float fogFactor = lWorldPos;
		#else
		float fogFactor = lViewPos;
		#endif

        float distancePow = 4.0;
        #if defined DISTANT_HORIZONS || defined VOXY
                distancePow -= 3.0;
        #endif

		float vanillaFog = 1.0 - (farPlane - (fogFactor + fogOffset)) / farPlane;
		        vanillaFog = clamp(pow(vanillaFog, distancePow), 0.0, 1.0) * caveFactor;
	
		if (vanillaFog > 0.0){
			fogCol *= fog;
			fog = fmix(fog, 1.0, vanillaFog);

			if (0.0 < fog) fogCol = fmix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.005;
	#ifdef DISTANT_FADE
	      // Optimized: Pre-compute inverse farPlane
	      float invFarPlane = 1.0 / farPlane;
	      float normalizedDist = lWorldPos * invFarPlane;
	      float dist4 = normalizedDist * normalizedDist;
	      dist4 *= dist4;
	      fog += 6.0 * dist4;
	#endif
	      // Optimized: exp2 instead of exp
	      fog = 1.0 - exp2(-fog * LOG2_E);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

	//End fog
	#ifdef END
    vec3 wpos = ToWorld(viewPos);
    // Optimized: Use inversesqrt for normalization
    float wposLen = length(wpos);
    vec3 nWorldPos = wpos * inversesqrt(dot(wpos, wpos) + 0.0001);
    nWorldPos.y += nWorldPos.x * END_ANGLE;

    #ifdef END_67
    if (frameCounter < 500) {
        nWorldPos.y += nWorldPos.x * 0.5 * sin(frameTimeCounter * 8.0);
    }
    #endif

	#ifdef END_TIME_TILT
		nWorldPos.y += nWorldPos.x * min(0.025 * frameTimeCounter, 1.0);
	#endif

	// Optimized: pow4 inline
	float absY = 1.0 - abs(nWorldPos.y);
	float absYSqr = absY * absY;
	float density = absYSqr * absYSqr;
		  density *= 1.0 - clamp((cameraPosition.y - 100.0) * 0.01, 0.0, 1.0);

	// Optimized: exp2 instead of exp, use cached length
	float fog = 1.0 - exp2(-0.00014427 * wposLen);  // -0.0001 * LOG2_E
		  fog = clamp(fog * density, 0.0, 1.0);

	vec3 fogCol = vec3(1.0, 1.0, 0.75) * endLightColSqrt;
	#endif

    //Mixing Colors depending on depth
	#if !defined NETHER && !defined END && defined DEFERRED && !defined DISTANT_HORIZONS
    float zMixer = float(z0 < 1.0);

	#if MC_VERSION >= 12104 && defined OVERWORLD
		  zMixer = fmix(zMixer, 1.0, isPaleGarden);
	#endif
	      zMixer = clamp(zMixer, 0.0, 1.0);

	fog *= zMixer;
	#endif

	color = fmix(color, fogCol, fog);
}

void Fog(inout vec3 color, in vec3 viewPos, in vec3 atmosphereColor, in float z0) {
	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
	        worldPos.xyz /= worldPos.w;

    float lViewPos = length(viewPos.xz);
    float lWorldPos = length(worldPos.xz);

	if (isEyeInWater < 1) {
        getNormalFog(color, atmosphereColor, viewPos, worldPos.xyz, lViewPos, lWorldPos, z0);
    } else if (isEyeInWater > 1) {
        getDenseFog(color, lViewPos);
    }
	if (blindFactor > 0.0) getBlindFog(color, lViewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0.0) getDarknessFog(color, lViewPos);
	#endif
}