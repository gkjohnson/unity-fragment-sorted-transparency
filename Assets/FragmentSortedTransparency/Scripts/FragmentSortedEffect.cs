using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

public class FragmentSortedEffect : MonoBehaviour {
    struct LinkedListNode {
        float r, g, b, a;
        float depth;
        int childIndex;
    }

    const string HEAD_BUFFER_NAME = "_FragmentSortedTransparencyHead";
    const string LINKEDLIST_BUFFER_NAME = "_FragmentSortedTransparencyLinkedList";
    const string LINKEDLIST_NULL_NAME = "LINKEDLIST_END";

    const int CLEAR_HEADER_KERNEL = 0;
    const int CLEAR_LINKEDLIST_KERNEL = 1;
    const int SORT_LINKEDLIST_KERNEL = 2;

    static List<FragmentSortedRenderer> _renderers = new List<FragmentSortedRenderer>();
    public static bool RegisterRenderer(FragmentSortedRenderer fsr) {
        if (_renderers.Contains(fsr)) return false;
        _renderers.Add(fsr);
        return true;
    }

    public static bool DeregisterRenderer(FragmentSortedRenderer fsr) {
        if (!_renderers.Contains(fsr)) return false;
        _renderers.Remove(fsr);
        return true;
    }


    [Range(0.5f, 10.0f)]
    public float fragsPerPixel = 4;
    
    public Shader compositeShader = null;
    public ComputeShader clearUtilities = null;

    Material _compositeMaterial = null;
    Material compositeMaterial { get {
        return _compositeMaterial = _compositeMaterial ?? new Material(compositeShader);
    } }

    int headerLength { get {
        return Mathf.FloorToInt(Screen.width * Screen.height);
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

    private void Start() {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        // intialize the post effect render camera
        effectCamera.CopyFrom(GetComponent<Camera>());
        effectCamera.clearFlags = CameraClearFlags.Nothing;
        effectCamera.cullingMask = 0;
        effectCamera.enabled = false;

        // initialize or resize linked list head buffer
        if (_headerBuffer != null && _headerBuffer.count != headerLength) {
            _headerBuffer.Release();
            _headerBuffer = null;
        }
        if (_headerBuffer == null) _headerBuffer = new ComputeBuffer(headerLength, Marshal.SizeOf(typeof(int)));

        // initialize or resize the fragment linked list / append buffer
        if (_linkedListBuffer != null && _linkedListBuffer.count  != linkedListLength) {
            _linkedListBuffer.Release();
            _linkedListBuffer = null;
        }
        if (_linkedListBuffer == null) _linkedListBuffer = new ComputeBuffer(linkedListLength, Marshal.SizeOf(typeof(LinkedListNode)), ComputeBufferType.Counter);

        Graphics.SetRandomWriteTarget(1, _headerBuffer);
        Graphics.SetRandomWriteTarget(2, _linkedListBuffer);

        clearUtilities.SetBuffer(CLEAR_HEADER_KERNEL, HEAD_BUFFER_NAME, _headerBuffer);
        clearUtilities.Dispatch(CLEAR_HEADER_KERNEL, _headerBuffer.count, 1, 1);
    
        clearUtilities.SetBuffer(CLEAR_LINKEDLIST_KERNEL, LINKEDLIST_BUFFER_NAME, _linkedListBuffer);
        clearUtilities.Dispatch(CLEAR_LINKEDLIST_KERNEL, _linkedListBuffer.count, 1, 1);
        
        // Draw the meshes
        Shader.SetGlobalBuffer(HEAD_BUFFER_NAME, _headerBuffer);
        Shader.SetGlobalBuffer(LINKEDLIST_BUFFER_NAME, _linkedListBuffer);
        Shader.SetGlobalInt(LINKEDLIST_NULL_NAME, _linkedListBuffer.count);

        UnityEngine.Rendering.CommandBuffer commandBuffer = new UnityEngine.Rendering.CommandBuffer();
        for (int i = 0; i < _renderers.Count; i ++) {
            FragmentSortedRenderer fsr = _renderers[i];

            // TODO: Support multiple materials?
            MeshFilter mf = fsr.GetComponent<MeshFilter>();
            if (fsr.material && mf) commandBuffer.DrawMesh(mf.sharedMesh, fsr.transform.localToWorldMatrix, fsr.material);
        }

        effectCamera.AddCommandBuffer(UnityEngine.Rendering.CameraEvent.AfterEverything, commandBuffer);
        effectCamera.Render();
        effectCamera.RemoveAllCommandBuffers();
        commandBuffer.Release();

        // Sort the fragments
        clearUtilities.SetBuffer(SORT_LINKEDLIST_KERNEL, HEAD_BUFFER_NAME, _headerBuffer);
        clearUtilities.SetBuffer(SORT_LINKEDLIST_KERNEL, LINKEDLIST_BUFFER_NAME, _linkedListBuffer);
        clearUtilities.Dispatch(SORT_LINKEDLIST_KERNEL, _headerBuffer.count, 1, 1);

        Graphics.ClearRandomWriteTargets();

        // TODO: sort the fragments here?
        // or in draw?
        // or on insert?

        // composite into the destination buffer
        // TODO: How do we sample the depth buffer here?
        
        Graphics.Blit(source, destination, compositeMaterial);
        
        Shader.SetGlobalBuffer(HEAD_BUFFER_NAME, null);
        Shader.SetGlobalBuffer(LINKEDLIST_BUFFER_NAME, null);
        Shader.SetGlobalInt(LINKEDLIST_NULL_NAME, 0);
    }

    private void OnDestroy() {
        if (_headerBuffer != null) _headerBuffer.Release();
        if (_linkedListBuffer != null) _linkedListBuffer.Release();
    }
}
