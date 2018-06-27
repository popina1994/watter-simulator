using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderWater : MonoBehaviour
{
    [SerializeField]public Camera renderCamera;
    public Shader shader;
    public RenderTexture texture1;
    public RenderTexture texture2;
    public Material material1;
    public Material material2;
    private int idx = 0;

	void Start () {
        GL.Clear(false, true, Color.clear);
	    renderCamera.targetTexture = texture1;
	    //renderCamera.SetReplacementShader(shader, "");

    }

    void Update()
    {
        renderCamera.Render();
        if (idx == 0)
        {
            //Graphics.SetRenderTarget(texture1);
            renderCamera.targetTexture = texture2;
        }
        else
        {
            //Graphics.SetRenderTarget(texture2);
            renderCamera.targetTexture = texture1;
        }

        idx = (idx + 1) % 2;
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
        Graphics.Blit(currentTexture, otherTexture, otherMatherial);
    }
}
