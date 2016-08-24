//
//  PingeTests.swift
//  PingeTests
//
//  Created by Dale Myers on 24/08/2016.
//  Copyright © 2016 Dale Myers. All rights reserved.
//

import XCTest
@testable import Pinge

class PingeTests: XCTestCase {

	private var libpngTest: NSData!

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.

		let bundle = NSBundle(forClass: self.dynamicType)

		guard let libpngTestPath = bundle.pathForResource("libpng-test", ofType:"png") else {
			libpngTest = NSData()
			return
		}

		libpngTest = NSData(contentsOfFile: libpngTestPath)
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testHeaders() {
		let png = Pinge(data: libpngTest)
		XCTAssert(png != nil)
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}

}
