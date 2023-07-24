{ ****************************************************************************** }
{ * Navigation scene                                                           * }
{ ****************************************************************************** }
unit PasAI.Nav.Scene;

{$I PasAI.Define.inc}

interface

uses PasAI.Core, PasAI.Geometry2D, PasAI.Nav.Pass, PasAI.Nav.Polygon, PasAI.Nav.PathFinding, Math, Types,
  PasAI.DFE, PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib;

type
  TNavigationScene = class(TCore_Persistent)
  private
    FPolyManager: TPolyManager;
    FBioManager: TNavBioManager;
    FPassManagerList: TCore_ListForObj;
    FSceneSize: TVec2;

    function GetPassManager(ExtandDistance: TGeoFloat): TPolyPassManager;
    procedure RebuildNavBioPass(Sender: TNavBio);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;

    property PassManager[ExtandDistance: TGeoFloat]: TPolyPassManager read GetPassManager;
    property PolyManager: TPolyManager read FPolyManager;
    property BioManager: TNavBioManager read FBioManager;
    property SceneSize: TVec2 read FSceneSize write FSceneSize;
    property PassManagerList: TCore_ListForObj read FPassManagerList;

    procedure Progress(deltaTime: Double); virtual;

    function GroupMovementTo(BioList: TCore_ListForObj; ToPosition: TVec2): Integer;

    procedure AddPolygon(PointList: TVec2List; ConvexHull: Boolean);
    procedure SetScene(PointList: TVec2List);
    function AddBio(pt: TVec2; angle, radius: TGeoFloat): TNavBio;

    procedure ClearPass;

    procedure RebuildCoordinate;
    procedure RebuildPass;
    procedure ResetCollisionState;
    procedure StopAllMovement;

    procedure LoadFromStream(stream: TCore_Stream);
    procedure SaveToStream(stream: TCore_Stream);

    procedure LoadFromFile(FileName: U_String);
    procedure SaveToFile(FileName: U_String);
  end;

implementation

function TNavigationScene.GetPassManager(ExtandDistance: TGeoFloat): TPolyPassManager;
var
  i: Integer;
  p: TPolyPassManager;
begin
  for i := 0 to FPassManagerList.Count - 1 do
    begin
      p := FPassManagerList[i] as TPolyPassManager;
      if IsEqual(ExtandDistance, p.ExtandDistance) then
        begin
          Result := p;
          Exit;
        end;
    end;
  Result := TPolyPassManager.Create(FPolyManager, FBioManager, ExtandDistance);
  FPassManagerList.Add(Result);
end;

procedure TNavigationScene.RebuildNavBioPass(Sender: TNavBio);
var
  i: Integer;
  p: TPolyPassManager;
begin
  for i := 0 to FPassManagerList.Count - 1 do
    begin
      p := FPassManagerList[i] as TPolyPassManager;
      p.BuildNavBioPass;
    end;
  ResetCollisionState;
end;

constructor TNavigationScene.Create;
begin
  inherited Create;
  FPolyManager := TPolyManager.Create;
  FBioManager := TNavBioManager.Create;
{$IFDEF FPC}
  FBioManager.OnRebuildNavBioPass := @RebuildNavBioPass;
{$ELSE}
  FBioManager.OnRebuildNavBioPass := RebuildNavBioPass;
{$ENDIF}
  FPassManagerList := TCore_ListForObj.Create;
  FSceneSize := PointMake(1000, 1000);
end;

destructor TNavigationScene.Destroy;
var
  i: Integer;
begin
  for i := 0 to FPassManagerList.Count - 1 do
      DisposeObject(TPolyPassManager(FPassManagerList[i]));

  DisposeObject(FPassManagerList);
  DisposeObject(FPolyManager);
  DisposeObject(FBioManager);
  inherited Destroy;
end;

procedure TNavigationScene.Reset;
var
  i: Integer;
begin
  for i := 0 to FPassManagerList.Count - 1 do
      DisposeObject(TPolyPassManager(FPassManagerList[i]));
  FPassManagerList.Clear;
  FPolyManager.Clear;
  FBioManager.Clear;
end;

procedure TNavigationScene.Progress(deltaTime: Double);
begin
  FBioManager.Progress(deltaTime);
end;

function TNavigationScene.GroupMovementTo(BioList: TCore_ListForObj; ToPosition: TVec2): Integer;
var
  i: Integer;
  chr: TNavBio;
  group: TCore_ListForObj;
