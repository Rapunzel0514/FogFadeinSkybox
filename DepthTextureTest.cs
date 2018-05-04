//This is modified based on Kino Fog
//https://github.com/keijiro/KinoFog


using UnityEngine;  
using System.Collections;  

[ExecuteInEditMode]  
public class DepthTextureTest : PostEffectBase  
{  
	// Start distance
	[SerializeField]
	float _startDistance = 1;

	void OnEnable()  
	{  
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;  
	}  

	void OnDisable()  
	{  
		GetComponent<Camera>().depthTextureMode &= ~DepthTextureMode.Depth;  
	}  

	[ImageEffectOpaque]
	void OnRenderImage(RenderTexture source, RenderTexture destination)  
	{  
		if (_Material)  
		{  
			Graphics.Blit(source, destination, _Material);  
		}  

		/*if (_material == null)
		{
			_material = new Material(_shader);
			_Material.hideFlags = HideFlags.DontSave;
		}*/

		_startDistance = Mathf.Max(_startDistance, 0.0f);
		_Material.SetFloat("_DistanceOffset", _startDistance);

		_Material.SetTexture("_MainTex", source);
		_Material.EnableKeyword("USE_SKYBOX");
		// Transfer the skybox parameters.
		var skybox = RenderSettings.skybox;
		_Material.SetTexture("_SkyCubemap", skybox.GetTexture("_Tex"));
		_Material.SetColor("_SkyTint", skybox.GetColor("_Tint"));
		_Material.SetFloat("_SkyExposure", skybox.GetFloat("_Exposure"));
		_Material.SetFloat("_SkyRotation", skybox.GetFloat("_Rotation"));

        // Calculate vectors towards frustum corners.
        var cam = GetComponent<Camera>();
        var camtr = cam.transform;
        var camNear = cam.nearClipPlane;
        var camFar = cam.farClipPlane;

        var tanHalfFov = Mathf.Tan(cam.fieldOfView * Mathf.Deg2Rad / 2);
        var toRight = camtr.right * camNear * tanHalfFov * cam.aspect;
        var toTop = camtr.up * camNear * tanHalfFov;

        var v_tl = camtr.forward * camNear - toRight + toTop;
        var v_tr = camtr.forward * camNear + toRight + toTop;
        var v_br = camtr.forward * camNear + toRight - toTop;
        var v_bl = camtr.forward * camNear - toRight - toTop;

        var v_s = v_tl.magnitude * camFar / camNear;

        // Draw screen quad.
        RenderTexture.active = destination;

		_Material.SetTexture("_MainTex", source);
		_Material.SetPass(0);

        GL.PushMatrix();
        GL.LoadOrtho();
        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0, 0);
        GL.MultiTexCoord(1, v_bl.normalized * v_s);
        GL.Vertex3(0, 0, 0.1f);

        GL.MultiTexCoord2(0, 1, 0);
        GL.MultiTexCoord(1, v_br.normalized * v_s);
        GL.Vertex3(1, 0, 0.1f);

        GL.MultiTexCoord2(0, 1, 1);
        GL.MultiTexCoord(1, v_tr.normalized * v_s);
        GL.Vertex3(1, 1, 0.1f);

        GL.MultiTexCoord2(0, 0, 1);
        GL.MultiTexCoord(1, v_tl.normalized * v_s);
        GL.Vertex3(0, 1, 0.1f);

        GL.End();
        GL.PopMatrix();

    }  
}  