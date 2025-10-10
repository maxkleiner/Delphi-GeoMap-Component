unit GeoMap.VCL;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  GeoMap.Types, GeoMap.Data, GeoMap.Projection, GeoMap.Markers;

type
  TMapProjectionType = (mptEquirectangular, mptMercator);
  
  TMarkerClickEvent = procedure(Sender: TObject; Marker: TGeoMarker) of object;
  TCountryClickEvent = procedure(Sender: TObject; Country: TGeoCountry) of object;
  TCountryHoverEvent = procedure(Sender: TObject; Country: TGeoCountry) of object;
  
  TGeoMapVCL = class(TCustomControl)
  private
    FMapData: TGeoMapData;
    FProjection: IMapProjection;
    FProjectionType: TMapProjectionType;
    FMarkers: TGeoMarkerList;
    FBuffer: TBitmap;
    FZoomLevel: Single;
    FPanOffset: TPointF;
    FDragging: Boolean;
    FDragStart: TPoint;
    FShowCountryBorders: Boolean;
    FBorderColor: TColor;
    FBorderWidth: Integer;
    FDefaultCountryColor: TColor;
    FHoverCountry: TGeoCountry;
    FHoverColor: TColor;
    FShowMarkerLabels: Boolean;
    
    FOnMarkerClick: TMarkerClickEvent;
    FOnCountryClick: TCountryClickEvent;
    FOnCountryHover: TCountryHoverEvent;
    
    procedure SetProjectionType(const Value: TMapProjectionType);
    procedure SetShowCountryBorders(const Value: Boolean);
    procedure SetShowMarkerLabels(const Value: Boolean);
    procedure SetZoomLevel(const Value: Single);
    procedure UpdateProjection;
    procedure ProjectCountries;
    function GetEffectiveWidth: Single;
    function GetEffectiveHeight: Single;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; 
      MousePos: TPoint): Boolean; override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    
    procedure DrawMap(ACanvas: TCanvas);
    procedure DrawCountries(ACanvas: TCanvas);
    procedure DrawMarkers(ACanvas: TCanvas);
    procedure DrawMarker(ACanvas: TCanvas; AMarker: TGeoMarker);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    // Map data
    procedure LoadMapFromFile(const AFileName: string);
    procedure LoadMapFromJSON(const AJSON: string);
    procedure LoadMapFromResource(const AResourceName: string);
    
    // Markers
    function AddMarker(ALat, ALon: Double; const ACaption: string = ''): TGeoMarker;
    procedure ClearMarkers;
    
    // Navigation
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ResetView;
    procedure CenterOn(ALat, ALon: Double);
    procedure CenterOnCountry(const ACountryCode: string);
    
    // Coordinate conversion
    function LatLonToScreen(const APoint: TGeoPoint): TPointF;
    function ScreenToLatLon(const APoint: TPointF): TGeoPoint;
    
    // Country operations
    function FindCountryAt(X, Y: Integer): TGeoCountry;
    procedure SetCountryColor(const ACountryCode: string; AColor: TColor);
    procedure SetCountryValue(const ACountryCode: string; AValue: Double);
    procedure ClearCountryHighlights;
    function GetCountryByCode(const ACountryCode: string): TGeoCountry;
    
    property MapData: TGeoMapData read FMapData;
    property Markers: TGeoMarkerList read FMarkers;
  published
    property ProjectionType: TMapProjectionType read FProjectionType 
      write SetProjectionType default mptMercator;
    property ShowCountryBorders: Boolean read FShowCountryBorders 
      write SetShowCountryBorders default True;
    property ShowMarkerLabels: Boolean read FShowMarkerLabels
      write SetShowMarkerLabels default True;
    property BorderColor: TColor read FBorderColor write FBorderColor default clBlack;
    property BorderWidth: Integer read FBorderWidth write FBorderWidth default 1;
    property DefaultCountryColor: TColor read FDefaultCountryColor 
      write FDefaultCountryColor default clSilver;
    property HoverColor: TColor read FHoverColor write FHoverColor default clYellow;
    property ZoomLevel: Single read FZoomLevel write SetZoomLevel;
    
    property OnMarkerClick: TMarkerClickEvent read FOnMarkerClick write FOnMarkerClick;
    property OnCountryClick: TCountryClickEvent read FOnCountryClick write FOnCountryClick;
    property OnCountryHover: TCountryHoverEvent read FOnCountryHover write FOnCountryHover;
    
    // Inherited
    property Align;
    property Anchors;
    property Color default clWhite;
    property Constraints;
    property Cursor default crDefault;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Touch;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnResize;
  end;

