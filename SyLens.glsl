#version 120

/*
  Original Lens Distortion Algorithm from SSontech (Syntheyes)
  http://www.ssontech.com/content/lensalg.htm
  
  r2 = image_aspect*image_aspect*u*u + v*v
  f = 1 + r2*(k + kcube*sqrt(r2))
  u' = f*u
  v' = f*v

*/

uniform sampler2D input1;
uniform float adsk_input1_w, adsk_input1_h, adsk_input1_aspect;
uniform float kCoeff, kCube;
uniform float adsk_result_w, adsk_result_h;

float distoF(float r) {
  float f;
  float r2 = r * r;
  // Skipping the square root speeds up things
  f = 1 + r2*(kCoeff + kCube * sqrt(r2));
  return f;
}

void main(void)
{
   vec2 uv;
   float f, r;
   
   // Get the pixel coordiante in the input
   uv.x = gl_FragCoord.xy.x / adsk_input1_w;
   uv.y = gl_FragCoord.xy.y / adsk_input1_h;
   
   uv -= 0.5;
   r = sqrt((uv.x*uv.x) +  (uv.y * uv.y * adsk_input1_aspect * adsk_input1_aspect));
   
   // Build a lookup table on the radius, as a fixed-size table.
   // We will use a vec3 since we will store the multipled number in the Z coordinate.
   // So to recap: x will be the radius, y will be the f(x) distortion, and Z will be x * y;
   vec3[32] lut;
   float lut_r = 0;
   
   // Flame has no overflow bbox so we can safely max out at the image edge, plus some cushion
   float max_r = sqrt((adsk_input1_aspect * adsk_input1_aspect) + 1) + 0.1;
   float incr = max_r / 32;
   for(int i=0; i < 32; i++) {
       f = distoF(lut_r);
       lut[i] = vec3(lut_r, f, lut_r * f);
       lut_r += incr;
   }
   
   // Now find the nehgbouring elements
   int left_i = 0;
   int right_i = 0;
   for(int i=0; i < 32; i++) {
       if(lut[i].z > r && left_i == 0 && right_i == 0) {
           left_i = i;
           right_i = i +1;
       }
   }

   // Interpolate for the right F between those found vectors
   float t = (r - lut[left_i].z) / (lut[right_i].z - lut[left_i].z);
   f = (lut[right_i].y - lut[left_i].y) * t;
   uv = uv / f;
   
   uv += 0.5;
   
   vec4 tex0 = texture2D(input1, uv);
   gl_FragColor.rgba = vec4(tex0.rgb, 1.0 );
}