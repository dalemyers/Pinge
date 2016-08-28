//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

class Pinge {

	typealias Byte = UInt8

	struct Constants {
		static let pngHeader: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		static let headerLength: Int = 8
	}

	private var data: NSData

	private var non_required_chunks = [PNGChunk]()
	private var chunkIHDR: IHDRChunk!
	private var chunkPLTE: PLTEChunk?
	private var chunkIDAT: PNGChunk!

	init?(data: NSData) {
		self.data = data
		guard validateHeader() else {
			return nil
		}

		guard readChunks() else {
			return nil
		}

		guard validateChunks() else {
			return nil
		}
	}

	private func validateChunks() -> Bool {
		guard chunkIHDR != nil else {
			return false
		}

		switch chunkIHDR.colorType! {
		case .IndexedColor:
			guard chunkPLTE != nil else {
				return false
			}
		case .Greyscale, .GreyscaleWithAlpha:
			guard chunkPLTE == nil else {
				return false
			}
		default:
			break
		}

		// The number of palette entries must not exceed the range that can be
		// represented in the image bit depth (for example, 2^4 = 16 for a bit
		// depth of 4)
		guard chunkPLTE == nil || chunkPLTE!.paletteEntries.count <= Int(pow(2.0, Double(chunkIHDR.bitDepth))) else {
			return false
		}

		return true
	}

	private func createChunk(chunkID: [Byte], chunkData: [Byte], chunkCRC: [Byte]) -> Bool {
		
		guard let chunkName = String(bytes: chunkID, encoding: NSUTF8StringEncoding) else {
			return false
		}

		switch chunkName {
		case "IHDR":
			guard let chunk = IHDRChunk(identifier: chunkID, data: chunkData, crc: chunkCRC) else {
				return false
			}
			guard chunkIHDR == nil else {
				return false
			}
			chunkIHDR = chunk
		case "PLTE":
			guard let chunk = PLTEChunk(identifier: chunkID, data: chunkData, crc: chunkCRC) else {
				return false
			}
			guard chunkPLTE == nil else {
				return false
			}
			guard chunkIDAT == nil else {
				// PLTE must precede the IDAT chunk
				return false
			}
			chunkPLTE = chunk
		default:
			print(chunkName)
		}

		return true
	}

	private func readChunks() -> Bool {
		var offset = Constants.headerLength

		while offset < data.length {
			// Chunk length
			var chunkLength: UInt32 = 0
			data.getBytes(&chunkLength, range: NSMakeRange(offset, sizeof(UInt32)))
			chunkLength = CFSwapInt32(chunkLength)
			offset += 4

			// Chunk ID
			var chunkID: [Byte] = [Byte](count: 4, repeatedValue: 0)
			data.getBytes(&chunkID, range: NSMakeRange(offset, 4))
			offset += 4

			// Chunk Data
			var chunkData: [Byte] = [Byte](count: Int(chunkLength), repeatedValue: 0)
			data.getBytes(&chunkData, range: NSMakeRange(offset, Int(chunkLength)))
			offset += Int(chunkLength)

			// Chunk CRC
			var chunkCRC: [Byte] = [Byte](count: 4, repeatedValue: 0)
			data.getBytes(&chunkCRC, range: NSMakeRange(offset, 4))
			offset += 4

			guard createChunk(chunkID, chunkData: chunkData, chunkCRC: chunkCRC) else {
				return false
			}

			guard chunkIHDR != nil else {
				// IHDR must be the first chunk. If we have parsed one and it's
				// not set, then it must not have been the first one
				return false
			}
		}

		return true
	}

	private func validateHeader() -> Bool {
		if data.length < Constants.headerLength {
			return false
		}

		var headerData: [Byte] = [Byte](count: Constants.headerLength, repeatedValue: 0)
		data.getBytes(&headerData, length: Constants.headerLength * sizeof(Byte))

		for (a,b) in Zip2Sequence(headerData, Constants.pngHeader) {
			if a != b {
				return false
			}
		}

		return true
	}

}