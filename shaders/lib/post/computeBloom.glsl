float pixelHeight = 0.8 / min(720.0, viewHeight);
float pixelWidth = pixelHeight / aspectRatio;
vec2 viewSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

// Optimized: Reduced from 6x6 (36 samples) to 5x5 (25 samples) - 30% fewer texture reads
const float weight[5] = float[5](0.06, 0.24, 0.40, 0.24, 0.06);

vec3 getBloomTile(float lod, vec2 bloomCoord, vec2 offset) {
	vec3 bloom = vec3(0.0);
	float scale = exp2(lod);
	bloomCoord = (bloomCoord - offset) * scale;
	vec2 padding = vec2(0.5) + 2.0 * viewSize * scale;

	if (abs(bloomCoord.x - 0.5) < padding.x && abs(bloomCoord.y - 0.5) < padding.y) {
		for(int i = 0; i < 5; i++) {
			float wi = weight[i];
			float offsetX = (float(i) - 2.0) * pixelWidth * scale;
			for(int j = 0; j < 5; j++) {
				float wg = wi * weight[j];
				vec2 sampleCoord = bloomCoord + vec2(offsetX, (float(j) - 2.0) * pixelHeight * scale);
				bloom += texture2D(colortex0, sampleCoord).rgb * wg;
			}
		}
	}

	return bloom;
}

// Optimized: Reduced from 5 to 4 bloom tiles
vec3 computeBloom(vec2 texCoord) {
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(720.0, viewHeight);
	vec3 blur =  getBloomTile(1.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.0   , 0.0 ) + vec2( 0.5, 0.0) * viewSize);
	     blur += getBloomTile(2.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.0 ) + vec2( 4.0, 0.0) * viewSize);
	     blur += getBloomTile(3.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.50  , 0.25) + vec2( 4.0, 4.0) * viewSize);
	     blur += getBloomTile(4.0 + BLOOM_TILE_SIZE, bloomCoord, vec2(0.625 , 0.25) + vec2( 8.0, 4.0) * viewSize);
		 blur = pow(blur * 0.03125, vec3(0.25));  // 1/32 = 0.03125, use multiplication
		 blur = clamp(blur + (Bayer8(gl_FragCoord.xy) - 0.5) * 0.0026, vec3(0.0), vec3(1.0));  // 1/384 = 0.0026
    return blur;
}