// Optimized: Inline division and reduce redundant length() calls
vec3 nvec3(vec4 pos) {
    return pos.xyz * (1.0 / pos.w);
}

const float errMult = 2.8;

vec3 Raytrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, float fresnel,
			  int refinementSteps, float stepSize, float refMult, float stepLength, int sampleCount, out float border, out float lRfragPos, out float dist, out vec2 cdist) {
	vec3 pos = vec3(0.0);
    vec3 rfragpos = vec3(0.0);
    float viewLen = length(viewPos);
	vec3 start = viewPos + normal * (viewLen * (0.025 - fresnel * 0.025) + 0.05);
    vec3 reflectDir = normalize(reflect(viewPos, normal));
    vec3 rayIncrement = stepSize * reflectDir;
    viewPos += rayIncrement;
	vec3 rayDir = rayIncrement;

    int refinedSamples = 0;
    float rayIncrementLen = stepSize;

    // Optimized: Reduced default sample count, faster early exit
    sampleCount = min(sampleCount, 24);

    for (int i = 0; i < sampleCount; i++) {
        vec4 projPos = gbufferProjection * vec4(viewPos, 1.0);
        pos = projPos.xyz * (1.0 / projPos.w) * 0.5 + 0.5;

        // Early exit on screen bounds
		if (abs(pos.x - 0.5) > 0.6 || abs(pos.y - 0.5) > 0.55) break;

		float sampledDepth = texture2D(depthtex, pos.xy).r;
        vec4 rfragprojInv = gbufferProjectionInverse * vec4(pos.xy * 2.0 - 1.0, sampledDepth * 2.0 - 1.0, 1.0);
        rfragpos = rfragprojInv.xyz * (1.0 / rfragprojInv.w);

        vec3 diff = viewPos - rfragpos;
        float errSqr = dot(diff, diff);

        if (errSqr < rayIncrementLen * rayIncrementLen * errMult * errMult) {
			refinedSamples++;
			if (refinedSamples >= refinementSteps) break;
			rayDir -= rayIncrement;
			rayIncrement *= refMult;
            rayIncrementLen *= refMult;
		}
        rayIncrement *= stepLength;
        rayIncrementLen *= stepLength;
        rayDir += rayIncrement * (0.1 * dither + 0.9);
		viewPos = start + rayDir;
    }

    dist = length(start - rfragpos);
    lRfragPos = length(rfragpos);
    cdist = abs(pos.xy - 0.5) * vec2(1.6667, 1.8182);  // Pre-computed 1/0.6 and 1/0.55
    float maxCdist = max(cdist.x, cdist.y);
    float maxCdist32 = maxCdist * maxCdist;
    maxCdist32 *= maxCdist32; maxCdist32 *= maxCdist32; maxCdist32 *= maxCdist32; maxCdist32 *= maxCdist32;
    border = clamp(1.0 - maxCdist32 * maxCdist32, 0.0, 1.0);

	return pos;
}