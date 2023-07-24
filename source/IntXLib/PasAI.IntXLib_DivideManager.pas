// https://github.com/Xor-el/IntXLib4Pascal
unit PasAI.IntXLib_DivideManager;


{$I PasAI.IntXLib.inc}

interface

uses

  PasAI.IntXLib_IDivider,
  PasAI.IntXLib_Enums,
  PasAI.IntXLib_ClassicDivider,
  PasAI.IntXLib_AutoNewtonDivider,
  PasAI.IntXLib,
  PasAI.IntXLib_Types;

type
  /// <summary>
  /// Used to retrieve needed divider.
  /// </summary>

  TDivideManager = class(TObject)

  public
    /// <summary>
    /// Constructor.
    /// </summary>
    class constructor Create();

    /// <summary>
    /// Returns divider instance for given divide mode.
    /// </summary>
    /// <param name="mode">Divide mode.</param>
    /// <returns>Divider instance.</returns>
    /// <exception cref="EArgumentOutOfRangeException"><paramref name="mode" /> is out of range.</exception>

    class function GetDivider(mode: TDivideMode): IIDivider;

    /// <summary>
    /// Returns current divider instance.
    /// </summary>
    /// <returns>Current divider instance.</returns>

    class function GetCurrentDivider(): IIDivider;

  class var
    /// <summary>
    /// Classic divider instance.
    /// </summary>

    FClassicDivider: IIDivider;

    /// <summary>
    /// Newton divider instance.
    /// </summary>

    FAutoNewtonDivider: IIDivider;

  end;

implementation

// static class constructor
class constructor TDivideManager.Create();
var
  mclassicDivider: IIDivider;
begin
  // Create new classic divider instance
  mclassicDivider := TClassicDivider.Create;

  // Fill publicity visible divider fields
  FClassicDivider := mclassicDivider;
  FAutoNewtonDivider := TAutoNewtonDivider.Create(mclassicDivider);
end;

class function TDivideManager.GetDivider(mode: TDivideMode): IIDivider;
begin
  case (mode) of

    TDivideMode.dmAutoNewton:
      begin
        result := FAutoNewtonDivider;
        Exit;
      end;
    TDivideMode.dmClassic:
      begin
        result := FClassicDivider;
        Exit;
      end
  else
    begin
      raise EArgumentOutOfRangeException.Create('mode');
    end;

  end;

end;

class function TDivideManager.GetCurrentDivider(): IIDivider;
begin
  result := GetDivider(TIntX.GlobalSettings.DivideMode);
end;

end.
