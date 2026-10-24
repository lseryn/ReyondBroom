// FTEBroom managed Unity bridge v1
// SPDX-License-Identifier: GPL-3.0-or-later
// Generated assets are confined to the manifest's directory under Assets.
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
namespace FTEBroomImport {
[Serializable] public sealed class MaterialDescription {public string id,name,texture,file;}
[Serializable] public sealed class Manifest {
    public int version;public string mesh;public bool separate,colliders;public float scale;
    public MaterialDescription[] materials;
}
[InitializeOnLoad]
public sealed class Sync : AssetPostprocessor {
    static readonly HashSet<string> pending=new HashSet<string>();
    static bool scheduled,busy;
    static Sync(){EditorApplication.delayCall+=FindExports;}
    static void FindExports(){foreach(var path in AssetDatabase.GetAllAssetPaths())if(path.EndsWith(".ftebroom.json",StringComparison.Ordinal))Queue(path);}
    static void Queue(string path){pending.Add(path);if(!scheduled){scheduled=true;EditorApplication.delayCall+=RunPending;}}
    static void OnPostprocessAllAssets(string[] imported,string[] deleted,string[] moved,string[] movedFrom){
        foreach(var path in imported)if(path.EndsWith(".ftebroom.json",StringComparison.Ordinal))Queue(path);
    }
    static void RunPending(){scheduled=false;if(busy){EditorApplication.delayCall+=RunPending;scheduled=true;return;}var paths=new List<string>(pending);pending.Clear();foreach(var path in paths){if(File.Exists(Path.Combine(Path.GetDirectoryName(path),".ftebroom-lock"))){Queue(path);continue;}try{Import(path);}catch(Exception e){Debug.LogError("FTEBroom Sync: "+path+"\n"+e);}}}
    [MenuItem("Tools/FTEBroom/Regenerate synced maps")]
    static void Regenerate(){FindExports();}
    static string Relative(string root,string name){
        if(string.IsNullOrEmpty(name)||Path.IsPathRooted(name))throw new InvalidDataException("Invalid manifest path.");
        var full=Path.GetFullPath(Path.Combine(root,name));var prefix=Path.GetFullPath(root)+Path.DirectorySeparatorChar;
        if(!full.StartsWith(prefix,StringComparison.Ordinal))throw new InvalidDataException("Manifest path leaves export directory.");
        return (root+"/"+name).Replace('\\','/');
    }
    static void Folder(string path){if(AssetDatabase.IsValidFolder(path))return;var parent=Path.GetDirectoryName(path).Replace('\\','/');Folder(parent);AssetDatabase.CreateFolder(parent,Path.GetFileName(path));}
    static Mesh StoreMesh(string path,MeshData data){
        var mesh=new Mesh {name=data.name,indexFormat=data.positions.Count>65535?IndexFormat.UInt32:IndexFormat.UInt16};
        var vertices=new Vector3[data.positions.Count];var uv=new Vector2[data.uvs.Count];
        for(int i=0;i<vertices.Length;i++){var p=data.positions[i];vertices[i]=new Vector3(p[0],p[1],p[2]);var t=data.uvs[i];uv[i]=new Vector2(t[0],t[1]);}
        mesh.vertices=vertices;mesh.uv=uv;mesh.subMeshCount=data.surfaces.Count;
        for(int i=0;i<data.surfaces.Count;i++)mesh.SetTriangles(data.surfaces[i].indices,i,false);
        mesh.RecalculateNormals();mesh.RecalculateBounds();
        var existing=AssetDatabase.LoadAssetAtPath<Mesh>(path);
        if(existing!=null){EditorUtility.CopySerialized(mesh,existing);UnityEngine.Object.DestroyImmediate(mesh);EditorUtility.SetDirty(existing);return existing;}
        AssetDatabase.CreateAsset(mesh,path);return mesh;
    }
    public static void Import(string path){
        if(busy)return;
        path=path.Replace('\\','/');if(!path.StartsWith("Assets/",StringComparison.Ordinal)||!path.EndsWith(".ftebroom.json",StringComparison.Ordinal))throw new InvalidDataException("Manifest must be inside Assets.");
        var root=Path.GetDirectoryName(path).Replace('\\','/');var manifest=JsonUtility.FromJson<Manifest>(File.ReadAllText(path));
        if(manifest==null||manifest.version!=1||float.IsNaN(manifest.scale)||float.IsInfinity(manifest.scale)||manifest.scale<=0||manifest.scale>1000)throw new InvalidDataException("Unsupported manifest or scale.");
        List<MeshData> geometry;using(var reader=File.OpenText(Relative(root,manifest.mesh)))geometry=Obj.Read(reader,manifest.separate);
        busy=true;GameObject map=null;
        try{
            Folder(root+"/Meshes");Folder(root+"/Materials");Folder(root+"/Prefabs");
            var materials=new Dictionary<string,Material>();
            var shader=GraphicsSettings.currentRenderPipeline==null ? (Shader.Find("Standard")??Shader.Find("Diffuse")) : Shader.Find("Universal Render Pipeline/Lit");
            if(shader==null)throw new InvalidDataException("No supported Unity material shader.");
            foreach(var item in manifest.materials??new MaterialDescription[0]){
                var materialPath=Relative(root,"Materials/"+item.file+".mat");var material=AssetDatabase.LoadAssetAtPath<Material>(materialPath);
                bool created=material==null;if(created){material=new Material(shader){name=item.name};AssetDatabase.CreateAsset(material,materialPath);}
                if(!string.IsNullOrEmpty(item.texture)){
                    var texture=AssetDatabase.LoadAssetAtPath<Texture2D>(Relative(root,item.texture));
                    if(texture!=null){material.mainTexture=texture;if(material.HasProperty("_BaseMap"))material.SetTexture("_BaseMap",texture);if(material.HasProperty("_MainTex"))material.SetTexture("_MainTex",texture);}
                }EditorUtility.SetDirty(material);materials.Add(item.id,material);
            }
            map=new GameObject(Path.GetFileName(root));map.transform.localScale=Vector3.one*manifest.scale;
            for(int i=0;i<geometry.Count;i++){
                var data=geometry[i];var mesh=StoreMesh(root+"/Meshes/part_"+i.ToString("D6")+".asset",data);
                var child=new GameObject(data.name);child.transform.SetParent(map.transform,false);child.AddComponent<MeshFilter>().sharedMesh=mesh;
                var assigned=new Material[data.surfaces.Count];for(int j=0;j<assigned.Length;j++)if(!materials.TryGetValue(data.surfaces[j].material,out assigned[j]))throw new InvalidDataException("Missing exported material.");
                child.AddComponent<MeshRenderer>().sharedMaterials=assigned;if(manifest.colliders)child.AddComponent<MeshCollider>().sharedMesh=mesh;
            }
            if(PrefabUtility.SaveAsPrefabAsset(map,root+"/Prefabs/Map.prefab")==null)throw new InvalidDataException("Unity could not save the generated prefab.");AssetDatabase.SaveAssets();Debug.Log("FTEBroom: updated "+root+"/Prefabs/Map.prefab");
        }finally{if(map!=null)UnityEngine.Object.DestroyImmediate(map);busy=false;}
    }
}
}
