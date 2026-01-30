#ifndef NETHER
//GGX area light approximation from Horizon Zero Dawn
// Optimized: Reduced redundant calculations and cached intermediate values
float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL) {
    // Optimized: Use inversesqrt which is faster on most GPUs
    float radiusTanSqr = radiusTan * radiusTan;
    float radiusCos = inversesqrt(1.0 + radiusTanSqr);

    float RoL = 2.0 * NoL * NoV - VoL;
    if (radiusCos <= RoL) return 1.0;

    // Optimized: Cache common subexpressions
    float RoLSqr = RoL * RoL;
    float oneMinusRoLSqr = 1.0 - RoLSqr;
    float rOverLengthT = radiusCos * radiusTan * inversesqrt(max(oneMinusRoLSqr, 0.0001));

    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float NoVSqr = NoV * NoV;
    float VoTr = rOverLengthT * (2.0 * NoVSqr - 1.0 - RoL * VoL);

    // Optimized: Cache squared terms
    float NoLSqr = NoL * NoL;
    float VoLSqr = VoL * VoL;
    float tripleArg = 1.0 - NoLSqr - NoVSqr - VoLSqr + 2.0 * NoL * NoV * VoL;
    float triple = sqrt(clamp(tripleArg, 0.0, 1.0));

    float NoBr = rOverLengthT * triple;
    float VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr;
    float VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr;
    float q = NoLVTr * VoLVTr;
    float s = VoBr * NoLVTr;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * (s - 2.0 * p) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;

    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

// Optimized: Inline-friendly with cached roughnessSqr
float GGXTrowbridgeReitz(float NoHsqr, float roughness){
    float roughnessSqr = roughness * roughness;
    float distr = NoHsqr * (roughnessSqr - 1.0) + 1.0;
    float distrSqr = distr * distr;

    // Optimized: Multiply by inverse PI instead of dividing
    return roughnessSqr * (1.0 / PI) / distrSqr;
}

// Optimized: Combined division for better instruction scheduling
float SchlickGGX(float NoL, float NoV, float roughness){
    float k = roughness * 0.5;
    float oneMinusK = 1.0 - k;

    // Optimized: Single division at the end
    float denomL = NoL * oneMinusK + k;
    float denomV = NoV * oneMinusK + k;

    return 0.25 / (denomL * denomV);
}

// Optimized: exp2 is faster than exp on most GPUs (already using it)
vec3 SphericalGaussianFresnel(float HoL, vec3 baseReflectance){
    float fresnel = exp2(((-5.55473 * HoL) - 6.98316) * HoL);

    return fresnel * (1.0 - baseReflectance) + baseReflectance;
}

// Optimized: Reduced redundant operations and improved early-outs
vec3 GGX(vec3 normal, vec3 viewPos, float smoothness, vec3 baseReflectance, float sunSize) {
    float roughness = max(1.0 - smoothness, 0.025);
          roughness *= roughness;
    vec3 negViewPos = -viewPos;

    #ifdef OVERWORLD
    vec3 lightDir = lightVec;
    #else
    vec3 lightDir = sunVec;
    #endif

    // Optimized: Combine normalize with addition
    vec3 halfVec = normalize(lightDir + negViewPos);

    float HoL = clamp(dot(halfVec, lightDir), 0.0, 1.0);
    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    float NoV = dot(normal, negViewPos);
    float VoL = dot(lightDir, negViewPos);

    float NoHsqr = getNoHSquared(sunSize, NoL, max(NoV, 0.0), VoL);
    if (NoV < 0.0){
        float NoH = dot(normal, halfVec);
        NoHsqr = NoH * NoH;
    }
    NoV = max(NoV, 0.0);

    float D = GGXTrowbridgeReitz(NoHsqr, roughness);
    vec3  F = SphericalGaussianFresnel(HoL, baseReflectance);
    float G = SchlickGGX(NoL, NoV, roughness);

    // Optimized: Use dot product for length squared, then sqrt
    float FlSqr = dot(F, F);
    float Fl = max(sqrt(FlSqr), 0.001);
    vec3  Fn = F * (1.0 / Fl);

    float specular = D * Fl * G;
    // Optimized: Pre-computed constant (0.03125 / 4.0 = 0.0078125)
    vec3 specular3 = specular / (1.0 + 0.0078125 * specular) * Fn * NoL;

    float roughnessSqr = roughness * roughness;
    return specular3 * (1.0 - roughnessSqr);
}

vec3 getSpecularHighlight(vec3 normal, vec3 viewPos, float smoothness, vec3 baseReflectance,
                          vec3 specularColor, vec3 shadow, float smoothLighting) {
    // Optimized: Early exit with combined conditions using dot product
    float shadowMag = dot(shadow, shadow);
    if (shadowMag < 0.001 || smoothness < 0.05) return vec3(0.0);

    float smoothLightingSqr = smoothLighting * smoothLighting;

    // Optimized: Pass normalized viewPos directly, avoid double normalize
    vec3 nViewPos = viewPos * inversesqrt(dot(viewPos, viewPos));

    #ifdef OVERWORLD
    vec3 specular = GGX(normal, nViewPos, smoothness, baseReflectance, 0.040);
         specular *= shadow * (shadowFade * smoothLightingSqr * (1.0 - wetness));
    #else
    vec3 specular = GGX(normal, nViewPos, smoothness, baseReflectance, 0.150);
         specular *= shadow * smoothLightingSqr;
    #endif

    return specular * specularColor;
}
#endif