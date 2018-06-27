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

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // idx == 0, currentTexture is texture1
        // it is written the old one
        RenderTexture currentTexture, otherTexture;
        Material currentMaterial, otherMatherial;
        //Graphics.Blit(src, dest);
        currentTexture = (idx == 0) ? texture1 : texture2;
        otherTexture = (idx == 0) ? texture2 : texture1;
        currentMaterial = (idx == 0) ? material1 : material2;
        otherMatherial = (idx == 0) ? material2 : material1;
        
        if (idxShader == 0)
        {
            material1.shader = Shader.Find("WaterHeightInit");
            Graphics.Blit(texture2, texture1, material1);
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
            otherMatherial.shader = Shader.Find("Standard");
        }

        idxShader = idxShader + 1;


    }
}
