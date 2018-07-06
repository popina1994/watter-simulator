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
    public Material material1;
    public Material material2;
    public Material materialCubeMap;
    public Color waterColor;
    public float radius;
    private GameObject testCube;

    private GameObject waterQuad;
    private int idxTexture;
    private int idxShader;
    private Vector2 _xPos = new Vector2();
    private Vector2 _yPos = new Vector2();
    private Vector2 _isClicked = new Vector2();
    public static int rowVertices = 64;
    public static int colVertices = 128;
    public static float scaleCol = 20f;
    public static float scaleRow = 20f;
    public static float scaleHeight = 2f;
    private int rowSize;
    private int colSize;
    private static float  []resultsArray = null;
    private Mesh _meshTmp;
    private ObjectLogic objectLogic;

    public float Radius
    {
        get { return radius; }
        set { radius = value; }
    }

    public Vector2 XPos
    {
        get { return _xPos; }
        set { _xPos = value; }
    }

    public Vector2 YPos
    {
        get { return _yPos; }
        set { _yPos = value; }
    }

    public Vector2 IsClicked
    {
        get { return _isClicked; }
        set { _isClicked = value; }
    }

    void Start ()
	{
        waterQuad = GameObject.Find("WaterSurface");
	    materialCubeMap.shader = Shader.Find("WaterReflectShader");
        //materialWaterVertexNormal.shader = Shader.Find("WaterVertexNormalShader");
        objectLogic = new ObjectLogic(this);
	    rowSize = texture1.width;
	    colSize = texture1.height;
	}


    private void PointClicked(Vector3 worldInteractionPoint, int idx)
    {
        Vector3 localPoint = waterQuad.transform.InverseTransformPoint(worldInteractionPoint);
        _isClicked[idx] = 1;
        // row -> x, col-> z
        _xPos[idx] = scaleRow * localPoint.x * rowSize / rowVertices;
        _yPos[idx] = scaleCol * localPoint.z * colSize / colVertices;
    }

    public void WaterWaveHappened(Vector3 worldInteractionPoint)
    {
        PointClicked(worldInteractionPoint, 0);
    }

    public void WaterWaveQuadHappened(Vector3[] worldInteractionPoints)
    {
        for (int idx = 0; idx < 2; idx++)
        {
            PointClicked(worldInteractionPoints[idx], idx);
        }
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
                WaterWaveHappened(hitInfo.point);
                Debug.Log("Clicked" + _xPos.ToString() + " : " + _yPos.ToString());
            }
        }
        else if (objectLogic.IsKeyPressed())
        {
            objectLogic.ProcessKeyPresses();
        }
        idxTexture = (idxTexture + 1) % 2;
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
        }
        Destroy(texture2D);

        return resultsArray;
        // TODO: Rethihk about necessity of veliocity. 

    }

    private static long IndexInTextureArray(RenderTexture renderTexture, int row, int col)
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
        
        for (int rowX = 0; rowX < rowVertices; rowX++)
        {
            for (int colZ = 0; colZ < colVertices; colZ++)
            {
                leftTop = GenerateVertex(heightMapTexture, velHeightMap, rowX, colZ);
                rightTop = GenerateVertex(heightMapTexture, velHeightMap, rowX, colZ + 1);
                leftBottom = GenerateVertex(heightMapTexture, velHeightMap, rowX + 1, colZ);
                rightBottom = GenerateVertex(heightMapTexture, velHeightMap, rowX + 1, colZ + 1);
                AddHeightToMesh(vertices, triangles, rightBottom, leftBottom, leftTop);
                AddHeightToMesh(vertices, triangles, rightTop, rightBottom, leftTop);
            }
        }
        
        //TOD1O Rethink how to solve problem of limitation of mesh in Unity. 
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
        rightTop = GenerateVertex(heightMapTexture, velHeightMap, 0, colVertices - 1);
        leftBottom = GenerateVertex(heightMapTexture, velHeightMap, rowVertices - 1, 0);
        rightBottom = GenerateVertex(heightMapTexture, velHeightMap, rowVertices - 1,
            colVertices - 1);
        float height = (leftTop.y + rightTop.y + leftBottom.y + rightBottom.y) / 4;
        leftTop.y = height;
        rightTop.y = height;
        leftBottom.y = height;
        rightBottom.y = height;
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
        _meshTmp.RecalculateNormals();
        meshFilter.mesh = _meshTmp;
    }

    private void InitRenderTexture(Material material, RenderTexture texture, RenderTexture otherTexture)
    {
        material.shader = Shader.Find("WaterHeightInit");
        material.SetFloat("_RendTexSize", texture.width);
        Graphics.Blit(otherTexture, texture, material);
    }

    private void CalculateAndUpdateWater(Material material, RenderTexture currentTexture, 
        RenderTexture otherTexture)
    {
        // I cannot explain why coordinates are swaped. 
        material.shader = Shader.Find("WaterHeightShader");
        material.SetVector("_xPos", _xPos);
        material.SetVector("_yPos", _yPos);
        material.SetVector("_IsClicked", _isClicked);
        material.SetFloat("_Radius", radius);
        material.SetFloat("_RendTexSize", texture1.width);
        Graphics.Blit(currentTexture, otherTexture, material);
        _isClicked = new Vector2(0, 0);
        //material.shader = Shader.Find("Standard");
    }

    private void UpdateCubeMap(RenderTexture texture)
    {
        cameraCubeMap.RenderToCubemap(textureSkyBox);
        materialCubeMap.SetFloat("_ScaleHeight", scaleHeight);
        materialCubeMap.SetTexture("_MainTex", texture);
        materialCubeMap.SetTexture("_CubeMap", textureSkyBox);
        materialCubeMap.SetColor("_ColorWater", waterColor);
        materialCubeMap.SetFloat("_RowWidth", rowVertices / scaleRow);
        materialCubeMap.SetFloat("_ColWidth", colVertices / scaleCol);
        materialCubeMap.SetFloat("_DispRow", 1 / scaleRow);
        materialCubeMap.SetFloat("_DispCol", 1 / scaleCol);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // idxTexture == 0, currentTexture is texture1
        // it is written the old one
        RenderTexture currentTexture, otherTexture;
        Material currentMaterial;
        Graphics.Blit(src, dest);
        currentTexture = (idxTexture == 0) ? texture1 : texture2;
        otherTexture = (idxTexture == 0) ? texture2 : texture1;
        currentMaterial = (idxTexture == 0) ? material1 : material2;
        
        if (idxShader == 0)
        {
            InitRenderTexture(material1, texture1, texture2);
            InitializeMeshColider(texture1);
        }
        else if (idxShader == 1)
        {
            InitRenderTexture(material2, texture2, texture1);
            UpdateWaterBasedOnHeightMap(currentTexture);
        }
        else
        {
            CalculateAndUpdateWater(currentMaterial, currentTexture, otherTexture);
            UpdateCubeMap(currentTexture);
        }

        idxShader = idxShader + 1;
    }


}
