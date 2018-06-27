using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderWater : MonoBehaviour
{
    [SerializeField]public Camera renderCamera;
    public RenderTexture texture1;
    public RenderTexture texture2;
    public RenderTexture texture3;
    public Material material1;
    public Material material2;
    private GameObject waterQuad;
    private int idx = 0;
    private int idxShader = 0;

	void Start () {
        GL.Clear(false, true, Color.clear);
	    renderCamera.targetTexture = texture3;
        waterQuad = GameObject.Find("WaterSurface");
    }

    void Update()
    {
        renderCamera.targetTexture = texture3;
        idx = (idx + 1) % 2;
    }

    private static float[] GetTextureArrayFromRenderTexture(RenderTexture renderTexture)
    {
        Texture2D tex = new Texture2D(renderTexture.width, renderTexture.height, TextureFormat.RGBAFloat, false);
        RenderTexture.active = renderTexture;
        tex.ReadPixels(new Rect(0, 0, renderTexture.width, renderTexture.height), 0, 0);
        tex.Apply();
        RenderTexture.active = null;
        Color[] pix2 = tex.GetPixels();
        float[] results = new float[pix2.Length * 2];
        for (int i = 0; i < pix2.Length; i++)
        {
            results[i * 2] = pix2[i].r;
            results[i * 2 + 1] = pix2[i].g;
            //results[i * 4 + 2] = pix2[i].b;
            //results[i * 4 + 3] = pix2[i].a;
        }

        return results;
        // TODO: Rethihk about necessity of veliocity. 

    }

    private static int IndexInTextureArray(RenderTexture renderTexture, int row, int col)
    {
        return 2 * (row * renderTexture.width + col) + 1;
    }

    private static float GetHeight(RenderTexture renderTexture, float[] velHeightMap, int row, int col)
    {
        return velHeightMap[IndexInTextureArray(renderTexture, row, col)] * 10;
    }

    private static Vector3 GenerateVertex(RenderTexture heightMapTexture, float[] velHeightMap, 
        int row, int col)
    {
        return new Vector3(row/10.0f, GetHeight(heightMapTexture, velHeightMap, row, col), col /20.0f);
    }

    private static void AddHeightToMesh(List<Vector3> vertices, List<int> triangles, Vector3 vertex1, Vector3 vertex2,
        Vector3 vertex3)
    {
        int vertexId = vertices.Count;
        vertices.Add(vertex1);
        vertices.Add(vertex2);
        vertices.Add(vertex3);
        triangles.Add(vertexId);
        triangles.Add(vertexId + 1);
        triangles.Add(vertexId + 2);
    }

    private void UpdateWaterBasedOnHeightMap(RenderTexture heightMapTexture)
    {
        float[] velHeightMap = GetTextureArrayFromRenderTexture(heightMapTexture);
        MeshFilter meshFilter = waterQuad.GetComponent<MeshFilter>() as MeshFilter;
        Mesh mesh = new Mesh();
        List<Vector3> vertices = new List<Vector3>();
        List<int> triangles = new List<int>();
        Vector3 leftTop;
        Vector3 rightTop;
        Vector3 leftBottom;
        Vector3 rightBottom;

        for (int row = 0; row < heightMapTexture.width - 1; row ++)
        {
            for (int col = 0; col < heightMapTexture.height - 1; col++)
            {
                leftTop = GenerateVertex(heightMapTexture, velHeightMap, row, col);
                rightTop = GenerateVertex(heightMapTexture, velHeightMap, row, col + 1);
                leftBottom = GenerateVertex(heightMapTexture, velHeightMap, row + 1, col);
                rightBottom = GenerateVertex(heightMapTexture, velHeightMap, row + 1, col + 1);
                AddHeightToMesh(vertices, triangles, rightBottom, leftBottom, leftTop);
                AddHeightToMesh(vertices, triangles, rightTop, rightBottom, leftTop);
            }
        }
        mesh.SetVertices(vertices);
        mesh.triangles = triangles.ToArray();
        mesh.RecalculateNormals();
        meshFilter.mesh = mesh;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // idx == 0, currentTexture is texture1
        // it is written the old one
        RenderTexture currentTexture, otherTexture;
        Material currentMaterial, otherMatherial;
        Graphics.Blit(src, dest);
        currentTexture = (idx == 0) ? texture1 : texture2;
        otherTexture = (idx == 0) ? texture2 : texture1;
        currentMaterial = (idx == 0) ? material1 : material2;
        otherMatherial = (idx == 0) ? material2 : material1;
        
        if (idxShader == 0)
        {
            material1.shader = Shader.Find("WaterHeightInit");
            Graphics.Blit(texture2, texture1, material1);
            float []tmp = GetTextureArrayFromRenderTexture(texture1);
            material1.shader = Shader.Find("Standard");
        }
        else if (idxShader == 1)
        {
            material2.shader = Shader.Find("WaterHeightInit");
            Graphics.Blit(texture1, texture2, material2);
            material2.shader = Shader.Find("Standard");
        }
        else
        {
            otherMatherial.shader = Shader.Find("WaterHeightShader");
            Graphics.Blit(currentTexture, otherTexture, otherMatherial);
            UpdateWaterBasedOnHeightMap(currentTexture);
            otherMatherial.shader = Shader.Find("Standard");

            // Check values
            // Draw triangles based on this values.
        }

        idxShader = idxShader + 1;


    }
}
