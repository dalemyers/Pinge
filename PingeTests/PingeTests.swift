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

	private var libpngTest: Data!

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.

		let bundle = Bundle(for: type(of: self))

		// If we leave the image as PNG, Apple compress them using their special
		// encoder: http://iphonedevwiki.net/index.php/CgBI_file_format
		guard let libpngTestPath = bundle.path(forResource: "basn0g01-black_and_white", ofType:"pinge") else {
			libpngTest = Data()
			return
		}

		libpngTest = try? Data(contentsOf: URL(fileURLWithPath: libpngTestPath))
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
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}

}