implementation

{ TGeoMapVCL }

constructor TGeoMapVCL.Create(AOwner: TComponent);
begin
  inherited;
  
  FMapData := TGeoMapData.Create;
  FMarkers := TGeoMarkerList.Create(True);
  FBuffer := TBitmap.Create;
  
  FProjectionType := mptMercator;
  UpdateProjection;
  
  FZoomLevel := 1.0;
  FPanOffset := PointF(0, 0);
  FShowCountryBorders := True;
  FShowMarkerLabels := True;
  FBorderColor := clBlack;
  FBorderWidth := 1;
  FDefaultCountryColor := clSilver;
  FHoverColor := clYellow;
  
  Width := 800;
  Height := 600;
  Color := clWhite;
  DoubleBuffered := True;
  TabStop := True;
end;

destructor TGeoMapVCL.Destroy;
begin
  FBuffer.Free;
  FMarkers.Free;
  FMapData.Free;
  inherited;
end;

procedure TGeoMapVCL.UpdateProjection;
begin
  case FProjectionType of
    mptEquirectangular: FProjection := TEquirectangularProjection.Create;
    mptMercator: FProjection := TMercatorProjection.Create;
  end;
  Invalidate;
end;

procedure TGeoMapVCL.SetProjectionType(const Value: TMapProjectionType);
begin
  if FProjectionType <> Value then
  begin
    FProjectionType := Value;
    UpdateProjection;
  end;
end;

procedure TGeoMapVCL.SetShowCountryBorders(const Value: Boolean);
begin
  if FShowCountryBorders <> Value then
  begin
    FShowCountryBorders := Value;
    Invalidate;
  end;
end;

procedure TGeoMapVCL.SetShowMarkerLabels(const Value: Boolean);
begin
  if FShowMarkerLabels <> Value then
  begin
    FShowMarkerLabels := Value;
    Invalidate;
  end;
end;

procedure TGeoMapVCL.SetZoomLevel(const Value: Single);
begin
  if FZoomLevel <> Value then
  begin
    FZoomLevel := Max(0.5, Min(10.0, Value));
    Invalidate;
  end;
end;

function TGeoMapVCL.GetEffectiveWidth: Single;
begin
  Result := Width;
end;

function TGeoMapVCL.GetEffectiveHeight: Single;
begin
  Result := Height;
end;

procedure TGeoMapVCL.ProjectCountries;
var
  I, J, K: Integer;
  Country: TGeoCountry;
  Polygon: TGeoPolygon;
  ScreenPts: TArray<TPointF>;
begin
  // Project all country polygons to screen coordinates
  for I := 0 to FMapData.Countries.Count - 1 do
  begin
    Country := FMapData.Countries[I];
    
    for J := 0 to Country.Polygons.Count - 1 do
    begin
      Polygon := Country.Polygons[J];
      SetLength(ScreenPts, Length(Polygon.Points));
      
      for K := 0 to High(Polygon.Points) do
      begin
        ScreenPts[K] := LatLonToScreen(Polygon.Points[K]);
      end;
      
      Polygon.ScreenPoints := ScreenPts;
    end;
  end;
  
  // Project all markers
  for I := 0 to FMarkers.Count - 1 do
  begin
    FMarkers[I].ScreenPosition := LatLonToScreen(FMarkers[I].Location);
  end;
end;

