//
//  SwiftGooglePolylineStringExtensionTests.swift
//  SwiftGooglePolylineStringExtensionTests
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
@testable import SwiftGooglePolyline

class SwiftGooglePolylineStringExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDecodingAsSequence() {
        
        do {
            let sequence = try testEncodedGooglePolyline.makeCoordinateSequenceFromGooglePolyline()
            var resultIndex = testDecodedCoordinates.startIndex

            for coord in sequence {
                XCTAssertTrue(resultIndex < testDecodedCoordinates.endIndex)
                XCTAssertEqualWithAccuracy(coord.latitude, testDecodedCoordinates[resultIndex].latitude, accuracy: 0.0001)
                XCTAssertEqualWithAccuracy(coord.longitude, testDecodedCoordinates[resultIndex].longitude, accuracy: 0.0001)
                resultIndex = resultIndex.successor()
            }
        } catch {
            XCTAssertTrue(false, "Exception parsing polyline")
        }
    }
    
    func testDecodingAsArray() {
        
        do {
            let array = try testEncodedGooglePolyline.makeCoordinateArrayFromGooglePolyline()
            var resultIndex = testDecodedCoordinates.startIndex
            
            for coord in array {
                XCTAssertTrue(resultIndex < testDecodedCoordinates.endIndex)
                XCTAssertEqualWithAccuracy(coord.latitude, testDecodedCoordinates[resultIndex].latitude, accuracy: 0.0001)
                XCTAssertEqualWithAccuracy(coord.longitude, testDecodedCoordinates[resultIndex].longitude, accuracy: 0.0001)
                resultIndex = resultIndex.successor()
            }
        } catch {
            XCTAssertTrue(false, "Exception parsing polyline")
        }
    }
    
    func testDecodingAsMKPolyline() {
        do {
            validate(try testEncodedGooglePolyline.makeMKPolylineFromGooglePolyline())
        } catch {
            XCTAssertTrue(false, "Exception parsing polyline")
        }
    }

    func testEncodingLocationSequence() {
        
        let encoded = String(googlePolylineLocationCoordinateSequence:testDecodedCoordinates)
        XCTAssertEqual(encoded, testEncodedGooglePolyline)

    }
    
    func testEncodingMKMapPointSequence() {
        let sequence = testDecodedCoordinates.map { MKMapPointForCoordinate($0) }
        let encoded = String(googlePolylineMapPointSequence: sequence)
        XCTAssertEqual(encoded, testEncodedGooglePolyline)
    }
    
    func testDecodePerformance() {
        self.measureBlock {
            (0..<10000).forEach { _ in
                let _ = try! testEncodedGooglePolyline.makeCoordinateArrayFromGooglePolyline()
            }
        }
    }
    
    func testEncodePerformance() {
        self.measureBlock {
            (0..<10000).forEach { _ in
                let _ = String(googlePolylineLocationCoordinateSequence:testDecodedCoordinates)
            }
        }
    }
}
