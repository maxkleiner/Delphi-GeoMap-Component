unit GeoMap.Projection;

interface

uses
  System.Types, System.Math, GeoMap.Types;

type
  IMapProjection = interface
    ['{B8E9C5D1-4F2E-4A3A-9B1F-8E3C7A6D9F2E}']
    function LatLonToXY(const APoint: TGeoPoint; AWidth, AHeight: Single): TPointF;
    function XYToLatLon(const APoint: TPointF; AWidth, AHeight: Single): TGeoPoint;
    function GetPreferredAspectRatio: Single;
  end;

  TMercatorProjection = class(TInterfacedObject, IMapProjection)
  public
    function LatLonToXY(const APoint: TGeoPoint; AWidth, AHeight: Single): TPointF;
    function XYToLatLon(const APoint: TPointF; AWidth, AHeight: Single): TGeoPoint;
    function GetPreferredAspectRatio: Single;
  end;

  TEquirectangularProjection = class(TInterfacedObject, IMapProjection)
  public
    function LatLonToXY(const APoint: TGeoPoint; AWidth, AHeight: Single): TPointF;
    function XYToLatLon(const APoint: TPointF; AWidth, AHeight: Single): TGeoPoint;
    function GetPreferredAspectRatio: Single;
  end;

implementation

{ TMercatorProjection }

function TMercatorProjection.LatLonToXY(const APoint: TGeoPoint; 
  AWidth, AHeight: Single): TPointF;
var
  X, Y: Double;
  LatRad, MercN: Double;
begin
  // Mercator projection
  // X: Simple linear mapping of longitude
  X := (APoint.Longitude + 180) * (AWidth / 360);
  
  // Y: Mercator formula for latitude
  LatRad := APoint.Latitude * Pi / 180;
  MercN := Ln(Tan(Pi / 4 + LatRad / 2));
  Y := AHeight / 2 - AHeight * MercN / (2 * Pi);
  
  Result := PointF(X, Y);
end;

function TMercatorProjection.XYToLatLon(const APoint: TPointF; 
  AWidth, AHeight: Single): TGeoPoint;
var
  Lon, Lat: Double;
  MercN: Double;
begin
  // Reverse Mercator projection
  Lon := (APoint.X / AWidth) * 360 - 180;
  
  MercN := (AHeight / 2 - APoint.Y) * (2 * Pi) / AHeight;
  Lat := (ArcTan(Exp(MercN)) - Pi / 4) * 2 * 180 / Pi;
  
  Result := TGeoPoint.Create(Lon, Lat);
end;

function TMercatorProjection.GetPreferredAspectRatio: Single;
begin
  Result := 1.0; // 1:1 (square map)
end;

{ TEquirectangularProjection }

function TEquirectangularProjection.LatLonToXY(const APoint: TGeoPoint; 
  AWidth, AHeight: Single): TPointF;
var
  X, Y: Double;
begin
  // Simple equirectangular projection (plate carrée)
  // Linear mapping for both longitude and latitude
  X := (APoint.Longitude + 180) / 360 * AWidth;
  Y := (90 - APoint.Latitude) / 180 * AHeight;
  
  Result := PointF(X, Y);
end;

function TEquirectangularProjection.XYToLatLon(const APoint: TPointF; 
  AWidth, AHeight: Single): TGeoPoint;
var
  Lon, Lat: Double;
begin
  // Reverse equirectangular projection
  Lon := (APoint.X / AWidth) * 360 - 180;
  Lat := 90 - (APoint.Y / AHeight) * 180;
  
  Result := TGeoPoint.Create(Lon, Lat);
end;

function TEquirectangularProjection.GetPreferredAspectRatio: Single;
begin
  Result := 2.0; // 2:1 (twice as wide as tall)
end;

end.

