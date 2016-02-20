//
//  TestData.swift
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

import XCTest
import MapKit

// MARK: Test data

// Test data from Google example https://developers.google.com/maps/documentation/utilities/polylinealgorithm

let testEncodedGooglePolyline = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
let testDecodedCoordinates = [
    CLLocationCoordinate2D(latitude: 38.5, longitude: -120.2),
    CLLocationCoordinate2D(latitude: 40.7, longitude: -120.95),
    CLLocationCoordinate2D(latitude: 43.252, longitude: -126.453)
]

extension XCTestCase {
    func validate(mkPolyline:MKPolyline) {
        var resultIndex = testDecodedCoordinates.startIndex
        
        var ptr = mkPolyline.points()
        var count = mkPolyline.pointCount
        
        while(count > 0) {
            
            let point = ptr.memory
            let testPoint = MKMapPointForCoordinate(testDecodedCoordinates[resultIndex])
            
            XCTAssertEqualWithAccuracy(point.x, testPoint.x, accuracy:0.0001)
            XCTAssertEqualWithAccuracy(point.y, testPoint.y, accuracy:0.0001)
            ptr = ptr.successor()
            resultIndex = resultIndex.successor()
            count = count - 1
        }
    }
}