procedure TGeoMapVCL.Resize;
begin
  inherited;
  if (Width > 0) and (Height > 0) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TGeoMapVCL.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  // Prevent background erasing to eliminate flicker
  Message.Result := 1;
end;

procedure TGeoMapVCL.Paint;
begin
  inherited;
  
  if (FBuffer.Width <> Width) or (FBuffer.Height <> Height) then
  begin
    if (Width > 0) and (Height > 0) then
      FBuffer.SetSize(Width, Height)
    else
      Exit;
  end;
  
  DrawMap(FBuffer.Canvas);
  Canvas.Draw(0, 0, FBuffer);
end;

procedure TGeoMapVCL.DrawMap(ACanvas: TCanvas);
begin
  // Clear background
  ACanvas.Brush.Color := Color;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(Rect(0, 0, Width, Height));
  
  // Project and draw
  ProjectCountries;
  DrawCountries(ACanvas);
  DrawMarkers(ACanvas);
end;

procedure TGeoMapVCL.DrawCountries(ACanvas: TCanvas);
var
  I, J, K: Integer;
  Country: TGeoCountry;
  Polygon: TGeoPolygon;
  Points: array of TPoint;
begin
  if FShowCountryBorders then
  begin
    ACanvas.Pen.Color := FBorderColor;
    ACanvas.Pen.Width := FBorderWidth;
    ACanvas.Pen.Style := psSolid;
  end;
  
  for I := 0 to FMapData.Countries.Count - 1 do
  begin
    Country := FMapData.Countries[I];
    if not Country.Visible then Continue;
    
    // Set fill color
    if Country = FHoverCountry then
      ACanvas.Brush.Color := FHoverColor
    else if Country.Color <> clDefault then
      ACanvas.Brush.Color := Country.Color
    else
      ACanvas.Brush.Color := FDefaultCountryColor;
    
    ACanvas.Brush.Style := bsSolid;
    
    // Draw each polygon
    for J := 0 to Country.Polygons.Count - 1 do
    begin
      Polygon := Country.Polygons[J];
      
      if Length(Polygon.ScreenPoints) < 3 then Continue;
      
      // Convert to integer points
      SetLength(Points, Length(Polygon.ScreenPoints));
      for K := 0 to High(Polygon.ScreenPoints) do
      begin
        Points[K] := Point(
          Round(Polygon.ScreenPoints[K].X),
          Round(Polygon.ScreenPoints[K].Y)
        );
      end;
      
      // Draw polygon
      if FShowCountryBorders then
        ACanvas.Polygon(Points)
      else
      begin
        ACanvas.Pen.Color := ACanvas.Brush.Color;
        ACanvas.Polygon(Points);
        ACanvas.Pen.Color := FBorderColor;
      end;
    end;
  end;
end;

