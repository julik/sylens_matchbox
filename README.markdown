## Basics

This shader will undistort and redistort footage according to the Syntheyes model. It's called SyLens after it's more
powerful cousin, [SyLens for Nuke.](http://github.com/julik/sylens)

## Installation

To use it, copy the .glsl, the .glsl.p and the .xml files somewhere where your Flame/Smoke system
can access them. The default location of all the stock Matchbox shaders is `/usr/discreet/<version>/matchbox`,
so for example for Flame 2013 it will be `/usr/discreet/flame_2013/matchbox`. Once the shader is there, load it into Matchbox.
Afterwards, dial in the parameters computed in Syntheyes to apply or remove distortion (the default is "remove").

## Dealing with overscan when removing distortion

When you are undistorting images it sometimes produces oversize images. By default the overflow pixels will be
simply cropped away, however if you expand the **Output Size** of your shader, you will see that the output
will still be centered in your canvas. So, to recover the overflow pixels, expand your output until all the pixels are
covered.

Remember that the undistorted plate will always have the same aspect ratio as the original.

## Dealing with overscan when applying distortion

When applying distortion the reverse process must be observed - you want to get a redistorted image that has the same
size as your original distorted source. To achieve this, feed the shader an oversize plate as input and 
simply **reduce** your **Output Size** in the settings. The shader will compute all the needed parameters
and your output will match the distorted source.

## Use in setups

Do not worry about always using the latest version of the shader - the shader you use will actually be **copied** to your setup
so there is no problem versioning it.

## License

    Copyright (c) 2012 Julik Tarkhanov
    
    	Permission is hereby granted, free of charge, to any person obtaining
    	a copy of this software and associated documentation files (the
    	"Software"), to deal in the Software without restriction, including
    	without limitation the rights to use, copy, modify, merge, publish,
    	distribute, sublicense, and/or sell copies of the Software, and to
    	permit persons to whom the Software is furnished to do so, subject to
    	the following conditions:
    
    	The above copyright notice and this permission notice shall be
    	included in all copies or substantial portions of the Software.
    
    	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.