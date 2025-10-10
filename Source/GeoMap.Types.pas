unit GeoMap.Types;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  System.UITypes, Vcl.Graphics;

type
  TGeoPoint = record
    Longitude: Double;  // -180 to +180
    Latitude: Double;   // -90 to +90
    constructor Create(ALon, ALat: Double);
    function ToString: string;
    function IsValid: Boolean;
  end;

  TGeoPolygon = class
  private
    FPoints: TArray<TGeoPoint>;
    FScreenPoints: TArray<TPointF>;
    FBounds: TRectF;
    FScreenBoundsValid: Boolean;
    procedure CalculateBounds;
  public
    constructor Create(const APoints: TArray<TGeoPoint>);
    property Points: TArray<TGeoPoint> read FPoints;
    property ScreenPoints: TArray<TPointF> read FScreenPoints write FScreenPoints;
    property Bounds: TRectF read FBounds;
    procedure InvalidateScreenCache;
  end;

  TGeoCountry = class
  private
    FCode: string;
    FName: string;
    FPolygons: TObjectList<TGeoPolygon>;
    FBounds: TRectF;
    FColor: TColor;
    FValue: Double;
    FVisible: Boolean;
    procedure CalculateBounds;
  public
    constructor Create(const ACode, AName: string);
    destructor Destroy; override;
    procedure AddPolygon(APolygon: TGeoPolygon);
    function GetCenterPoint: TGeoPoint;
    
    property Code: string read FCode;
    property Name: string read FName write FName;
    property Polygons: TObjectList<TGeoPolygon> read FPolygons;
    property Bounds: TRectF read FBounds;
    property Color: TColor read FColor write FColor;
    property Value: Double read FValue write FValue;
    property Visible: Boolean read FVisible write FVisible;
  end;

implementation

{ TGeoPoint }

constructor TGeoPoint.Create(ALon, ALat: Double);
begin
  Longitude := ALon;
  Latitude := ALat;
end;

function TGeoPoint.ToString: string;
begin
  Result := Format('%.6f°, %.6f°', [Latitude, Longitude]);
end;

function TGeoPoint.IsValid: Boolean;
begin
  Result := (Longitude >= -180) and (Longitude <= 180) and
            (Latitude >= -90) and (Latitude <= 90);
end;

{ TGeoPolygon }

constructor TGeoPolygon.Create(const APoints: TArray<TGeoPoint>);
begin
  FPoints := APoints;
  CalculateBounds;
  FScreenBoundsValid := False;
end;

procedure TGeoPolygon.CalculateBounds;
var
  I: Integer;
  MinLon, MaxLon, MinLat, MaxLat: Double;
begin
  if Length(FPoints) = 0 then Exit;
  
  MinLon := FPoints[0].Longitude;
  MaxLon := MinLon;
  MinLat := FPoints[0].Latitude;
  MaxLat := MinLat;
  
  for I := 1 to High(FPoints) do
  begin
    if FPoints[I].Longitude < MinLon then MinLon := FPoints[I].Longitude;
    if FPoints[I].Longitude > MaxLon then MaxLon := FPoints[I].Longitude;
    if FPoints[I].Latitude < MinLat then MinLat := FPoints[I].Latitude;
    if FPoints[I].Latitude > MaxLat then MaxLat := FPoints[I].Latitude;
  end;
  
  FBounds := RectF(MinLon, MinLat, MaxLon, MaxLat);
end;

procedure TGeoPolygon.InvalidateScreenCache;
begin
  FScreenBoundsValid := False;
  SetLength(FScreenPoints, 0);
end;

{ TGeoCountry }

constructor TGeoCountry.Create(const ACode, AName: string);
begin
  FCode := LowerCase(ACode);
  FName := AName;
  FPolygons := TObjectList<TGeoPolygon>.Create(True);
  FVisible := True;
  FColor := clDefault;  // Use default color (means "not set")
  FValue := 0;
end;

destructor TGeoCountry.Destroy;
begin
  FPolygons.Free;
  inherited;
end;

procedure TGeoCountry.AddPolygon(APolygon: TGeoPolygon);
begin
  FPolygons.Add(APolygon);
  CalculateBounds;
end;

procedure TGeoCountry.CalculateBounds;
var
  I: Integer;
  MinX, MaxX, MinY, MaxY: Double;
  First: Boolean;
begin
  if FPolygons.Count = 0 then Exit;
  
  First := True;
  MinX := 0; MaxX := 0; MinY := 0; MaxY := 0;
  
  for I := 0 to FPolygons.Count - 1 do
  begin
    if First then
    begin
      MinX := FPolygons[I].Bounds.Left;
      MaxX := FPolygons[I].Bounds.Right;
      MinY := FPolygons[I].Bounds.Top;
      MaxY := FPolygons[I].Bounds.Bottom;
      First := False;
    end
    else
    begin
      if FPolygons[I].Bounds.Left < MinX then MinX := FPolygons[I].Bounds.Left;
      if FPolygons[I].Bounds.Right > MaxX then MaxX := FPolygons[I].Bounds.Right;
      if FPolygons[I].Bounds.Top < MinY then MinY := FPolygons[I].Bounds.Top;
      if FPolygons[I].Bounds.Bottom > MaxY then MaxY := FPolygons[I].Bounds.Bottom;
    end;
  end;
  
  FBounds := RectF(MinX, MinY, MaxX, MaxY);
end;

function TGeoCountry.GetCenterPoint: TGeoPoint;
begin
  Result := TGeoPoint.Create(
    (FBounds.Left + FBounds.Right) / 2,
    (FBounds.Top + FBounds.Bottom) / 2
  );
end;

end.

