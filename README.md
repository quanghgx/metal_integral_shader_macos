# Metal Integral Shader on Mac OS
Metal shader for image integral on MacOS (swift 3 and not depend on Metal Performance Shader - MPS)

Based on christopherhelf work https://github.com/christopherhelf/IntegralImage-iOS-Metal with some modifications:
 * Not depend on Metal Performance Shader
 * Running on Mac OS instead of iOS. (just a minor tweak)

# Test result
`[MTLDevice.description] name = Intel(R) SKL Unknown`
`Theoretical FPS 720p: 120.722·`
`Theoretical FPS 1080p: 91.2149·`

# References:
 * **Original** work of christopherhelf https://github.com/christopherhelf/IntegralImage-iOS-Metal
 * NVidia's GPU GEM 3 book (Chapter 39): https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch39.html
 * alexdemartos ViolaAndJones framework: https://github.com/alexdemartos/ViolaAndJones (in file: https://github.com/alexdemartos/ViolaAndJones/blob/master/src/main.cpp)

Hanoi, July 2017
