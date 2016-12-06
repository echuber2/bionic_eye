using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

[ExecuteInEditMode]
[AddComponentMenu("Image Effects/Displacement/PointsFxGauss")]
public class PointsFxGauss : ImageEffectBase
{
    public float numDots;  
    public float dotSize;
    // public Texture dotTexture;
    public bool useHexMode;

    // Called by camera to apply image effect
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetInt("useHexMode", useHexMode ? 1 : 0);
        material.SetFloat("numDots", numDots);
        material.SetFloat("_DotFreq", 1 / numDots);
        material.SetFloat("_DotSize", numDots*dotSize);
        // material.SetTexture("_DotTex", dotTexture);

        Graphics.Blit(source, destination, material);
    }
}
