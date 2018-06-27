using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderWater : MonoBehaviour
{
    [SerializeField]public Camera renderCamera;
    public Shader shader;
    public RenderTexture texture1;
    public RenderTexture texture2;
    public RenderTexture texture3;
    public Material material1;
    public Material material2;
    private int idx = 0;
    private int idxShader = 0;

	void Start () {
        GL.Clear(false, true, Color.clear);
	    renderCamera.targetTexture = texture3;
    }

    void Update()
    {
        renderCamera.targetTexture = texture3;
        idx = (idx + 1) % 2;
    }

    float[] RenderTextureToTexture2d(RenderTexture renderTexture)
    {
        Texture2D tex = new Texture2D(renderTexture.width, renderTexture.height, TextureFormat.RGBAFloat, false);
        RenderTexture.active = renderTexture;
        tex.ReadPixels(new Rect(0, 0, renderTexture.width, renderTexture.height), 0, 0);
        tex.Apply();
        RenderTexture.active = null;
        Color [] pix2 = tex.GetPixels();
        float[] results = new float[pix2.Length * 4];
        for (int i = 0; i < pix2.Length; i++)
        {
            results[i * 4] = pix2[i].r;
            results[i * 4 + 1] = pix2[i].g;
            results[i * 4 + 2] = pix2[i].b;
            results[i * 4 + 3] = pix2[i].a;
        }
        return results;
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
            float []tmp = RenderTextureToTexture2d(texture1);
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
            RenderTextureToTexture2d(currentTexture);
            otherMatherial.shader = Shader.Find("Standard");
            // Check values
            // Draw triangles based on this values.
        }

        idxShader = idxShader + 1;


    }
}
