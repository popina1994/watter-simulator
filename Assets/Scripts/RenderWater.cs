using System;
using System.Collections;
using System.Collections.Generic;
using Assets.Scripts;
using UnityEngine;

public class RenderWater : MonoBehaviour
{
    public Camera cameraCubeMap;
    public RenderTexture texture1;
    public RenderTexture texture2;
    public RenderTexture textureSkyBox;
    public RenderTexture textureReflection1;
    public RenderTexture textureReflection2;
    public Material material1;
    public Material material2;
    public Material materialCubeMap;
    public float radius;
    private GameObject waterQuad;
    private int idx = 0;
    private int idxShader = 0;
    private float xPos;
    private float yPos;
    private float isClicked = 1;
    public static float scaleCol = 20f;
    public static float scaleRow = 20f;
    public static float scaleHeight = 2f;
    private static float  []resultsArray = null;
    private Mesh _meshTmp;
    private ObjectLogic objectLogic;
	void Start ()
	{
	    isClicked = 0;
        waterQuad = GameObject.Find("WaterSurface");
        objectLogic = new ObjectLogic();
	}

    private void ConvertClickedPointToTextureCoordinate(Vector3 clickPoint)
    {
        // row -> x, col-> z
        xPos = scaleRow * clickPoint.x;
        yPos = scaleCol * clickPoint.z;
    }

    void Update()
    {

        if (Input.GetMouseButtonDown(0) || Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hitInfo;
            if (Physics.Raycast(ray, out hitInfo) && 
                hitInfo.transform.name == waterQuad.name)
            {
                isClicked = 1;
                Vector3 localPoint = waterQuad.transform.InverseTransformPoint(hitInfo.point);
                ConvertClickedPointToTextureCoordinate(localPoint);
                //Debug.Log("Clicked" + xPos.ToString() + " : " + yPos.ToString());
            }
        }
        else if (objectLogic.IsKeyPressed())
        {
            objectLogic.ProcessKeyPresses();
        }
        idx = (idx + 1) % 2;
    }

    private static float[] GetTextureArrayFromRenderTexture(RenderTexture renderTexture)
    {
        Texture2D texture2D = new Texture2D(renderTexture.width, renderTexture.height, TextureFormat.RGBAFloat, false);
        texture2D.ReadPixels(new Rect(0, 0, renderTexture.width, renderTexture.height), 0, 0);
        Color[] pixels = texture2D.GetPixels();
        
        if (resultsArray == null)
        {
            resultsArray = new float[pixels.Length * 2];
        }
        
        for (int i = 0; i < pixels.Length; i++)
        {
            resultsArray[i * 2] = pixels[i].r;
            resultsArray[i * 2 + 1] = pixels[i].g;
            //results[i * 4 + 2] = pix2[i].b;
            //results[i * 4 + 3] = pix2[i].a;
        }
        Destroy(texture2D);

        return resultsArray;
        // TODO: Rethihk about necessity of veliocity. 

    }

    private static int IndexInTextureArray(RenderTexture renderTexture, int row, int col)
    {
        return 2 * (row * renderTexture.width + col) + 1;
    }

    private static float GetHeight(RenderTexture renderTexture, float[] velHeightMap, int row, int col)
    {
        return velHeightMap[IndexInTextureArray(renderTexture, row, col)]  * scaleHeight;
    }

