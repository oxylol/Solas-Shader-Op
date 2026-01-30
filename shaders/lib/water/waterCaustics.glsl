float getWaterHeightMap(vec3 worldPos, vec2 offset) {
    float noise = 0.0;
    
    vec2 wind = vec2(frameTimeCounter) * 0.5 * WATER_NORMAL_SPEED;

	offset /= 256.0;
	worldPos.xz -= worldPos.y * 0.2;

	#if WATER_NORMALS == 1
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 256.0 + offset).g;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 48.0 + offset).g;
	#elif WATER_NORMALS == 2
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 256.0 + offset).r * 1.25;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 96.0 + offset).r;
	noiseA *= noiseA; noiseB *= noiseB;
	#elif WATER_NORMALS == 3
	float noiseA = texture2D(noisetex, (worldPos.xz - wind) / 256.0 + offset).r * 1.25;
	float noiseB = texture2D(noisetex, (worldPos.xz + wind) / 32.0 + offset).g;
	noiseA *= noiseA;
	#endif
	
	#if WATER_NORMALS > 0
	noise = mix(noiseA, noiseB, WATER_NORMAL_DETAIL);
	#endif

	return noise * WATER_NORMAL_BUMP;
}

// Iris-only: Reduced from 5 to 3 texture samples using diagonal sampling
float getWaterCaustics(vec3 waterPos) {
	float h0 = getWaterHeightMap(waterPos, vec2(0.0));
	float h1 = getWaterHeightMap(waterPos, vec2( WATER_NORMAL_OFFSET,  WATER_NORMAL_OFFSET));
	float h2 = getWaterHeightMap(waterPos, vec2(-WATER_NORMAL_OFFSET, -WATER_NORMAL_OFFSET));

	float invOffset = 1.0 / (WATER_NORMAL_OFFSET * 1.414);  // sqrt(2) for diagonal
	float delta1 = (h1 - h0) * invOffset;
	float delta2 = (h2 - h0) * invOffset;

	float height = max(delta1 * -delta2 * 96.0, 0.0);

	return height;
}