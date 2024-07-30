//godot things
uniform int iFrame = 0; //TODO: set

// Spatial resolution of cascade 0
const ivec2 c_sRes = ivec2(256, 128);
// Number of directions in cascade 0
const int c_dRes = 16;
// Number of cascades all together
const int nCascades = 6;
// Length of ray interval for cascade 0 (measured in pixels)
const float c_intervalLength = 7.0;
// Length of transition area between cascade 0 and cascade 1
const float c_smoothDistScale = 10.0;

// Brush radius used for drawing, measured as fraction of iResolution.y
const float brushRadius = 0.02;

const float MAX_FLOAT = 3.402823466e+38;
const float MAGIC = 1e25;

const vec2 screenRes = vec2(1024, 576); //TODO: fixme!

vec4 cubemapFetch(sampler2D sampler, ivec2 P) {
	// Look up a single texel in a cubemap
	ivec2 cubemapRes = textureSize(sampler, 0);
	if (clamp(P, ivec2(0), cubemapRes - 1) != P ) {
		return vec4(0.0);
	}
	return textureLod(sampler, (vec2(P)+.5)/vec2(cubemapRes),0);
}

//vec4 cascadeFetch(samplerCube cascadeTex, int n, ivec2 p, int d) {
vec4 cascadeFetch(sampler2D cascadeTex, int n, ivec2 p, int d) {
    // Look up the radiance interval at position p in direction d of cascade n
    ivec2 cubemapRes = ivec2(1024,1024);
    int cn_offset = n > 0
        ? c_sRes.x * c_sRes.y + (c_sRes.x * c_sRes.y * c_dRes * (n - 1)) / 4
        : 0;
    int cn_dRes = n == 0 ? 1 : c_dRes << 2 * (n - 1);
    ivec2 cn_sRes = c_sRes >> n;
    p = clamp(p, ivec2(0), cn_sRes - 1);
    int i = cn_offset + d + cn_dRes * (p.x + cn_sRes.x * p.y);
    int x = i % cubemapRes.x;
    i /= cubemapRes.x;
    int y = i % cubemapRes.y;
    i /= cubemapRes.y;
	//debugging return vec4(vec2(float(x)/1024.,float(y)/64.), 0., 1.);
    return cubemapFetch(cascadeTex, ivec2(x, y));
}

vec4 sampleDrawing(sampler2D drawingTex, vec2 P) {
	// Return the drawing (in the format listed at the top of Buffer B) at P
	vec4 data = texture(drawingTex, P / vec2(textureSize(drawingTex, 0)));
	data.a = 0.; //because alpha is not imported by godot or exported by shadertoy

	return data;
}

float sdDrawing(sampler2D drawingTex, vec2 P) {
	// Return the signed distance for the drawing at P
	return sampleDrawing(drawingTex, P).r;
}
