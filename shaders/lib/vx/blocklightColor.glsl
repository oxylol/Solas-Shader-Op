// Optimized: Pre-normalized candle colors to avoid per-pixel normalize() calls
const vec3 CANDLE_RED = vec3(0.9950372, 0.0995037, 0.0995037);
const vec3 CANDLE_ORANGE = vec3(0.8944272, 0.4472136, 0.0894427);
const vec3 CANDLE_YELLOW = vec3(0.7043469, 0.7043469, 0.0704347);
const vec3 CANDLE_BROWN = vec3(0.7071068, 0.7071068, 0.0);
const vec3 CANDLE_GREEN = vec3(0.0995037, 0.9950372, 0.0995037);
const vec3 CANDLE_LIME = vec3(0.0, 0.9950372, 0.0995037);
const vec3 CANDLE_BLUE = vec3(0.0995037, 0.0995037, 0.9950372);
const vec3 CANDLE_LIGHT_BLUE = vec3(0.4472136, 0.4472136, 0.8944272);
const vec3 CANDLE_CYAN = vec3(0.0704347, 0.7043469, 0.7043469);
const vec3 CANDLE_PURPLE = vec3(0.5734624, 0.0819232, 0.8192319);
const vec3 CANDLE_MAGENTA = vec3(0.7043469, 0.0704347, 0.7043469);
const vec3 CANDLE_PINK = vec3(0.6666667, 0.3333333, 0.6666667);
const vec3 CANDLE_BLACK = vec3(0.5773503, 0.5773503, 0.5773503);
const vec3 CANDLE_WHITE = vec3(0.5773503, 0.5773503, 0.5773503);
const vec3 CANDLE_GRAY = vec3(0.5773503, 0.5773503, 0.5773503);
const vec3 CANDLE_LIGHT_GRAY = vec3(0.5773503, 0.5773503, 0.5773503);
const vec3 CANDLE_DEFAULT = vec3(0.6837635, 0.5698029, 0.4558423);

// Pre-normalized flower colors
const vec3 FLOWER_RED = vec3(0.9987515, 0.0499376, 0.0499376) * 0.20;
const vec3 FLOWER_PINK = vec3(0.7844645, 0.1961161, 0.5883484) * 0.40;
const vec3 FLOWER_YELLOW = vec3(0.8432740, 0.5270463, 0.0527046) * 0.20;
const vec3 FLOWER_BLUE = vec3(0.0, 0.1483240, 0.9888266) * 0.20;
const vec3 FLOWER_WHITE = vec3(0.5773503, 0.5773503, 0.5773503) * 0.20;
const vec3 FLOWER_ORANGE = vec3(0.8164966, 0.5715476, 0.0408248) * 0.20;

// Pre-normalized generic emitter colors
const vec3 EMITTER_RED = vec3(0.9987515, 0.0499376, 0.0499376) * 0.50;
const vec3 EMITTER_ORANGE = vec3(0.8164966, 0.5715476, 0.0408248) * 0.50;
const vec3 EMITTER_YELLOW = vec3(0.8432740, 0.5270463, 0.0527046) * 0.50;
const vec3 EMITTER_GREEN = vec3(0.0995037, 0.9950372, 0.0995037) * 0.50;
const vec3 EMITTER_BLUE = vec3(0.0, 0.1483240, 0.9888266) * 0.50;
const vec3 EMITTER_PURPLE = vec3(0.5734624, 0.0819232, 0.8192319) * 0.50;
const vec3 EMITTER_WHITE = vec3(0.5773503, 0.5773503, 0.5773503) * 0.50;

// Pre-normalized ore colors
const vec3 ORE_EMERALD = vec3(0.0494343, 0.9886859, 0.1483029) * 0.25;
const vec3 ORE_DIAMOND = vec3(0.0925820, 0.3703281, 0.9258201) * 0.25;
const vec3 ORE_COPPER = vec3(0.6246951, 0.7288109, 0.3123475) * 0.25;
const vec3 ORE_LAPIS = vec3(0.0, 0.0830455, 0.9965463) * 0.25;
const vec3 ORE_GOLD = vec3(0.7999999, 0.5999999, 0.0800000) * 0.25;
const vec3 ORE_IRON = vec3(0.7778175, 0.4444671, 0.3333503) * 0.25;
const vec3 ORE_REDSTONE = vec3(0.9987515, 0.0499376, 0.0) * 0.25;

