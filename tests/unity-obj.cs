using System;
using System.IO;
using System.Globalization;
using FTEBroomImport;
class Test {
 static int checks;
 static void Expect(bool value,string name){if(!value)throw new Exception(name);checks++;Console.WriteLine("PASS "+name);}
 static void Reject(string obj){bool failed=false;try{Obj.Read(new StringReader(obj),true);}catch(InvalidDataException){failed=true;}Expect(failed,"malformed input");}
 static void Main(string[] args){
  CultureInfo.CurrentCulture=new CultureInfo("de-DE");
  string vertices="v 1.5 2 3\nv 4 2 3\nv 1.5 5 3\nvt 0 0\nvt 1 0\nvt 0 1\n";
  string triangle="usemtl material_0\nf 1/1 2/2 3/3\n";
  var mesh=Obj.Read(new StringReader(vertices+triangle),true)[0];
  Expect(mesh.positions[0][0]==1.5f&&mesh.positions[0][1]==3&&mesh.positions[0][2]==2,"coordinate conversion and invariant decimals");
  Expect(mesh.surfaces[0].indices[1]==2&&mesh.surfaces[0].indices[2]==1,"reflected winding");
  Expect(mesh.uvs[1][0]==1&&mesh.uvs[2][1]==1,"UV preservation");
  Expect(Obj.Read(new StringReader(vertices+"o a\n"+triangle+"o b\n"+triangle),true).Count==2,"separate objects");
  var combined=Obj.Read(new StringReader(vertices+"o a\n"+triangle+"o b\n"+triangle),false);
  Expect(combined.Count==1&&combined[0].surfaces[0].indices.Count==6,"combined geometry");
  Expect(Obj.Read(new StringReader(vertices+"f -3/-3 -2/-2 -1/-1\n"),true)[0].positions.Count==3,"negative indices");
  Reject(vertices+"f 0/1 2/2 3/3");Reject(vertices+"f 4/1 2/2 3/3");Reject(vertices+"f 1 2 3");Reject("v NaN 0 0");Reject("# empty");
  foreach(string path in args){using(var reader=File.OpenText(path)){var geometry=Obj.Read(reader,true);int triangles=0;foreach(var part in geometry)foreach(var surface in part.surfaces)triangles+=surface.indices.Count/3;Expect(triangles>=12,"engine exported mesh "+path);}}
  Console.WriteLine("All "+checks+" checks passed.");
 }
}