begin
  Result := 0;
  if BioList.Count = 0 then
      Exit;

  group := TCore_ListForObj.Create;
  for i := 0 to BioList.Count - 1 do
    begin
      chr := BioList[i] as TNavBio;
      if chr.MovementTo(ToPosition) then
          group.Add(chr);
    end;
  for i := 0 to group.Count - 1 do
    begin
      chr := group[i] as TNavBio;
    end;
  Result := group.Count;
  DisposeObject(group);
end;

procedure TNavigationScene.AddPolygon(PointList: TVec2List; ConvexHull: Boolean);
begin
  PointList.RemoveSame;
  if ConvexHull then
      FPolyManager.AddConvexHullPointList(PointList)
  else
      FPolyManager.AddPointList(PointList);

  ResetCollisionState;
  ClearPass;
end;

procedure TNavigationScene.SetScene(PointList: TVec2List);
begin
  PointList.RemoveSame;
  FPolyManager.Scene.Rebuild(PointList, True);
  ResetCollisionState;
  ClearPass;
end;

function TNavigationScene.AddBio(pt: TVec2; angle, radius: TGeoFloat): TNavBio;
begin
  Result := FBioManager.Add(PassManager[radius], pt, angle);
end;

procedure TNavigationScene.ClearPass;
var
  i: Integer;
  p: TPolyPassManager;
begin
  for i := 0 to FPassManagerList.Count - 1 do
    begin
      p := FPassManagerList[i] as TPolyPassManager;
      p.Clear;
    end;
end;

procedure TNavigationScene.RebuildCoordinate;
var
  i: Integer;
  p: TPolyManagerChildren;
begin
  FPolyManager.Scene.Rebuild;
  for i := 0 to FPolyManager.Count - 1 do
    begin
      p := FPolyManager[i];
      p.Rebuild;
    end;
end;

procedure TNavigationScene.RebuildPass;
var
  i: Integer;
  p: TPolyPassManager;
begin
  for i := 0 to FPassManagerList.Count - 1 do
    begin
      p := FPassManagerList[i] as TPolyPassManager;
      p.Rebuild;
    end;
end;

procedure TNavigationScene.ResetCollisionState;
var
  i: Integer;
begin
  for i := 0 to FBioManager.Count - 1 do
      FBioManager[i].PositionChanged := True;
end;

procedure TNavigationScene.StopAllMovement;
var
  i: Integer;
begin
  for i := 0 to FBioManager.Count - 1 do
      FBioManager[i].stop;
end;

procedure TNavigationScene.LoadFromStream(stream: TCore_Stream);
var
  r: TDataReader;
  s: TMS64;

  c, i: Integer;
  Poly: TPolyManagerChildren;
begin
  PolyManager.Clear;
  r := TDataReader.Create(stream);

  c := r.ReadInteger;

  s := TMS64.Create;
  r.ReadStream(s);
  PolyManager.Scene.LoadFromStream(s);
  PolyManager.Scene.RemoveSame;
  DisposeObject(s);

  for i := 0 to c - 1 do
    begin
      s := TMS64.Create;
      r.ReadStream(s);
      Poly := TPolyManagerChildren.Create(PolyManager);
      Poly.LoadFromStream(s);
      Poly.RemoveSame;
      Poly.ExpandMode := emConvex;
      PolyManager.Add(Poly);
      DisposeObject(s);
    end;

  DisposeObject(r);
end;

procedure TNavigationScene.SaveToStream(stream: TCore_Stream);
var
  w: TDataWriter;
  s: TMS64;
  i: Integer;
begin
  w := TDataWriter.Create(stream);

  w.WriteInteger(PolyManager.Count);

  s := TMS64.Create;
  PolyManager.Scene.SaveToStream(s);
  w.WriteStream(s);
  DisposeObject(s);

  for i := 0 to PolyManager.Count - 1 do
    begin
      s := TMS64.Create;
      PolyManager[i].SaveToStream(s);
      w.WriteStream(s);
      DisposeObject(s);
    end;

  DisposeObject(w);
end;

procedure TNavigationScene.LoadFromFile(FileName: U_String);
var
  s: TMS64;
begin
  s := TMS64.Create;
  s.LoadFromFile(FileName.Text);
  s.Position := 0;
  LoadFromStream(s);
  DisposeObject(s);
end;

procedure TNavigationScene.SaveToFile(FileName: U_String);
var
  s: TMS64;
begin
  s := TMS64.Create;
  SaveToStream(s);
  s.SaveToFile(FileName.Text);
  DisposeObject(s);
end;

end.