vec3 getBlocklightColor(int id) {
	vec3 color = vec3(0.0);

	// Handle animated light sources first (fire flickering)
	if (id == 5 || id == 15) {
		// Torch, Lantern, Campfire, Fire
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 3.0) * 5.0 + frameTimeCounter) * 0.1);
		return pow(vec3(TLCF_R, TLCF_G, TLCF_B), fireAnimation) * TLCF_I;
	}
	if (id == 6 || id == 16) {
		// Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 2.0) * 4.0 + frameTimeCounter * 1.25) * 0.15);
		return pow(vec3(SOUL_R, SOUL_G, SOUL_B), fireAnimation) * SOUL_I;
	}

	// Use switch for common IDs (compiler can optimize to jump table)
	switch(id) {
		case 3:  return vec3(GLSP_R, GLSP_G, GLSP_B) * GLSP_I;     // Glow Lichen, Sea Pickle
		case 4:  return vec3(BS_R, BS_G, BS_B) * BS_I;              // Brewing Stand
		case 7:  return vec3(ER_R, ER_G, ER_B) * ER_I;              // End Rod
		case 8:  return vec3(SL_R, SL_G, SL_B) * SL_I;              // Sea Lantern
		case 9:  return vec3(GS_R, GS_G, GS_B) * GS_I;              // Glowstone
		case 10: return vec3(SLRL_R, SLRL_G, SLRL_B) * SLRL_I;      // Shroomlight, Redstone Lamp
		case 11: return vec3(RACO_R, RACO_G, RACO_B) * RACO_I;      // Respawn Anchor
		case 12: return vec3(LAVA_R, LAVA_G, LAVA_B + 0.02) * LAVA_I; // Lava
		case 13: return vec3(CB_R, CB_G, CB_B) * CB_I;              // Cave Berries
		case 14: return vec3(AM_R, AM_G, AM_B) * AM_I;              // Amethyst
		case 21: return vec3(MB_R, MB_G, MB_B) * MB_I;              // Magma Block
		case 29: return vec3(1.00, 0.05, 0.00) * 0.5;               // Lit Redstone Ore & Torch
		case 30: return vec3(1.00, 0.05, 0.00) * 0.5;               // Powered Rails
		case 31: return vec3(NP_R, NP_G, NP_B) * NP_I;              // Nether Portal
		case 32: return vec3(OF_R, OF_G, OF_B) * OF_I;              // Ochre Froglight
		case 33: return vec3(VF_R, VF_G, VF_B) * VF_I;              // Verdant Froglight
		case 34: return vec3(PF_R, PF_G, PF_B) * PF_I;              // Pearlescent Froglight
		case 41: return vec3(JL_R, JL_G, JL_B) * JL_I;              // Jack-O-Lantern
		case 42: return vec3(ET_R, ET_G, ET_B) * ET_I;              // Enchanting Table
		// Candles - using pre-normalized colors
		case 43: return CANDLE_RED;
		case 44: return CANDLE_ORANGE;
		case 45: return CANDLE_YELLOW;
		case 46: return CANDLE_BROWN;
		case 47: return CANDLE_GREEN;
		case 48: return CANDLE_LIME;
		case 49: return CANDLE_BLUE;
		case 50: return CANDLE_LIGHT_BLUE;
		case 51: return CANDLE_CYAN;
		case 52: return CANDLE_PURPLE;
		case 53: return CANDLE_MAGENTA;
		case 54: return CANDLE_PINK;
		case 55: return CANDLE_BLACK;
		case 56: return CANDLE_WHITE;
		case 57: return CANDLE_GRAY;
		case 58: return CANDLE_LIGHT_GRAY;
		case 59: return CANDLE_DEFAULT;
		case 60: return vec3(BC_R, BC_G, BC_B) * BC_I;              // Beacon
		case 62: return vec3(0.20, 0.55, 1.00) * 2.5;               // Sculk Sensor
		case 63: return vec3(1.00, 0.25, 0.75) * 2.5;               // Calibrated Sculk
		case 64: return vec3(1.0, 0.2, 0.1) * 0.1;                  // Fungi
		case 65: return vec3(1.0, 0.2, 0.1) * 0.2;                  // Crimson Stem
		case 66: return vec3(0.1, 0.5, 0.7) * 0.2;                  // Warped Stem
		case 69: return vec3(0.1, 0.01, 0.15);                      // Mob Spawner
		case 71: return vec3(EP_R, EP_G, EP_B) * EP_I;              // End Portal
		case 73: return vec3(1.0, 0.3, 0.1);                        // Creaking Heart
		case 80: return vec3(0.12, 0.1, 0.1);                       // Chorus
		case 81: return vec3(1.1, 0.3, 0.1) * 0.25;                 // Crimson Fungus
		case 82: return vec3(0.3, 0.6, 0.9) * 0.25;                 // Warped Fungus
		case 83: return vec3(CTL_R, CTL_G, CTL_B) * CTL_I;          // Copper Torch
		case 84: return vec3(CTL_R, CTL_G, CTL_B) * CTL_I;          // Copper Lantern
		// Generic emitters - pre-normalized
		case 194: return EMITTER_RED;
		case 195: return EMITTER_ORANGE;
		case 196: return EMITTER_YELLOW;
		case 197: return EMITTER_GREEN;
		case 198: return EMITTER_BLUE;
		case 199: return EMITTER_PURPLE;
		case 200: return EMITTER_WHITE;
	}

	// Handle conditional compilation blocks for ores
	#ifdef EMISSIVE_ORES
		#ifdef EMISSIVE_EMERALD_ORE
		if (id == 22) return ORE_EMERALD;
		#endif
		#ifdef EMISSIVE_DIAMOND_ORE
		if (id == 23) return ORE_DIAMOND;
		#endif
		#ifdef EMISSIVE_COPPER_ORE
		if (id == 24) return ORE_COPPER;
		#endif
		#ifdef EMISSIVE_LAPIS_ORE
		if (id == 25) return ORE_LAPIS;
		#endif
		#ifdef EMISSIVE_GOLD_ORE
		if (id == 26) return ORE_GOLD;
		#endif
		#ifdef EMISSIVE_IRON_ORE
		if (id == 27) return ORE_IRON;
		#endif
		#ifdef EMISSIVE_REDSTONE_ORE
		if (id == 28) return ORE_REDSTONE;
		#endif
		// Zinc Ore
		if (id == 72) return vec3(0.4);
	#endif

	// Handle conditional flower emissives
	#ifdef EMISSIVE_FLOWERS
		// Red flowers
		if (id == 35 || id == 309 || id == 310) return FLOWER_RED;
		// Pink flowers
		if (id == 36 || id == 305 || id == 306 || id == 311 || id == 312) return FLOWER_PINK;
		// Yellow flowers
		if (id == 37 || id == 307 || id == 308) return FLOWER_YELLOW;
		// Blue flowers
		if (id == 38) return FLOWER_BLUE;
		// White flowers
		if (id == 39) return FLOWER_WHITE;
		// Orange flowers
		if (id == 40) return FLOWER_ORANGE;
		// Potted flowers
		if (id == 74) return FLOWER_RED;
		if (id == 75) return FLOWER_PINK * 0.5;  // Pink potted at 0.20 vs 0.40
		if (id == 76) return FLOWER_YELLOW;
		if (id == 77) return FLOWER_BLUE;
		if (id == 78) return FLOWER_WHITE;
		if (id == 79) return FLOWER_ORANGE;
	#endif

	return color;
}

const vec3[] blocklightTintArray = vec3[](
	//Red
	vec3(1.0, 0.1, 0.1),
	//Orange
	vec3(1.0, 0.5, 0.1),
	//Yellow
	vec3(1.0, 1.0, 0.1),
	//Brown
	vec3(0.7, 0.7, 0.0),
	//Green
	vec3(0.1, 1.0, 0.1),
	//Lime
	vec3(0.1, 1.0, 0.5),
	//Blue
	vec3(0.1, 0.1, 1.0),
	//Light blue
	vec3(0.5, 0.5, 1.0),
	//Cyan
	vec3(0.1, 1.0, 1.0),
	//Purple
	vec3(0.7, 0.1, 1.0),
	//Magenta
	vec3(1.0, 0.1, 1.0),
	//Pink
	vec3(1.0, 0.5, 1.0),
	//Black
	vec3(0.1, 0.1, 0.1),
	//White
	vec3(0.9, 0.9, 0.9),
	//Gray
	vec3(0.3, 0.3, 0.3),
	//Light gray
	vec3(0.7, 0.7, 0.7),
	//Buffer
	vec3(0.0)
);