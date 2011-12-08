/*
  Original Lens Distortion Algorithm from SSontech (Syntheyes)
  http://www.ssontech.com/content/lensalg.htm
  
  r2 = image_aspect*image_aspect*u*u + v*v
  f = 1 + r2*(k + kcube*sqrt(r2))
  u' = f*u
  v' = f*v

*/

uniform sampler2D input1;
uniform float adsk_input1_w, adsk_input1_h, adsk_input1_frameratio;
uniform float kCoeff, kCube;
uniform float adsk_result_w, adsk_result_h;
uniform bool doRedisto;

vec2 redisto(vec2 pt) {
  float r, rp, f, rlim, rplim, raw, err, slope;
  vec2 res;
  
  rp = sqrt(adsk_input1_frameratio * adsk_input1_frameratio * pt.x * pt.x + pt.y * pt.y);
  if (kCoeff < 0.0) {
    rlim = sqrt((-1.0/3.0) / kCoeff);
    rplim = rlim * (1.0 + kCoeff*rlim*rlim);
    if (rp >= 0.99 * rplim) {
      f = rlim / rp;
      return pt * f;
    }
  }

  r = rp;
  for (int i = 0; i < 20; i++) {
    raw = kCoeff * r * r;
    slope = 1 + 3.0*raw;
    err = rp - r * (1.0 + raw);
    if (abs(err) < 0.00001) break;
    r += (err / slope);
  }
  f = r / rp;
  
  return pt * f;
}

vec2 undisto(vec2 pt) {
  // We compute the distortion based on the radius off the center, squared.
  // Therefore R2.
  float r2, f;
  f = adsk_input1_frameratio * adsk_input1_frameratio * pt.x * pt.x + pt.y * pt.y;
  // Skipping the square root speeds up things
  if (abs(kCube) > 0.00001) {
    f = 1.0 + r2*(kCoeff + kCube * sqrt(r2));
  } else {
    f = 1.0 + r2*(kCoeff);
  }
  return pt * f;
}

void main(void)
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_input1_w, adsk_input1_h);
   
   // Syntheyes operates in coordinates off-center of the image
   uv = uv - 0.5;
   if(doRedisto) {
     uv = undisto(uv);
   } else {
     uv = redisto(uv);
   }
   // Move to the lower left corner which is where the texture starts
   uv = uv + 0.5;
   
   // TODO - compensate for the changing plate size in the output w/r to the input
   
   // Perform sampling, TODO - also sample from alpha in the second input
   vec4 tex0 = texture2D(input1, uv);
   gl_FragColor.rgba = vec4(tex0.rgb, 1.0 );
}
