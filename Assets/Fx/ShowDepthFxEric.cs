using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

[ExecuteInEditMode]
[AddComponentMenu("Image Effects/Depth FX Eric")]
public class ShowDepthFxEric : ImageEffectBase
{
    public float speed;

    public float frac(float val) {
        return val - (float)((int)val);
    }

    public bool animateClipPlanes = false;
    public float nearMin = 0.1f;
    public float farMax = 40.0f;
    public float farMin = 1.0f;
    public float bandWidth = 10.0f; // in meters

	// Use this for initialization
	override protected void Start () {
        var animateClipPlanesInt = animateClipPlanes ? 1 : 0;
        base.Start();
        var cam = GetComponent<Camera>();
        cam.depthTextureMode |= DepthTextureMode.Depth;
        if (animateClipPlanes) {
            var timeval = frac((Time.time+1.0f)/1.5f);
            cam.nearClipPlane = nearMin;
            cam.farClipPlane = timeval*farMax;
            if (cam.farClipPlane < farMin) {
                cam.farClipPlane = farMin;
            }
            cam.nearClipPlane = cam.farClipPlane - bandWidth;
            if (cam.nearClipPlane < nearMin) {
                cam.nearClipPlane = nearMin;
            }
        }
        else {
            cam.nearClipPlane = nearMin;
            cam.farClipPlane = farMax;
        }
        material.SetInt("animateClipPlanes", animateClipPlanesInt);
	}
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        var cam = GetComponent<Camera>();
        if (animateClipPlanes) {
            var timeval = frac((Time.time+1.0f)/1.5f);
            cam.farClipPlane = timeval*farMax;
            if (cam.farClipPlane < farMin) {
                cam.farClipPlane = farMin;
            }
            cam.nearClipPlane = cam.farClipPlane - bandWidth;
            if (cam.nearClipPlane < nearMin) {
                cam.nearClipPlane = nearMin;
            }
        }
        else {
            cam.nearClipPlane = nearMin;
            cam.farClipPlane = farMax;
        }
        // Debug.Log(timeval);
        //Graphics.SetRenderTarget(destination);
        material.SetFloat("_Speed", speed);
        Graphics.Blit(source, destination, material);
    }
}
