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
uniform float kCoeff, kCube, kOverflow, uShift, vShift;
uniform float chroma_red, chroma_green, chroma_blue;
uniform bool apply_disto;

// Uniform inputs
uniform sampler2D input1;
uniform float adsk_input1_w, adsk_input1_h, adsk_input1_aspect, adsk_input1_frameratio;
uniform float adsk_result_w, adsk_result_h;

float distortion_f(float r) {
    float f = 1 + (r*r)*(kCoeff + kCube * r);
    return f;
}


float inverse_f(float r)
{
    
    // Build a lookup table on the radius, as a fixed-size table.
    // We will use a vec3 since we will store the multipled number in the Z coordinate.
    // So to recap: x will be the radius, y will be the f(x) distortion, and Z will be x * y;
    vec3[32] lut;
    
    // Since out LUT is shader-global check if it's been computed alrite
    // Flame has no overflow bbox so we can safely max out at the image edge, plus some cushion
    float max_r = sqrt((adsk_input1_frameratio * adsk_input1_frameratio) + 1) + 0.5;
    float incr = max_r / 32;
    float lut_r = 0;
    float f;
    for(int i=0; i < 32; i++) {
        f = distortion_f(lut_r);
        lut[i] = vec3(lut_r, f, lut_r * f);
        lut_r += incr;
    }
    
    float df;
    float dr;
    float t;
    
    // Now find the nehgbouring elements
    for(int i=0; i < 32; i++) {
        if(lut[i].z > r && lut[i-1].z < r) {
            // found!
            df = lut[i+1].y - lut[i].y;
            dr = lut[i+1].z - lut[i].z;
            t = (r - lut[i].z) / dr;
            return lut[i].y + (df * t);
        }
    }
}

void main(void)
{
   vec2 px, uv;
   float f = 1;
   float r = 1;
   
   px = gl_FragCoord.xy;
   
   // Make sure we are still centered
   px.x -= (adsk_result_w - adsk_input1_w) / 2;
   px.y -= (adsk_result_h - adsk_input1_h) / 2;
   
   // Push the destination coordinates into the [0..1] range
   uv.x = px.x / adsk_input1_w;
   uv.y = px.y / adsk_input1_h;
   
       
   // And to Syntheyes UV which are [1..-1] on both X and Y
   uv.x = (uv.x *2 ) - 1;
   uv.y = (uv.y *2 ) - 1;
   
   // Add UV shifts
   uv.x += uShift;
   uv.y += vShift;
   
   // Make the X value the aspect value
   uv.x = uv.x * adsk_input1_frameratio;

   // If we are redistorting, account for the plate oversize
   if(apply_disto) {
       uv.x = uv.x / kOverflow;
       uv.y = uv.y / kOverflow;
   }
   
   // Compute the radius
   r = sqrt(uv.x*uv.x + uv.y*uv.y);
   
   
   vec2[3] rgb_uvs;
   
   // Apply or remove disto, per channel honoring chromatic aberration
   if(apply_disto) {
       f = inverse_f(r);
       rgb_uvs[0].x = uv.x / (f + chroma_red);
       rgb_uvs[0].y = uv.y / (f + chroma_red);
       rgb_uvs[1].x = uv.x / (f + chroma_green);
       rgb_uvs[1].y = uv.y / (f + chroma_green);
       rgb_uvs[2].x = uv.x / (f + chroma_blue);
       rgb_uvs[2].y = uv.y / (f + chroma_blue);
   } else {
       f = distortion_f(r);
       rgb_uvs[0].x = uv.x * (f + chroma_red);
       rgb_uvs[0].y = uv.y * (f + chroma_red);
       rgb_uvs[1].x = uv.x * (f + chroma_green);
       rgb_uvs[1].y = uv.y * (f + chroma_green);
       rgb_uvs[2].x = uv.x * (f + chroma_blue);
       rgb_uvs[2].y = uv.y * (f + chroma_blue);
   }
   
   // Convert all the UVs back to the texture space, per color component
   for(int i=0; i < 3; i++) {
       uv = rgb_uvs[i];
       
       // Back from [-aspect..aspect] to [-1..1]
       uv.x = uv.x / adsk_input1_frameratio;
       
       // Remove UV shifts
       uv.x -= uShift;
       uv.y -= vShift;
       
       // Back to OGL UV
       uv.x = (uv.x + 1) / 2;
       uv.y = (uv.y + 1) / 2;
       
       rgb_uvs[i] = uv;
   }
   
   // Sample the input plate, per component
   vec4 sampled;
   sampled.r = texture2D(input1, rgb_uvs[0]).r;
   sampled.g = texture2D(input1, rgb_uvs[1]).g;
   sampled.b = texture2D(input1, rgb_uvs[2]).b;
   
   // and assign to the output
   gl_FragColor.rgba = vec4(sampled.rgb, 1.0 );
}