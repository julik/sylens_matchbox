#version 120

/*
  Original Lens Distortion Algorithm from SSontech (Syntheyes)
  http://www.ssontech.com/content/lensalg.htm
  
  r2 = image_aspect*image_aspect*u*u + v*v
  f = 1 + r2*(k + kcube*sqrt(r2))
  u' = f*u
  v' = f*v

*/

// Controls
uniform float kCoeff, kCube, uShift, vShift;
uniform bool apply_disto;

// Uniform inputs
uniform sampler2D input1;
uniform float adsk_input1_w, adsk_input1_h, adsk_input1_aspect;
uniform float adsk_result_w, adsk_result_h;

float distortion_f(float r) {
  float f;
  float r2 = r * r;
  f = 1 + r2*(kCoeff + kCube * sqrt(r2));
  return f;
}

float inverse_f(float r)
{
    
    // Build a lookup table on the radius, as a fixed-size table.
    // We will use a vec3 since we will store the multipled number in the Z coordinate.
    // So to recap: x will be the radius, y will be the f(x) distortion, and Z will be x * y;
    vec3[32] lut;
    
    // Flame has no overflow bbox so we can safely max out at the image edge, plus some cushion
    float max_r = sqrt((adsk_input1_aspect * adsk_input1_aspect) + 1) + 0.1;
    float incr = max_r / 32;
    float lut_r = 0;
    float f;
    for(int i=0; i < 32; i++) {
        f = distortion_f(lut_r);
        lut[i] = vec3(lut_r, f, lut_r * f);
        lut_r += incr;
    }
    
    float df;
    float dz;
    float t;
    
    // Now find the nehgbouring elements
    for(int i=0; i < 32; i++) {
        if(lut[i].z < r) {
            // found!
            df = lut[i+1].y - lut[i].y;
            dz = lut[i+1].z - lut[i].z;
            t = (r - lut[i].z) / dz;
            return df * t;
        }
    }
}

void main(void)
{
   vec2 px, uv;
   float f, r;
   
   px = gl_FragCoord.xy;
   
   // Make sure we are still centered
   px.x -= (adsk_result_w - adsk_input1_w) / 2;
   px.y -= (adsk_result_h - adsk_input1_h) / 2;
   
   // Get the pixel coordiante in the input
   uv.x = px.x / adsk_input1_w;
   uv.y = px.y / adsk_input1_h;
   
   uv -= 0.5;
   
   uv.x -= uShift;
   uv.y -= vShift;
   r = sqrt((uv.x*uv.x) +  (uv.y * uv.y * adsk_input1_aspect * adsk_input1_aspect));
   if(apply_disto){
       uv = uv * inverse_f(r);  
   } else {
       uv = uv * distortion_f(r);  
   }
   uv.x += uShift;
   uv.y += vShift;
   
   uv += 0.5;
   
   vec4 tex0 = texture2D(input1, uv);
   gl_FragColor.rgba = vec4(tex0.rgb, 1.0 );
}