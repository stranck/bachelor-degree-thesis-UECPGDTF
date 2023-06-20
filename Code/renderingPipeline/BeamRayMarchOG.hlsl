float traversalDepth = FDepth - NDepth ;
uint numSteps = floor(traversalDepth / StepSize) ;
float3 posOffset = normalize(FSlice-NSlice) * StepSize ;
float Adj = AdjOpp.x;
float Opp = AdjOpp.y + ConeRadius;

float3 cumul = 0;
for(uint i=0; i<numSteps; i++){

	///Position & depth at rayHit
	float3 pos = NSlice + posOffset * i ;
	float depth = NDepth + StepSize * i ;
	float dist = length(pos);
	float falloff = 1.0f-(dist/MaxDistance);

	///Domain Transform
	pos.z = -pos.z;
	pos /= float3(Opp*2,Opp*2,Adj);
	float div = ConeRadius / Opp;
	div = (pos.z*(1-div))+div;
	pos.xy /= div;
		
	//Center domain
	pos.z -= 0.5 ;
	///Clip domain edges.
	float maskX = (1-abs(pos.x)) > 0.5 ;
	float maskY = (1-abs(pos.y)) > 0.5 ;
	float maskZ = (1-abs(pos.z)) > 0.5 ;
	if( (maskX*maskY*maskZ) - 0.5 < 0 ) continue ;
	///Soft clipping with scene depth.
	float dClip = saturate((ScDepth-depth)/SoftClipSize);

	// UVs from pos
	pos.xy = saturate(pos.xy+0.5);
	float2 ColorUV = pos.xy;

	float2 texCoor = pos.xy;
	float scale = 1 / NumGobos;
	float offset = GoboIndex / NumGobos;
	texCoor.x = texCoor.x * scale + offset;
	float GoboSample =
      TXTpGobo.SampleLevel(TXTpGoboSampler, texCoor, 0);
	//GoboSample = TestGobo;
	// Color Wheel scale offset
	ColorUV.x = ColorUV.x / NumColors;
	ColorUV.x = ColorUV.x  + (ColorIndex/NumColors) ;
	// Sample Color Wheel
	float3 ColorSample =
      TXTpColor.SampleLevel(TXTpColorSampler,ColorUV.xy,0) ;
	
	// Add DMXColor in
	ColorSample = ColorSample * DMXColor;
	// InvSqr falloff function
	float invsqr = 1.0f / (dist*dist);
	///Add to Result
	cumul+=(1.f/numSteps)*GoboSample*ColorSample*dClip*invsqr*falloff;
}
return cumul ;