unit GeoMap.Markers;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, Vcl.Graphics, GeoMap.Types;

type
  TGeoMarker = class
  private
    FLocation: TGeoPoint;
    FScreenPosition: TPointF;
    FCaption: string;
    FColor: TColor;
    FSize: Integer;
    FVisible: Boolean;
    FData: TObject;
    FTag: Integer;
    FHint: string;
    FTextColor: TColor;
  public
    constructor Create(const ALocation: TGeoPoint); overload;
    constructor Create(ALat, ALon: Double); overload;
    
    property Location: TGeoPoint read FLocation write FLocation;
    property ScreenPosition: TPointF read FScreenPosition write FScreenPosition;
    property Caption: string read FCaption write FCaption;
    property Color: TColor read FColor write FColor;
    property TextColor: TColor read FTextColor write FTextColor;
    property Size: Integer read FSize write FSize;
    property Visible: Boolean read FVisible write FVisible;
    property Data: TObject read FData write FData;
    property Tag: Integer read FTag write FTag;
    property Hint: string read FHint write FHint;
  end;

  TGeoMarkerList = class(TObjectList<TGeoMarker>)
  public
    function AddMarker(const ALocation: TGeoPoint; 
      const ACaption: string = ''): TGeoMarker; overload;
    function AddMarker(ALat, ALon: Double; 
      const ACaption: string = ''): TGeoMarker; overload;
    function FindMarkerAt(const APoint: TPointF; ATolerance: Single = 10): TGeoMarker;
  end;

implementation

{ TGeoMarker }

constructor TGeoMarker.Create(const ALocation: TGeoPoint);
begin
  FLocation := ALocation;
  FColor := clRed;
  FTextColor := clBlack;
  FSize := 10;
  FVisible := True;
  FTag := 0;
  FCaption := '';
  FHint := '';
end;

constructor TGeoMarker.Create(ALat, ALon: Double);
begin
  Create(TGeoPoint.Create(ALon, ALat));
end;

{ TGeoMarkerList }

function TGeoMarkerList.AddMarker(const ALocation: TGeoPoint; 
  const ACaption: string): TGeoMarker;
begin
  Result := TGeoMarker.Create(ALocation);
  Result.Caption := ACaption;
  Add(Result);
end;

function TGeoMarkerList.AddMarker(ALat, ALon: Double; 
  const ACaption: string): TGeoMarker;
begin
  Result := AddMarker(TGeoPoint.Create(ALon, ALat), ACaption);
end;

function TGeoMarkerList.FindMarkerAt(const APoint: TPointF; 
  ATolerance: Single): TGeoMarker;
var
  I: Integer;
  Dist: Single;
  MinDist: Single;
  ClosestMarker: TGeoMarker;
begin
  Result := nil;
  MinDist := MaxSingle;
  ClosestMarker := nil;
  
  for I := 0 to Count - 1 do
  begin
    if not Items[I].Visible then Continue;
    
    Dist := Sqrt(
      Sqr(Items[I].ScreenPosition.X - APoint.X) + 
      Sqr(Items[I].ScreenPosition.Y - APoint.Y)
    );
    
    if (Dist <= ATolerance) and (Dist < MinDist) then
    begin
      MinDist := Dist;
      ClosestMarker := Items[I];
    end;
  end;
  
  Result := ClosestMarker;
end;

end.

