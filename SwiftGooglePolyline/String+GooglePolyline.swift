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

public extension String {
  init<S: Sequence>(googlePolylineLocationCoordinateSequence sequence:S)
  where S.Iterator.Element == CLLocationCoordinate2D {
    var encoder = CoordinateEncoder()
    self.init(sequence.reduce("") {
      $0 + encoder.encode(coordinate: $1)
    })
  }
  
  init<S: Sequence>(googlePolylineMapPointSequence sequence: S)
  where S.Iterator.Element == MKMapPoint {
    self.init(googlePolylineLocationCoordinateSequence:sequence.map { $0.coordinate })
  }
  
  init(googlePolylineMKMultiPoint polyline: MKMultiPoint) {
    
    var encoder = CoordinateEncoder()
    
    var count = polyline.pointCount
    var ptr = polyline.points()
    
    var s = ""
    while(count > 0) {
      count -= 1
      let coord = ptr.pointee.coordinate
      s = s + encoder.encode(coordinate: coord)
      ptr = ptr.successor()
    }
    
    self.init(s)
  }
  
  func makeCoordinateSequenceFromGooglePolyline() throws -> AnySequence<CLLocationCoordinate2D> {
    return AnySequence<CLLocationCoordinate2D>(try PolylineSequence(self))
  }
  
  func makeCoordinateArrayFromGooglePolyline() throws -> [CLLocationCoordinate2D] {
    return [CLLocationCoordinate2D](try self.makeCoordinateSequenceFromGooglePolyline())
  }
  
  func makeMKPolylineFromGooglePolyline() throws -> MKPolyline {
    return MKPolyline(sequence:try self.makeCoordinateSequenceFromGooglePolyline())
  }
}

// MARK: - CoordinateEncoder
private struct CoordinateEncoder {
  private struct PointEncoder {
    private var previousValue = 0
    
    mutating func encode(coordinate: CLLocationDegrees) -> String {
      
      let intCoord = Int(round(coordinate * 1E5))
      let delta = intCoord - self.previousValue
      self.previousValue = intCoord
      var value = delta << 1
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
    return latitudeEncoder.encode(coordinate: coordinate.latitude) + longitudeEncoder.encode(coordinate: coordinate.longitude)
  }
}

// MARK: - PolylineIterator
private struct PolylineIterator: IteratorProtocol {
  typealias Element = CLLocationCoordinate2D
  struct Coordinate {
    private var value = 0.0
    mutating func nextValue(
      polyline: String.UnicodeScalarView,
      index: inout String.UnicodeScalarView.Index) -> Double? {
        
        if index >= polyline.endIndex {
          return nil
        }
        
        var byte:Int
        var res:Int = 0
        var shift:Int = 0
        
        repeat {
          byte = Int(polyline[index].value) - 63
          if !(0..<64 ~= byte) {
            return nil
          }
          res |= (byte & 0x1F) << shift
          shift += 5
          index = polyline.index(index, offsetBy: 1)
        } while (byte >= 0x20 && index < polyline.endIndex)
        
        self.value += Double(((res % 2) == 1) ? ~(res >> 1) : res >> 1)
        
        return self.value * 1E-5
      }
  }
  
  private var polylineUnicodeChars: String.UnicodeScalarView
  private var current: String.UnicodeScalarView.Index
  private var latitude = Coordinate()
  private var longitude = Coordinate()
  
  init(_ polyline: String) {
    self.polylineUnicodeChars = polyline.unicodeScalars
    self.current = self.polylineUnicodeChars.startIndex
  }
  
  mutating func next() -> Element? {
    guard
      let lat = latitude.nextValue(polyline: self.polylineUnicodeChars, index: &self.current),
      let lng = longitude.nextValue(polyline: self.polylineUnicodeChars, index: &self.current)
    else {
      return nil
    }
    return Element(latitude: lat, longitude: lng)
  }
}

// MARK: - PolylineSequence
private struct PolylineSequence : Sequence {
  private let encodedPolyline: String
  
  init(_ encodedPolyline: String) throws {
    var index = encodedPolyline.startIndex
    try encodedPolyline.unicodeScalars.forEach {
      if !(0..<64 ~= $0.value - 63) {
        throw GooglePolylineError.invalidString(string: encodedPolyline, errorPosition: index)
      }
      index = encodedPolyline.index(index, offsetBy: 1)
    }
    
    self.encodedPolyline = encodedPolyline
  }
  
  func makeIterator() -> PolylineIterator {
    return PolylineIterator(self.encodedPolyline)
  }
}
