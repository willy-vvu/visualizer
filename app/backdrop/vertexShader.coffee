module.exports = """
#define HEX_SIDE 16.0
#define SQRT3 1.7320508075688772
#define HEX_Y SQRT3/2.0
#define HEX_X 0.25
#define HEX_2X 0.5
#define UPPER
#define AUDIO_DATA_LENGTH 4
varying float diffuse;
varying float ao;
varying float aoMask;
varying vec3 side;
uniform float time;
uniform float currentScroll;
uniform float concavity;
uniform float audioData[AUDIO_DATA_LENGTH];
float currentScrollOffset = currentScroll * 7.0;
float pseudoChiSquared(float x){
  return x/(x*x+1.0);
}
float getProgression(float time, vec2 coord){
  return clamp(3.0*(2.0*time-0.14*length(coord)),0.0,1.0);
}
float rippleFactor(float time, vec2 coord){
  float progression = getProgression(time,coord);
  return max(5.0*(1.0-time),1.0)*pseudoChiSquared(10.0*progression);
}
float getAudioData(int index){
  return audioData[index];
}
float getHeight(vec2 coord){
  coord.y-=SQRT3*floor(currentScrollOffset/SQRT3);

  float contentFactor = clamp(5.0*(-coord.y*0.125-1.0+currentScroll*1.0),0.0,1.0);

  float ripple = time<2.0?rippleFactor(time*0.5,coord):0.0;
  float audioRipple = 0.0;
  if(time>2.0){
    float index = length(coord)*float(AUDIO_DATA_LENGTH)/12.0;
    index *= index;
    float audioDataLeft = 0.0;
    float audioDataRight = 0.0;
    int indexLeft = int(floor(index));
    if(indexLeft < AUDIO_DATA_LENGTH){
      audioDataLeft = getAudioData(indexLeft);
    }
    int indexRight = int(ceil(index));
    if(indexRight < AUDIO_DATA_LENGTH){
      audioDataRight = getAudioData(indexRight);
    }
    float indexFactor = mod(index,1.0);
    if(indexFactor<0.5){
      indexFactor = 0.2*indexFactor;
    }
    else{
      indexFactor = 1.0-0.2*(1.0-indexFactor);
    }
    audioRipple+=(1.0-indexFactor)*audioDataLeft+indexFactor*audioDataRight;
  }

  float concavityFactor = time<4.0?clamp(concavity-min(1.0-0.5*(time-2.0),1.0),0.0,1.0):concavity;
  return (1.0-contentFactor)*(ripple-audioRipple*(1.0-concavity)+min(0.05*dot(coord,coord)-3.0,0.0)*getProgression(concavityFactor,coord));

/**min(0.05*dot(coord,coord)-3.0*concavityFactor,0.0)*/
}
void main(){
  float order = floor(position.z / 7.0);
  float id = mod(position.z, 7.0);

  float row = floor(order / HEX_SIDE);

  vec2 coord = vec2(
    float(mod(order, HEX_SIDE)) + 0.5*mod(row,2.0)
      -7.5,
    0.5*SQRT3 * row
      -7.0
  );/*TODO: Adjust Center*/

  float currentHeight = getHeight(coord);
  float aoHeightDiff = 0.0;
  side = vec3(0.0, 0.0, 0.0);
  float upperLeft=getHeight(coord+vec2(-HEX_X,HEX_Y)),
      upperRight=getHeight(coord+vec2(HEX_X,HEX_Y)),
      right=getHeight(coord+vec2(HEX_2X,0.0)),
      lowerRight=getHeight(coord+vec2(HEX_X,-HEX_Y)),
      lowerLeft=getHeight(coord+vec2(-HEX_X,-HEX_Y)),
      left=getHeight(coord+vec2(-HEX_2X,0.0));
  if(id < 0.5){
  }
  else if(id < 1.5){
    side.x = 1.0;
    aoHeightDiff =
      max(upperLeft,upperRight)-currentHeight;
  }
  else if(id < 2.5){
    side.y = 1.0;
    aoHeightDiff =
      max(upperRight,right)-currentHeight;
  }
  else if(id < 3.5){
    side.z = 1.0;
    aoHeightDiff =
      max(right,lowerRight)-currentHeight;
  }
  else if(id < 4.5){
    side.x = 1.0;
    aoHeightDiff =
      max(lowerRight,lowerLeft)-currentHeight;
  }
  else if(id < 5.5){
    side.y = 1.0;
    aoHeightDiff =
      max(lowerLeft,left)-currentHeight;
  }
  else{
    side.z = 1.0;
    aoHeightDiff =
      max(left,upperRight)-currentHeight;
  }
  if(aoHeightDiff<0.0){
    ao = -5.0;
  }
  else{
    ao = min(4.0*aoHeightDiff,1.0);
  }

  if(id < 0.5){
    diffuse = 1000000.0;
    aoMask = -9.0;
  }
  else {
    diffuse = abs(upperLeft-currentHeight)<0.01&&abs(upperRight-currentHeight)<0.01&&abs(right-currentHeight)<0.01&&abs(lowerRight-currentHeight)<0.01&&abs(lowerLeft-currentHeight)<0.01&&abs(left-currentHeight)<0.01?1000000.:0.;
    aoMask = 1.0;
  }

  vec3 pos = position;
  pos.z=currentHeight;
  pos.y=pos.y+mod(currentScrollOffset,SQRT3);
  vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );
  gl_Position = projectionMatrix * mvPosition;
}
"""
