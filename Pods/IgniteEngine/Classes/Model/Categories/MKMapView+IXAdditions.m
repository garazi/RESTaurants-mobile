//
//  MKMapView+IXAdditions.m
//  Ignite Engine
//
//  Created by Robert Walsh on 6/4/14.
//
/****************************************************************************
 The MIT License (MIT)
 Copyright (c) 2015 Apigee Corporation
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
//

#import "MKMapView+IXAdditions.h"

static CGFloat const kIXMercatorOffset = 268435456;
static CGFloat const kIXMercatorRadius = 85445659.44705395;

@implementation MKMapView (IXAdditions)

#pragma mark -
#pragma mark Map conversion methods

+ (double)ix_longitudeToPixelSpaceX:(double)longitude
{
    return round(kIXMercatorOffset + kIXMercatorRadius * longitude * M_PI / 180.0);
}

+ (double)ix_latitudeToPixelSpaceY:(double)latitude
{
	if (latitude == 90.0) {
		return 0;
	} else if (latitude == -90.0) {
		return kIXMercatorOffset * 2;
	} else {
		return round(kIXMercatorOffset - kIXMercatorRadius * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
	}
}

+ (double)ix_pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - kIXMercatorOffset) / kIXMercatorRadius) * 180.0 / M_PI;
}

+ (double)ix_pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - kIXMercatorOffset) / kIXMercatorRadius))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

- (MKCoordinateSpan)ix_coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [MKMapView ix_longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [MKMapView ix_latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [MKMapView ix_pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [MKMapView ix_pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [MKMapView ix_pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [MKMapView ix_pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

#pragma mark -
#pragma mark Public methods

- (void)ix_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                     zoomLevel:(NSUInteger)zoomLevel
                      animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self ix_coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self setRegion:region animated:animated];
}

//KMapView cannot display tiles that cross the pole (as these would involve wrapping the map from top to bottom, something that a Mercator projection just cannot do).
-(MKCoordinateRegion)ix_coordinateRegionWithMapView:(MKMapView *)mapView
                                   centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                       andZoomLevel:(NSUInteger)zoomLevel
{
	// clamp lat/long values to appropriate ranges
	centerCoordinate.latitude = MIN(MAX(-90.0, centerCoordinate.latitude), 90.0);
	centerCoordinate.longitude = fmod(centerCoordinate.longitude, 180.0);
    
	// convert center coordiate to pixel space
	double centerPixelX = [MKMapView ix_longitudeToPixelSpaceX:centerCoordinate.longitude];
	double centerPixelY = [MKMapView ix_latitudeToPixelSpaceY:centerCoordinate.latitude];
    
	// determine the scale value from the zoom level
	NSInteger zoomExponent = 20 - zoomLevel;
	double zoomScale = pow(2, zoomExponent);
    
	// scale the map’s size in pixel space
	CGSize mapSizeInPixels = mapView.bounds.size;
	double scaledMapWidth = mapSizeInPixels.width * zoomScale;
	double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
	// figure out the position of the left pixel
	double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    
	// find delta between left and right longitudes
	CLLocationDegrees minLng = [MKMapView ix_pixelSpaceXToLongitude:topLeftPixelX];
	CLLocationDegrees maxLng = [MKMapView ix_pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
	CLLocationDegrees longitudeDelta = maxLng - minLng;
    
	// if we’re at a pole then calculate the distance from the pole towards the equator
	// as MKMapView doesn’t like drawing boxes over the poles
	double topPixelY = centerPixelY - (scaledMapHeight / 2);
	double bottomPixelY = centerPixelY + (scaledMapHeight / 2);
	BOOL adjustedCenterPoint = NO;
	if (topPixelY > kIXMercatorOffset * 2) {
		topPixelY = centerPixelY - scaledMapHeight;
		bottomPixelY = kIXMercatorOffset * 2;
		adjustedCenterPoint = YES;
	}
    
	// find delta between top and bottom latitudes
	CLLocationDegrees minLat = [MKMapView ix_pixelSpaceYToLatitude:topPixelY];
	CLLocationDegrees maxLat = [MKMapView ix_pixelSpaceYToLatitude:bottomPixelY];
	CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
	// create and return the lat/lng span
	MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
	MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
	// once again, MKMapView doesn’t like drawing boxes over the poles
	// so adjust the center coordinate to the center of the resulting region
	if (adjustedCenterPoint) {
		region.center.latitude = [MKMapView ix_pixelSpaceYToLatitude:((bottomPixelY + topPixelY) / 2.0)];
	}
    
	return region;
}

- (NSUInteger) ix_zoomLevel {
    MKCoordinateRegion region = self.region;
    
    double centerPixelX = [MKMapView ix_longitudeToPixelSpaceX: region.center.longitude];
    double topLeftPixelX = [MKMapView ix_longitudeToPixelSpaceX: region.center.longitude - region.span.longitudeDelta / 2];
    
    double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
    CGSize mapSizeInPixels = self.bounds.size;
    double zoomScale = scaledMapWidth / mapSizeInPixels.width;
    double zoomExponent = log(zoomScale) / log(2);
    double zoomLevel = 20 - zoomExponent;
    
    return zoomLevel;
}

@end
