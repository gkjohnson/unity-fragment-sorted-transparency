# unity-fragment-sorted-transparency

Full fragment-sorted-transparency implementation using compute buffers and shaders to mitigate the typical drawbacks of mesh-sorted transparency, such as object pop-in and lack of mesh penetration. 

### Use
TODO

### TODO
#### Basic Features
- [ ] Test against the light(s) for sub surface scattering
- [ ] Refraction
- [ ] Separate shader logic into cginc files
- [ ] Test against depth when first drawing to optimize
- [ ] Minimize memory usage
- [ ] Figure out what to do at volume overlap

#### Extras
- [ ] Cast colored "shadows" from transparent objects
- [ ] Add lower resolution support
- [ ] Anti aliasing
- [ ] Save material-level qualities in a different buffer (fill color, index of refraction / diffusion)
- [ ] Shader feature options
- [ ] Refracted shadows
