# unity-fragment-sorted-transparency

Full fragment-sorted-transparency implementation using compute buffers and shaders to mitigate the typical drawbacks of mesh-sorted transparency, such as object pop-in and lack of mesh penetration. 

### Use
TODO

### TODO
#### Basic Features
- [ ] Support the rendering in the editor view, or at least a helper visualization
- [ ] Add a custom Amplify Shader Editor shader main
- [ ] Test against depth when first drawing to optimize
- [ ] Minimize memory usage 

#### Extras
- [ ] Store the facing direction in the fragment and scale the opacity based on volume / depth delta
- [ ] Provide visualization for heavily overlapped pixels
- [ ] Store both the volume color and surface color in a fragment so it can be handled separately
- [ ] Cast colored "shadows" from transparent objects
- [ ] Add lower resolution support
- [ ] Anti aliasing