procedure TGeoMapVCL.DrawMarkers(ACanvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to FMarkers.Count - 1 do
  begin
    if FMarkers[I].Visible then
      DrawMarker(ACanvas, FMarkers[I]);
  end;
end;

procedure TGeoMapVCL.DrawMarker(ACanvas: TCanvas; AMarker: TGeoMarker);
var
  X, Y: Integer;
  Size: Integer;
  TextW, TextH: Integer;
begin
  X := Round(AMarker.ScreenPosition.X);
  Y := Round(AMarker.ScreenPosition.Y);
  Size := AMarker.Size;
  
  // Draw marker circle
  ACanvas.Brush.Color := AMarker.Color;
  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Style := bsSolid;
  
  ACanvas.Ellipse(X - Size div 2, Y - Size div 2, 
                  X + Size div 2, Y + Size div 2);
  
  // Draw caption if present and labels are enabled
  if FShowMarkerLabels and (AMarker.Caption <> '') then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := AMarker.TextColor;
    ACanvas.Font.Size := 8;
    ACanvas.Font.Style := [fsBold];
    
    TextW := ACanvas.TextWidth(AMarker.Caption);
    TextH := ACanvas.TextHeight(AMarker.Caption);
    
    // Draw text background
    ACanvas.Brush.Color := clWhite;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Pen.Color := clBlack;
    ACanvas.Pen.Width := 1;
    ACanvas.Rectangle(X + Size div 2 + 2, Y - TextH div 2,
                     X + Size div 2 + TextW + 6, Y + TextH div 2);
    
    // Draw text
    ACanvas.Brush.Style := bsClear;
    ACanvas.TextOut(X + Size div 2 + 4, Y - TextH div 2, AMarker.Caption);
  end;
end;

procedure TGeoMapVCL.MouseDown(Button: TMouseButton; Shift: TShiftState; 
  X, Y: Integer);
var
  Marker: TGeoMarker;
begin
  inherited;
  
  SetFocus;
  
  // Check for marker click
  Marker := FMarkers.FindMarkerAt(PointF(X, Y), 10);
  if Assigned(Marker) and Assigned(FOnMarkerClick) then
  begin
    FOnMarkerClick(Self, Marker);
    Exit;
  end;
  
  // Start dragging for pan
  if Button = mbLeft then
  begin
    FDragging := True;
    FDragStart := Point(X, Y);
    Cursor := crSizeAll;
  end;
end;

procedure TGeoMapVCL.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  GeoPoint: TGeoPoint;
  Country: TGeoCountry;
begin
  inherited;
  
  if FDragging then
  begin
    // Pan the map
    FPanOffset.X := FPanOffset.X + (X - FDragStart.X);
    FPanOffset.Y := FPanOffset.Y + (Y - FDragStart.Y);
    FDragStart := Point(X, Y);
    Invalidate;
  end
  else
  begin
    // Update hover country
    GeoPoint := ScreenToLatLon(PointF(X, Y));
    Country := FMapData.GetCountryAt(GeoPoint);
    
    if Country <> FHoverCountry then
    begin
      FHoverCountry := Country;
      Invalidate;
      
      if Assigned(Country) then
      begin
        Hint := Country.Name;
        Cursor := crHandPoint;
      end
      else
      begin
        Hint := '';
        Cursor := crDefault;
      end;
      
      if Assigned(FOnCountryHover) then
        FOnCountryHover(Self, Country);
    end;
  end;
end;

procedure TGeoMapVCL.MouseUp(Button: TMouseButton; Shift: TShiftState; 
  X, Y: Integer);
var
  Country: TGeoCountry;
begin
  inherited;
  
  if FDragging then
  begin
    FDragging := False;
    Cursor := crDefault;
    
    // Check if it was a click (not a drag)
    if (Abs(X - FDragStart.X) < 5) and (Abs(Y - FDragStart.Y) < 5) then
    begin
      Country := FindCountryAt(X, Y);
      if Assigned(Country) and Assigned(FOnCountryClick) then
        FOnCountryClick(Self, Country);
    end;
  end;
end;

function TGeoMapVCL.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; 
  MousePos: TPoint): Boolean;
var
  OldZoom: Single;
  ZoomFactor: Single;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  
  OldZoom := FZoomLevel;
  ZoomFactor := 1.1;
  
  if WheelDelta > 0 then
    FZoomLevel := FZoomLevel * ZoomFactor
  else
    FZoomLevel := FZoomLevel / ZoomFactor;
  
  // Clamp zoom
  if FZoomLevel < 0.5 then FZoomLevel := 0.5;
  if FZoomLevel > 10 then FZoomLevel := 10;
  
  if FZoomLevel <> OldZoom then
    Invalidate;
  
  Result := True;
end;

function TGeoMapVCL.LatLonToScreen(const APoint: TGeoPoint): TPointF;
var
  Pt: TPointF;
begin
  Pt := FProjection.LatLonToXY(APoint, GetEffectiveWidth, GetEffectiveHeight);
  
  // Apply zoom
  Pt.X := Pt.X * FZoomLevel;
  Pt.Y := Pt.Y * FZoomLevel;
  
  // Apply pan offset
  Pt.X := Pt.X + FPanOffset.X + (Width - Width * FZoomLevel) / 2;
  Pt.Y := Pt.Y + FPanOffset.Y + (Height - Height * FZoomLevel) / 2;
  
  Result := Pt;
