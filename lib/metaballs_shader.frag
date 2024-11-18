#version 320 es

#include <flutter/runtime_effect.glsl>

precision highp float;

layout(location = 0) out vec4 fragColor;

// define uniforms:
layout(location = 0) uniform float time;
layout(location = 1) uniform float minimumGlowSum;
layout(location = 2) uniform float glowIntensity;
layout(location = 3) uniform float metaballs;

// Why are these defined seperatly? Because when using a vec3[138] the shader when loading in throws
// "Not a supported op". The only place i've seen arrays being using in the flutter engine is in
// https://github.com/flutter/engine/blob/main/lib/ui/fixtures/shaders/general_shaders/uniform_arrays.frag
// but here opengl #version 100 core is used which is not supported by the shader package compiler
// if you know a fix to this issue feel free to make a pr
layout(location = 4) uniform vec3 metaball1;
layout(location = 5) uniform vec3 metaball2;
layout(location = 6) uniform vec3 metaball3;
layout(location = 7) uniform vec3 metaball4;
layout(location = 8) uniform vec3 metaball5;
layout(location = 9) uniform vec3 metaball6;
layout(location = 10) uniform vec3 metaball7;
layout(location = 11) uniform vec3 metaball8;
layout(location = 12) uniform vec3 metaball9;
layout(location = 13) uniform vec3 metaball10;
layout(location = 14) uniform vec3 metaball11;
layout(location = 15) uniform vec3 metaball12;
layout(location = 16) uniform vec3 metaball13;
layout(location = 17) uniform vec3 metaball14;
layout(location = 18) uniform vec3 metaball15;
layout(location = 19) uniform vec3 metaball16;
layout(location = 20) uniform vec3 metaball17;
layout(location = 21) uniform vec3 metaball18;
layout(location = 22) uniform vec3 metaball19;
layout(location = 23) uniform vec3 metaball20;
layout(location = 24) uniform vec3 metaball21;
layout(location = 25) uniform vec3 metaball22;
layout(location = 26) uniform vec3 metaball23;
layout(location = 27) uniform vec3 metaball24;
layout(location = 28) uniform vec3 metaball25;
layout(location = 29) uniform vec3 metaball26;
layout(location = 30) uniform vec3 metaball27;

float addSum(vec3 metaball, vec2 coords) {
  float dx = metaball.x - coords.x;
  float dy = metaball.y - coords.y;
  float radius = metaball.z;
  return ((radius * radius) / (dx * dx + dy * dy));
}

vec4 noise(vec4 v){
  // ensure reasonable range
  v = fract(v) + fract(v*1e4) + fract(v*1e-4);
  // seed
  v += vec4(0.12345, 0.6789, 0.314159, 0.271828);
  // more iterations => more random
  v = fract(v*dot(v, v)*123.456);
  v = fract(v*dot(v, v)*123.456);
  return v;
}

float getSum(vec2 coords) {
  float sum = 0.0;
  if(metaballs < 1.0) return sum;
  sum += addSum(metaball1, coords);
  if(metaballs < 2.0) return sum;
  sum += addSum(metaball2, coords);
  if(metaballs < 3.0) return sum;
  sum += addSum(metaball3, coords);
  if(metaballs < 4.0) return sum;
  sum += addSum(metaball4, coords);
  if(metaballs < 5.0) return sum;
  sum += addSum(metaball5, coords);
  if(metaballs < 6.0) return sum;
  sum += addSum(metaball6, coords);
  if(metaballs < 7.0) return sum;
  sum += addSum(metaball7, coords);
  if(metaballs < 8.0) return sum;
  sum += addSum(metaball8, coords);
  if(metaballs < 9.0) return sum;
  sum += addSum(metaball9, coords);
  if(metaballs < 10.0) return sum;
  sum += addSum(metaball10, coords);
  if(metaballs < 11.0) return sum;
  sum += addSum(metaball11, coords);
  if(metaballs < 12.0) return sum;
  sum += addSum(metaball12, coords);
  if(metaballs < 13.0) return sum;
  sum += addSum(metaball13, coords);
  if(metaballs < 14.0) return sum;
  sum += addSum(metaball14, coords);
  if(metaballs < 15.0) return sum;
  sum += addSum(metaball15, coords);
  if(metaballs < 16.0) return sum;
  sum += addSum(metaball16, coords);
  if(metaballs < 17.0) return sum;
  sum += addSum(metaball17, coords);
  if(metaballs < 18.0) return sum;
  sum += addSum(metaball18, coords);
  if(metaballs < 19.0) return sum;
  sum += addSum(metaball19, coords);
  if(metaballs < 20.0) return sum;
  sum += addSum(metaball20, coords);
  if(metaballs < 21.0) return sum;
  sum += addSum(metaball21, coords);
  if(metaballs < 22.0) return sum;
  sum += addSum(metaball22, coords);
  if(metaballs < 23.0) return sum;
  sum += addSum(metaball23, coords);
  if(metaballs < 24.0) return sum;
  sum += addSum(metaball24, coords);
  if(metaballs < 25.0) return sum;
  sum += addSum(metaball25, coords);
  if(metaballs < 26.0) return sum;
  sum += addSum(metaball26, coords);
  if(metaballs < 27.0) return sum;
  sum += addSum(metaball27, coords);
  return sum;
}

void main(){
  vec2 coords = FlutterFragCoord().xy;
  float sum = getSum(coords);

  if(sum >= 1.0) {
    fragColor = vec4(1,1,1,1);
  } else if(sum > minimumGlowSum) {
    float n = ((sum - minimumGlowSum) / (1.0 - minimumGlowSum)) * glowIntensity;
    
    fragColor = vec4(n) + ((noise(vec4(coords, time, 0.0)) - 0.5) / 255.0);
  } else {
    fragColor = vec4(0, 0, 0, 0);
  }
}