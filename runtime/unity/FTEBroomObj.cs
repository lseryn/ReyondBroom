// FTEBroom managed Unity bridge v1
// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded OBJ reader for the editor's own export format. Independent of Unity APIs.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
namespace FTEBroomImport {
public sealed class Surface {
    public string material;
    public readonly List<int> indices = new List<int>();
}
public sealed class MeshData {
    public string name;
    public readonly List<float[]> positions = new List<float[]>();
    public readonly List<float[]> uvs = new List<float[]>();
    public readonly List<Surface> surfaces = new List<Surface>();
    internal readonly Dictionary<long,int> remap = new Dictionary<long,int>();
    internal Surface Material(string id) {
        foreach (var s in surfaces) if (s.material == id) return s;
        var next = new Surface {material=id}; surfaces.Add(next); return next;
    }
}
public static class Obj {
    const int MaxVertices = 2000000, MaxTriangles = 4000000;
    static float Number(string text) {
        float value;
        if (!float.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out value) || float.IsNaN(value) || float.IsInfinity(value)) throw new InvalidDataException("Invalid OBJ number.");
        return value;
    }
    static int Index(string text, int count) {
        int value;
        if (!int.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out value)) throw new InvalidDataException("Invalid OBJ index.");
        value = value > 0 ? value-1 : count+value;
        if (value < 0 || value >= count) throw new InvalidDataException("OBJ index is outside the vertex array.");
        return value;
    }
    public static List<MeshData> Read(TextReader input, bool separate) {
        var positions = new List<float[]>(); var uvs = new List<float[]>();
        var result = new List<MeshData>(); var current = new MeshData {name="Map"}; result.Add(current);
        string material="untextured", line; int triangles=0, expanded=0;
        while ((line=input.ReadLine()) != null) {
            if (line.Length > 65536) throw new InvalidDataException("OBJ line is too long.");
            var words=line.Split((char[])null,StringSplitOptions.RemoveEmptyEntries); if(words.Length==0 || words[0][0]=='#')continue;
            switch(words[0]) {
            case "v":
                if(words.Length<4 || positions.Count>=MaxVertices)throw new InvalidDataException("Invalid or excessive OBJ vertices.");
                // Quake Z-up to Unity Y-up. Reflection is compensated in triangle winding.
                positions.Add(new[]{Number(words[1]),Number(words[3]),Number(words[2])});break;
            case "vt":
                if(words.Length<3 || uvs.Count>=MaxVertices)throw new InvalidDataException("Invalid or excessive OBJ UVs.");
                uvs.Add(new[]{Number(words[1]),Number(words[2])});break;
            case "o":
                if(separate){if(current.positions.Count>0){current=new MeshData();result.Add(current);}current.name=words.Length>1?words[1]:"Object";}break;
            case "usemtl": if(words.Length!=2)throw new InvalidDataException("Invalid OBJ material.");material=words[1];break;
            case "f":
                if(words.Length<4 || words.Length>129)throw new InvalidDataException("Invalid OBJ polygon.");
                var polygon=new int[words.Length-1];
                for(int i=1;i<words.Length;i++) {
                    var pair=words[i].Split('/'); if(pair.Length<2 || pair[1].Length==0)throw new InvalidDataException("OBJ face is missing UVs.");
                    int v=Index(pair[0],positions.Count),t=Index(pair[1],uvs.Count);long key=((long)v<<32)|(uint)t;int mapped;
                    if(!current.remap.TryGetValue(key,out mapped)){
                        if(++expanded>MaxVertices)throw new InvalidDataException("OBJ mesh exceeds two million vertices.");
                        mapped=current.positions.Count;current.remap.Add(key,mapped);current.positions.Add(positions[v]);current.uvs.Add(uvs[t]);
                    }polygon[i-1]=mapped;
                }
                var surface=current.Material(material);
                for(int i=1;i<polygon.Length-1;i++){
                    if(++triangles>MaxTriangles)throw new InvalidDataException("OBJ mesh exceeds four million triangles.");
                    surface.indices.Add(polygon[0]);surface.indices.Add(polygon[i+1]);surface.indices.Add(polygon[i]);
                }break;
            }
        }
        result.RemoveAll(mesh=>mesh.positions.Count==0);
        if(result.Count==0)throw new InvalidDataException("No exported brush or patch geometry.");
        return result;
    }
}
}
