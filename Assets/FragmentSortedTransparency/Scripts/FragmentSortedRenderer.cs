using UnityEngine;

public class FragmentSortedRenderer : MonoBehaviour {

    public Material material = null;

    void OnEnable() { FragmentSortedEffect.RegisterRenderer(this); }
    
    void OnDisable() { FragmentSortedEffect.DeregisterRenderer(this); }

    private void OnDrawGizmos() {
        MeshFilter mf = GetComponent<MeshFilter>();
        if (!mf) return;

        Mesh mesh = mf.sharedMesh;
        if (!mesh) return;

        Gizmos.matrix = transform.localToWorldMatrix;

        Gizmos.color = new Color(1, 1, 1, 0.1f);
        Gizmos.DrawMesh(mesh);

        Gizmos.color = new Color(1, 1, 1, 0.4f);
        Gizmos.DrawWireMesh(mesh);

    }
}
