using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class ProceduralMesh : MonoBehaviour
{
    private Mesh mesh;
    private Vector3[] vertices;
    private int[] triangles;

    void Awake()
    {
        mesh = GetComponent<MeshFilter>().mesh;
    }

	// Use this for initialization
	void Start () {
		MakeMashData();
        CreateMash();
	}

    void MakeMashData()
    {
        vertices = new Vector3[] { new Vector3(0, 0, 0), new Vector3(0, 0, 1), new Vector3(1, 0, 0), };
        triangles = new int[] {0, 1, 2};
    }

    void CreateMash()
    {
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
    }
	

}
