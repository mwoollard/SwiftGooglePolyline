//
//  String+GooglePolyline.swift
//  SwiftGooglePolyline
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Mark Woollard
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import MapKit

extension String {
    
    private struct CoordinateEncoder {
        
        private struct PointEncoder {
            
            private var previousValue:Int = 0
            
            mutating func encode(coordinate:CLLocationDegrees) -> String {
                
                let intCoord = Int(round(coordinate * 1E5))
                let delta = intCoord - self.previousValue
                self.previousValue = intCoord
                var value = delta << 1;
                if delta < 0 {
                    value = ~value
                }
                
                var encoded = ""
                var hasNext = true
                while(hasNext) {
                    let next = value >> 5
                    var encValue = UInt8(value & 0x1f)
                    hasNext = next > 0
                    if hasNext {
                        encValue = encValue | 0x20
                    }
                    encoded.append(Character(UnicodeScalar(encValue + 0x3f)))
                    value = next
                }
                
                return encoded
            }
        }
        
        private var latitudeEncoder = PointEncoder()
        private var longitudeEncoder = PointEncoder()
        
        mutating func encode(coordinate:CLLocationCoordinate2D) -> String {
            return latitudeEncoder.encode(coordinate.latitude) + longitudeEncoder.encode(coordinate.longitude)
        }
    }
    
    private struct PolylineGenerator : GeneratorType {
        
        typealias Element = CLLocationCoordinate2D
        
        struct Coordinate {
            private var value:Double = 0.0
            mutating func nextValue(polyline:String.UnicodeScalarView, inout index:String.UnicodeScalarView.Index) -> Double? {
                
                if index >= polyline.endIndex {
                    return nil
                }
                
                var byte:Int
                var res:Int = 0
                var shift:Int = 0
                
                repeat {
                    byte = Int(polyline[index].value) - 63;
                    res |= (byte & 0x1F) << shift;
                    shift += 5;
                    index = index.successor()
                } while (byte >= 0x20 && index < polyline.endIndex);
                
                self.value = self.value + Double(((res % 2) == 1) ? ~(res >> 1) : res >> 1);
                
                return self.value * 1E-5
            }
        }
        
        private var polylineUnicodeChars:String.UnicodeScalarView
        private var current:String.UnicodeScalarView.Index
        private var latitude:Coordinate = Coordinate()
        private var longitude:Coordinate = Coordinate()
        
        init(_ polyline:String) {
            self.polylineUnicodeChars = polyline.unicodeScalars
            self.current = self.polylineUnicodeChars.startIndex
        }
        
        mutating func next() -> Element? {
            guard let lat = latitude.nextValue(self.polylineUnicodeChars, index: &self.current), let lng = longitude.nextValue(self.polylineUnicodeChars, index: &self.current) else {
                return nil
            }
            return Element(latitude: lat, longitude: lng)
        }
    }
    
    private struct PolylineSequence : SequenceType {
        
        typealias Generator = PolylineGenerator
        
        private let encodedPolyline:String
        
        init(_ encodedPolyline:String) {
            self.encodedPolyline = encodedPolyline
        }
        
        func generate() -> PolylineGenerator {
            return PolylineGenerator(self.encodedPolyline)
        }
    }
    
    public init<S:SequenceType where S.Generator.Element == CLLocationCoordinate2D>(googlePolylineLocationCoordinateSequence sequence:S) {
        var encoder = CoordinateEncoder()
        self.init(sequence.reduce("") {
            $0 + encoder.encode($1)
        })
    }
    
    public init<S:SequenceType where S.Generator.Element == MKMapPoint>(googlePolylineMapPointSequence sequence:S) {
        self.init(googlePolylineLocationCoordinateSequence:sequence.map { MKCoordinateForMapPoint($0) })
    }

    public init(googlePolylineMKPolyline polyline:MKPolyline) {
        
        var encoder = CoordinateEncoder()

        var count = polyline.pointCount
        var ptr = polyline.points()
        
        var s = ""
        while(count-- > 0) {
            let coord = MKCoordinateForMapPoint(ptr.memory)
            s = s + encoder.encode(coord)
            ptr = ptr.successor()
        }
        
        self.init(s)
    }
    
    public var encodedGooglePolylineAsSequence:AnySequence<CLLocationCoordinate2D> {
        get {
            return AnySequence<CLLocationCoordinate2D>(PolylineSequence(self))
        }
    }
    
    public var encodedGooglePolylineAsArray:Array<CLLocationCoordinate2D> {
        get {
            return Array<CLLocationCoordinate2D>(self.encodedGooglePolylineAsSequence)
        }
    }
    
    public var encodedGooglePolylineAsMKPolyline:MKPolyline {
        get {
            return MKPolyline(sequence:self.encodedGooglePolylineAsSequence)
        }
    }
}