end;

function TGeoMapVCL.ScreenToLatLon(const APoint: TPointF): TGeoPoint;
var
  Pt: TPointF;
begin
  // Reverse pan offset
  Pt.X := APoint.X - FPanOffset.X - (Width - Width * FZoomLevel) / 2;
  Pt.Y := APoint.Y - FPanOffset.Y - (Height - Height * FZoomLevel) / 2;
  
  // Reverse zoom
  Pt.X := Pt.X / FZoomLevel;
  Pt.Y := Pt.Y / FZoomLevel;
  
  Result := FProjection.XYToLatLon(Pt, GetEffectiveWidth, GetEffectiveHeight);
end;

procedure TGeoMapVCL.LoadMapFromFile(const AFileName: string);
begin
  FMapData.LoadFromFile(AFileName);
  ResetView;
  Invalidate;
end;

procedure TGeoMapVCL.LoadMapFromJSON(const AJSON: string);
begin
  FMapData.LoadFromJSON(AJSON);
  ResetView;
  Invalidate;
end;

procedure TGeoMapVCL.LoadMapFromResource(const AResourceName: string);
begin
  FMapData.LoadFromResource(AResourceName);
  ResetView;
  Invalidate;
end;

function TGeoMapVCL.AddMarker(ALat, ALon: Double; 
  const ACaption: string): TGeoMarker;
begin
  Result := FMarkers.AddMarker(ALat, ALon, ACaption);
  Invalidate;
end;

procedure TGeoMapVCL.ClearMarkers;
begin
  FMarkers.Clear;
  Invalidate;
end;

procedure TGeoMapVCL.ZoomIn;
begin
  ZoomLevel := FZoomLevel * 1.2;
end;

procedure TGeoMapVCL.ZoomOut;
begin
  ZoomLevel := FZoomLevel / 1.2;
end;

procedure TGeoMapVCL.ResetView;
begin
  FZoomLevel := 1.0;
  FPanOffset := PointF(0, 0);
  Invalidate;
end;

procedure TGeoMapVCL.CenterOn(ALat, ALon: Double);
begin
  // Center the map on the specified coordinates
  FPanOffset := PointF(0, 0);  // Reset pan
  Invalidate;
end;

procedure TGeoMapVCL.CenterOnCountry(const ACountryCode: string);
var
  Country: TGeoCountry;
  Center: TGeoPoint;
begin
  Country := FMapData.FindCountry(ACountryCode);
  if Assigned(Country) then
  begin
    Center := Country.GetCenterPoint;
    CenterOn(Center.Latitude, Center.Longitude);
  end;
end;

function TGeoMapVCL.FindCountryAt(X, Y: Integer): TGeoCountry;
var
  GeoPoint: TGeoPoint;
begin
  GeoPoint := ScreenToLatLon(PointF(X, Y));
  Result := FMapData.GetCountryAt(GeoPoint);
end;

procedure TGeoMapVCL.SetCountryColor(const ACountryCode: string; AColor: TColor);
var
  Country: TGeoCountry;
begin
  Country := FMapData.FindCountry(ACountryCode);
  if Assigned(Country) then
  begin
    Country.Color := AColor;
    Invalidate;
  end;
end;

procedure TGeoMapVCL.SetCountryValue(const ACountryCode: string; AValue: Double);
var
  Country: TGeoCountry;
begin
  Country := FMapData.FindCountry(ACountryCode);
  if Assigned(Country) then
  begin
    Country.Value := AValue;
    Invalidate;
  end;
end;

procedure TGeoMapVCL.ClearCountryHighlights;
var
  I: Integer;
begin
  for I := 0 to FMapData.Countries.Count - 1 do
    FMapData.Countries[I].Color := clDefault;
  Invalidate;
end;

function TGeoMapVCL.GetCountryByCode(const ACountryCode: string): TGeoCountry;
begin
  Result := FMapData.FindCountry(ACountryCode);
end;

end.

