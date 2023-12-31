{ ****************************************************************************** }
{ * memory Rasterization AGG support                                           * }
{ ****************************************************************************** }


(*
  ////////////////////////////////////////////////////////////////////////////////
  //                                                                            //
  //  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
  //    Maintained by Christian-W. Budde (Christian@pcjv.de)                    //
  //    Copyright (c) 2012-2017                                                 //
  //                                                                            //
  //  Based on:                                                                 //
  //    Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        //
  //    Copyright (c) 2005-2006, see http://www.aggpas.org                      //
  //                                                                            //
  //  Original License:                                                         //
  //    Anti-Grain Geometry - Version 2.4 (Public License)                      //
  //    Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)     //
  //    Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com                     //
  //                                                                            //
  //  Permission to copy, use, modify, sell and distribute this software        //
  //  is granted provided this copyright notice appears in all copies.          //
  //  This software is provided "as is" without express or implied              //
  //  warranty, and with no claim as to its suitability for any purpose.        //
  //                                                                            //
  ////////////////////////////////////////////////////////////////////////////////
*)
unit PasAI.Agg.ConvClipPolyline;

{$DEFINE FPC_DELPHI_MODE}
{$I PasAI.Define.inc}
interface
uses
  PasAI.Agg.Basics,
  PasAI.Agg.ConvAdaptorVpgen,
  PasAI.Agg.VpGenClipPolyline,
  PasAI.Agg.VertexSource;

type
  TAggConvClipPolyline = class(TAggConvAdaptorVpgen)
  private
    FGenerator: TAggVpgenClipPolyline;
    function GetX1: Double;
    function GetY1: Double;
    function GetX2: Double;
    function GetY2: Double;
  public
    constructor Create(Vs: TAggVertexSource);
    destructor Destroy; override;

    procedure SetClipBox(x1, y1, x2, y2: Double); overload;
    procedure SetClipBox(Bounds: TRectDouble); overload;

    property x1: Double read GetX1;
    property y1: Double read GetY1;
    property x2: Double read GetX2;
    property y2: Double read GetY2;
  end;

implementation


{ TAggConvClipPolyline }

constructor TAggConvClipPolyline.Create;
begin
  FGenerator := TAggVpgenClipPolyline.Create;

  inherited Create(Vs, FGenerator);
end;

destructor TAggConvClipPolyline.Destroy;
begin
  FGenerator.Free;

  inherited;
end;

function TAggConvClipPolyline.GetX1: Double;
begin
  Result := TAggVpgenClipPolyline(FVpGen).x1;
end;

function TAggConvClipPolyline.GetY1: Double;
begin
  Result := TAggVpgenClipPolyline(FVpGen).y1;
end;

function TAggConvClipPolyline.GetX2: Double;
begin
  Result := TAggVpgenClipPolyline(FVpGen).x2;
end;

function TAggConvClipPolyline.GetY2: Double;
begin
  Result := TAggVpgenClipPolyline(FVpGen).y2;
end;

procedure TAggConvClipPolyline.SetClipBox(x1, y1, x2, y2: Double);
begin
  TAggVpgenClipPolyline(FVpGen).SetClipBox(x1, y1, x2, y2);
end;

procedure TAggConvClipPolyline.SetClipBox(Bounds: TRectDouble);
begin
  TAggVpgenClipPolyline(FVpGen).SetClipBox(Bounds);
end;

end.
