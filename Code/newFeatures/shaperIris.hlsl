float sCurve(float f){
	const float exp = -4;
	f = saturate(f);
	return 1 / (1 + pow((f / (1.125 - f)), exp));
}

void rotateUV(float2 texCoor, float rads, out float x, out float y) {
	x = cos(rads) * (texCoor.x - 0.5) + sin(rads) * (texCoor.y - 0.5) + 0.5;
	y = sin(rads) * (texCoor.x - 0.5) - cos(rads) * (texCoor.y - 0.5) + 0.5;
}

float mapLineValue(float passed, float d, float frost, float frostMultiplier){
	float max = (0.05 * frost + 0.002) * frostMultiplier; /*0.04-0.002 Hardcoded blur value*/
	float clamp = d > max;
	d = clamp + (1 - clamp) * (d / max);

	return sCurve((passed * 2 - 1) * (d / 2) + 0.5);
}

float sampleIris(float2 texCoor, float irisVal, float frost) {
	/*irisVal = 1 - irisVal;*/
	const float x = texCoor.x * 2 - 1, y = texCoor.y * 2 - 1;
	float dist = x * x + y * y;
	/*dist = sqrt(dist);*/
	float d = abs(dist - irisVal);
	const float frostMulActivation = 0.15;
	float frostMulEnabled = irisVal >= frostMulActivation;
	float frostMul = frostMulEnabled + (1 - frostMulEnabled) * irisVal * (1 / frostMulActivation);
	float passed = dist <= irisVal;
	return mapLineValue(passed, d, frost, frostMul);
}

float sampleBladeAB(float2 texCoor, float a, float b, float orientationRads, float frost){
	float x, y;
	rotateUV(texCoor, orientationRads, x, y);
	float m = b - a;
	float eq = (x * m) + a;
	float d = abs(y - eq) /*/ sqrt(1 + m * m)*/;
	float passed = y > eq;
	return mapLineValue(passed, d, frost, 1);
}
float sampleBladeARot(float2 texCoor, float a, float rotRads, float orientationRads, float frost){
	float x, y;
	rotateUV(texCoor, orientationRads, x, y);
	float m = rotRads * x;
	float eq = m - (rotRads * 0.5) + a;
	float d = abs(y - eq) /*/ sqrt(1 + m * m)*/;
	float passed = y > eq;
	return mapLineValue(passed, d, frost, 1);
}