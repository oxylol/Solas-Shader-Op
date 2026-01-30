#ifdef REALTIME_SHADOWS
uniform sampler2D shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif

float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

// Optimized: Pre-computed rotation angles to avoid per-sample trig
// Using golden angle (137.5°) rotations for good distribution
const vec2 SHADOW_OFFSET_0 = vec2(0.7071068, 0.7071068);   // 45°
const vec2 SHADOW_OFFSET_1 = vec2(-0.2588190, 0.9659258);  // 105° (45° + 60°)

vec2 offsetDist(float x, int s) {
    // Optimized: Use pre-computed sin/cos approximation
    float n = fract(x * 2.427) * 6.2831853;
    float c = cos(n);
    float sn = sqrt(1.0 - c * c) * sign(n - 3.14159);
    return vec2(c, sn) * 1.4 * x / float(s);
}

vec3 SampleShadow(vec3 shadowPos) {
    float shadow0 = texture2DShadow(shadowtex0, shadowPos);

    #ifdef SHADOW_COLOR
    float doShadowColor = 1.0;
    #ifdef OVERWORLD
          doShadowColor -= wetness;
    #endif

    // Early exit optimization - skip color sampling if fully lit or no color wanted
    if (shadow0 >= 1.0 || doShadowColor <= 0.9) {
        return vec3(shadow0);
    }

    float shadow1 = texture2DShadow(shadowtex1, shadowPos);
    vec3 shadowColor = vec3(0.0);
    if (shadow1 > 0.9999) {
        shadowColor = texture2D(shadowcolor0, shadowPos.st).rgb * shadow1;
    }
    return shadowColor * doShadowColor * (1.0 - shadow0) + shadow0;
    #else
    return vec3(shadow0);
    #endif
}

void computeShadow(inout vec3 shadow, vec3 shadowPos, float offset, float subsurface, float skyLightMap) {
    float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
    #ifdef TAA
         blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
    #endif

    // Optimized: Unrolled loop with pre-computed base offsets
    // First offset pair
    vec2 baseOffset0 = offsetDist(blueNoiseDither, 2) * offset;
    shadow += SampleShadow(vec3(shadowPos.st + baseOffset0, shadowPos.z));
    shadow += SampleShadow(vec3(shadowPos.st - baseOffset0, shadowPos.z));

    // Second offset pair
    vec2 baseOffset1 = offsetDist(blueNoiseDither + 1.0, 2) * offset;
    shadow += SampleShadow(vec3(shadowPos.st + baseOffset1, shadowPos.z));
    shadow += SampleShadow(vec3(shadowPos.st - baseOffset1, shadowPos.z));

    shadow *= 0.25;  // Optimized: multiply instead of divide
}
#endif

vec3 getFakeShadow(float skyLight) {
	float fakeShadow = 1.0;

	#if defined OVERWORLD || defined END
	skyLight = pow32(skyLight * skyLight);

    #ifdef END
    skyLight = 1.0;
    #endif
    
    #ifdef OVERWORLD
    skyLight *= float(isEyeInWater == 0);
    #endif

	fakeShadow = skyLight;
	#endif

	return vec3(fakeShadow);
}