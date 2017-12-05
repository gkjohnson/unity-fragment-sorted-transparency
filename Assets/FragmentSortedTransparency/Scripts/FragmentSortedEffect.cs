using System.Collections.Generic;
using UnityEngine;

public class FragmentSortedEffect : MonoBehaviour {
    static List<FragmentSortedRenderer> _renderers = new List<FragmentSortedRenderer>();

    [Range(0.5f, 10.0f)]
    public float fragsPerPixel = 4;

    [Range(0.25f, 4.0f)]
    public float resolutionScale = 1;
    // Header Buffer Struct
    // {
    //      uint index
    // }

    // Linked List Struct
    // {
    //      Color surfaceColor
    //      Color internalColor
    //      uint depth
    //      uint nextChild
    // }

    int headerLength { get {
        return Mathf.FloorToInt(Screen.width * resolutionScale * Screen.height * resolutionScale);
    } }

    int linkedListLength { get {
        return Mathf.FloorToInt(headerLength * fragsPerPixel);
    } }

    Camera _effectCamera;
    Camera effectCamera { get {
        return _effectCamera = _effectCamera ?? new GameObject("Fragment Transparency Renderer").AddComponent<Camera>();
    } }

    ComputeBuffer _headerBuffer = null;
    ComputeBuffer _linkedListBuffer = null;
    
    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        // intialize the post effect render camera
        effectCamera.CopyFrom(GetComponent<Camera>());
        effectCamera.enabled = false;

        // initialize or resize linked list head buffer
        if (_headerBuffer != null && _headerBuffer.count != headerLength) {
            _headerBuffer.Release();
            _headerBuffer = null;
        }
        if (_headerBuffer == null) _headerBuffer = new ComputeBuffer(headerLength, 4);

        // initialize or resize the fragment linked list / append buffer
        if (_linkedListBuffer != null && _linkedListBuffer.count  != linkedListLength) {
            _linkedListBuffer.Release();
            _linkedListBuffer = null;
        }
        if (_linkedListBuffer == null) _linkedListBuffer = new ComputeBuffer(linkedListLength, 4, ComputeBufferType.Counter);

        // TODO: clear the compute buffers
        
        // Draw the meshes
        Shader.SetGlobalBuffer("_FragmentSortedTransparencyHead", _headerBuffer);
        Shader.SetGlobalBuffer("_FragmentSortedTransparencyLinkedList", _linkedListBuffer);

        UnityEngine.Rendering.CommandBuffer commandBuffer = new UnityEngine.Rendering.CommandBuffer();
        for (int i = 0; i < _renderers.Count; i ++) {
            FragmentSortedRenderer fsr = _renderers[i];

            // TODO: Support multiple materials?
            MeshFilter mf = fsr.GetComponent<MeshFilter>();
            if (fsr.material && mf) commandBuffer.DrawMesh(mf.sharedMesh, fsr.transform.localToWorldMatrix, fsr.material);
        }

        effectCamera.Render();
        effectCamera.RemoveAllCommandBuffers();
        commandBuffer.Release();
        Shader.SetGlobalBuffer("_FragmentSortedTransparencyHead", null);
        Shader.SetGlobalBuffer("_FragmentSortedTransparencyLinkedList", null);

        // TODO: sort the fragments here?

        // composite into the destination buffer
        // TODO: How do we sample the depth buffer here?
        Graphics.Blit(source, destination, null);
    }

}
