using UnityEngine;

public class FragmentSortedRenderer : MonoBehaviour {

    public Material material = null;

    void OnEnable() { FragmentSortedEffect.RegisterRenderer(this); }
    
    void OnDisable() { FragmentSortedEffect.DeregisterRenderer(this); }

    void OnRenderObject() { }    
}