    private static Vector3 GenerateVertex(RenderTexture heightMapTexture, float[] velHeightMap, 
        int row, int col)
    {
        return new Vector3(row / scaleRow, GetHeight(heightMapTexture, velHeightMap, row, col), col / scaleCol);
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

    private static Mesh GenerateMeshBasedOnHeightMap(RenderTexture heightMapTexture, 
        float[] velHeightMap)
    {
        Mesh mesh = new Mesh();
        List<Vector3> vertices = new List<Vector3>();
        List<int> triangles = new List<int>();
        Vector3 leftTop;
        Vector3 rightTop;
        Vector3 leftBottom;
        Vector3 rightBottom;
        
        for (int row = 0; row < (heightMapTexture.height/4)-1; row++)
        {
            for (int col = 0; col < heightMapTexture.width/2 - 1; col++)
            {
                leftTop = GenerateVertex(heightMapTexture, velHeightMap, row, col);
                rightTop = GenerateVertex(heightMapTexture, velHeightMap, row, col + 1);
                leftBottom = GenerateVertex(heightMapTexture, velHeightMap, row + 1, col);
                rightBottom = GenerateVertex(heightMapTexture, velHeightMap, row + 1, col + 1);
                AddHeightToMesh(vertices, triangles, rightBottom, leftBottom, leftTop);
                AddHeightToMesh(vertices, triangles, rightTop, rightBottom, leftTop);
            }
        }
        
        //TODO Rethink how to solve problem of limitation of mesh in Unity. 
        // 65536
        
        mesh.SetVertices(vertices);
        mesh.triangles = triangles.ToArray();
        mesh.RecalculateNormals();
        
        return mesh;
    }

    private static Mesh GenerateSimplifiedMeshBasedOnHeightMap(RenderTexture heightMapTexture,
        float[] velHeightMap)
    {
        Mesh mesh = new Mesh();
        List<Vector3> vertices = new List<Vector3>();
        List<int> triangles = new List<int>();
        Vector3 leftTop;
        Vector3 rightTop;
        Vector3 leftBottom;
        Vector3 rightBottom;

        leftTop = GenerateVertex(heightMapTexture, velHeightMap, 0, 0);
        rightTop = GenerateVertex(heightMapTexture, velHeightMap, 0, heightMapTexture.width/2 - 1);
        leftBottom = GenerateVertex(heightMapTexture, velHeightMap, heightMapTexture.height/4 - 1, 0);
        rightBottom = GenerateVertex(heightMapTexture, velHeightMap, heightMapTexture.height/4 - 1, 
                                     heightMapTexture.width/2 - 1);
        AddHeightToMesh(vertices, triangles, rightBottom, leftBottom, leftTop);
        AddHeightToMesh(vertices, triangles, rightTop, rightBottom, leftTop);

        mesh.SetVertices(vertices);
        mesh.triangles = triangles.ToArray();
        mesh.RecalculateNormals();
        return mesh;
    }

    private void InitializeMeshColider(RenderTexture heightMapTexture)
    {
        float[] velHeightMap = GetTextureArrayFromRenderTexture(heightMapTexture);
        MeshCollider meshCollider = waterQuad.GetComponent<MeshCollider>() as MeshCollider;
        meshCollider.sharedMesh = GenerateSimplifiedMeshBasedOnHeightMap(heightMapTexture, velHeightMap);
    }

    private void UpdateWaterBasedOnHeightMap(RenderTexture heightMapTexture)
    {
        float[] velHeightMap = GetTextureArrayFromRenderTexture(heightMapTexture);
        MeshFilter meshFilter = waterQuad.GetComponent<MeshFilter>() as MeshFilter;
        Destroy(_meshTmp);
        _meshTmp = GenerateMeshBasedOnHeightMap(heightMapTexture, velHeightMap);
        meshFilter.mesh = _meshTmp;
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
            material1.shader = Shader.Find("Standard");
            InitializeMeshColider(texture1);
        }
        else if (idxShader == 1)
        {
            material2.shader = Shader.Find("WaterHeightInit");
            Graphics.Blit(texture1, texture2, material2);
            material2.shader = Shader.Find("Standard");
        }
        else
        {
            // I cannot explain why coordinates are swaped. 
            otherMatherial.shader = Shader.Find("WaterHeightShader");
            otherMatherial.SetFloat("_xPos", yPos);
            otherMatherial.SetFloat("_yPos", xPos);
            otherMatherial.SetFloat("_IsClicked", isClicked);
            otherMatherial.SetFloat("_Radius", radius);
            Graphics.Blit(currentTexture, otherTexture, otherMatherial);
            UpdateWaterBasedOnHeightMap(currentTexture);
            isClicked = 0;
            otherMatherial.shader = Shader.Find("Standard");

            cameraCubeMap.RenderToCubemap(textureSkyBox);

            materialCubeMap.shader = Shader.Find("WaterReflectShader");
            materialCubeMap.SetTexture("_CubeMap", textureSkyBox);
            
            if (idxShader % 2 == 0)
            {
                Graphics.Blit(null, textureReflection1, materialCubeMap);
            }
            else
            {
                Graphics.Blit(null, textureReflection2, materialCubeMap);
            }
            
            

            //materialCubeMap.shader = Shader.Find("Standard");
        }

        idxShader = idxShader + 1;
    }


}
