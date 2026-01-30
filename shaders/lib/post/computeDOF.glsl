// Iris-only: Reduced from 32 to 16 samples for better performance
const vec2 blurOffsets16[16] = vec2[16](
	vec2(0.12064426510477419, 0.01555443141176569),
	vec2(-0.16400077998918963, 0.16180237012184204),
	vec2(0.19686650437195816, 0.27801320993574674),
	vec2(-0.37362329188851157, -0.04976379998047616),
	vec2(0.34544673107582735, -0.20696126421568928),
	vec2(-0.22749138875333694, -0.41407969197383454),
	vec2(0.4797593802468298, 0.19235249500691445),
	vec2(-0.5079968434096749, 0.22345015963708734),
	vec2(0.23843255951864029, -0.5032700515259672),
	vec2(-0.5451127409909945, -0.29782530685850084),
	vec2(0.6300137885218894, -0.12390992876509888),
	vec2(-0.391501580064061, 0.5662295575692019),
	vec2(0.5447160222309757, 0.47831268960533435),
	vec2(-0.7432342062047558, 0.046109375942755174),
	vec2(0.5345993903170301, -0.520777903066999),
	vec2(-0.6926663754026566, 0.4944630470831171)
);

vec3 getDepthOfField(vec3 color, vec2 coord, float z1) {
	vec3 blur = vec3(0.0);

	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = 0.0;

	#ifdef DOF
	coc = max(abs(z1 - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
	// Optimized: use inversesqrt
	coc *= inversesqrt(coc * coc + 0.1);
	#endif

	#ifdef DISTANT_BLUR
	vec3 viewPos = ToView(vec3(coord, z1));
	coc = min(length(viewPos) * DISTANT_BLUR_RANGE * 0.00025, DISTANT_BLUR_STRENGTH * 0.025) * DISTANT_BLUR_STRENGTH;
	#endif

    float lod = log2(viewHeight * aspectRatio * coc * fovScale / 320.0);

	if (coc > 0.0 && z1 > 0.56) {
		vec2 cocScale = coc * 0.025 * fovScale * vec2(1.0 / aspectRatio, 1.0);
		for(int i = 0; i < 16; i++) {
			vec2 offset = blurOffsets16[i] * cocScale;
			blur += texture2DLod(colortex0, coord + offset, lod).rgb;
		}
		blur *= 0.0625;  // 1/16
	} else blur = color;

	return blur;
}