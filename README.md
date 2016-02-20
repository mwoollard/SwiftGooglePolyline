## Swift Google Polylines
Google's direction API provides points along route segments as an encoded string. For example the encoded string:

```_p~iF~ps|U_ulLnnqC_mqNvxq`@``` 

decodes to the coordinate points: 

`(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)`

Full details of the algorithm used can be found [here](ttps://developers.google.com/maps/documentation/utilities/polylinealgorithm).

The Swift extensions provided here support encoding and decoding to and from the `String` and `MKPolyline` classes.

## Usage
Examples of usage
#### Decoding
```
let googlePolyline = "`_p~iF~ps|U_ulLnnqC_mqNvxq`@"

// Get lazy sequence of CLLocationCoordinate2D 
let seq = googlePolyline.encodedGooglePolylineAsSequence

// Get array of CLLocationCoordinate2D
let array = googlePolyline.encodedGooglePolylineAsArray

// Get MKPolyline
let polyline = googlePolyline.encodedGooglePolylineAsMKPolyline
let anotherPolyline = MKPolyline(encodedGooglePolyline:googlePolyline)
```
#### Encoding
```
let googlePolyline = "`_p~iF~ps|U_ulLnnqC_mqNvxq`@"
let polyline = MKPolyline(encodedGooglePolyline:googlePolyline)
let points = [
    CLLocationCoordinate2D(latitude: 38.5, longitude: -120.2),
    CLLocationCoordinate2D(latitude: 40.7, longitude: -120.95),
    CLLocationCoordinate2D(latitude: 43.252, longitude: -126.453)
]

// Encode from sequence of CLLocationCoordinate2D
let encodedFromPoints = String(googlePolylineLocationCoordinateSequence:points)

// Encode from sequence of MKMapPoint
let encodedFromMapPoints = String(googlePolylineMapPointSequence:
	points.map { MKMapPointForCoordinate($0) })

// Encode from MKPolyline
let encodedFromPolyline = String(googlePolylineMKPolyline:polyline)
let anotherEncodedFromPolyline = polyline.googlePolyline
```
## Credits
This library has been created by Mark Woollard and has been made available under the **MIT License**. Please see the `LICENSE` file for more information.
