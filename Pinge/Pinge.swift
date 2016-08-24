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

	private var chunks = [PNGChunk]()

	init?(data: NSData) {
		self.data = data
		guard validateHeader() else {
			return nil
		}

		readChunks()
	}

	private func createChunk(chunkID: [Byte], chunkData: [Byte], chunkCRC: [Byte]) {
		
		guard let chunkName = String(bytes: chunkID, encoding: NSUTF8StringEncoding) else {
			return
		}

		switch chunkName {
		case "IHDR":
			guard let chunk = IHDRChunk(identifier: chunkID, data: chunkData, crc: chunkCRC) else {
				return
			}
			chunks.append(chunk)
		default:
			print(chunkName)
		}

	}

	private func readChunks() {
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

			createChunk(chunkID, chunkData: chunkData, chunkCRC: chunkCRC)
		}
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