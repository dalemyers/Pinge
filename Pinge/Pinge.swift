//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class Pinge {

	struct Constants {
		static let pngHeader: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		static let headerLength: Int = 8
	}

	private var data: DataExtractor
	private var previousChunkName = ""
	private var idatDataStream: DataExtractor!

	private var endChunkFound = false
	private var non_required_chunks = [PNGChunk]()
	private var chunkIHDR: IHDRChunk!
	private var chunkPLTE: PLTEChunk?
	private var idatChunks = [IDATChunk]()
	private var chunkIEND: IENDChunk!
	private var decodedData: Data?


	public init?(data: Data) {
		self.data = DataExtractor(data: data)
		guard validateHeader() else {
			return nil
		}
	}

	public func load() -> Bool {
		guard readChunks() else {
			return false
		}
		return true
	}

	public func validate() -> Bool {
		guard consolidateIDATChunks() else {
			return false
		}

		guard validateChunks() else {
			return false
		}

		return true
	}

	public func decode() -> Bool {
		guard let bytes = unfilterIDATChunks() else {
			return false
		}

		var outputData = Data()

		// We have the raw bytes, along with any chunks we need to turn these
		// into an actual ARGB array.

		for byte in bytes {
			switch chunkIHDR.bitDepth! {
			case .depth1:
				let decodedBytes = bitFieldToBytes(byte: byte)
				for decodedByte in decodedBytes {
					outputData.append(255) // Alpha
					outputData.append(decodedByte * 255) // R
					outputData.append(decodedByte * 255) // G
					outputData.append(decodedByte * 255) // B
				}
			case .depth2:
				continue
			case .depth4:
				continue
			case .depth8:
				continue
			case .depth16:
				continue
			}
		}

		decodedData = outputData

		return true
	}

	public func imageData() -> Data? {
		return decodedData
	}

	public func image() -> UIImage? {
		guard let imageData = decodedData else {
			return nil
		}

		let imageWidth = chunkIHDR.width!
		let imageHeight = chunkIHDR.height!

		guard imageWidth * imageHeight * 4 == imageData.count else {
			return nil
		}

		guard let provider: CGDataProvider = CGDataProvider(data: NSData(data: imageData) as CFData) else {
			return nil
		}
		
		guard let cgimage: CGImage = CGImage(
			width: imageWidth,
			height: imageHeight,
			bitsPerComponent: 8,
			bitsPerPixel: 32,
			bytesPerRow: imageWidth * 4,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
			provider: provider,
			decode: nil,
			shouldInterpolate: true,
			intent: .defaultIntent
			) else {
				return nil
		}

		return UIImage(cgImage: cgimage)
	}

	private func unfilterIDATChunks() -> [Byte]? {

		guard let chunkIHDR = chunkIHDR else {
			return nil
		}

		guard chunkIHDR.interlaceMethod == InterlaceMethod.none else {
			// TODO support ADAM7
			return nil
		}

		var unfilteredData = [Byte]()
		var prior: [Byte]!

		while idatDataStream.remainingData() {
			guard let filterTypeValue: Byte = idatDataStream.nextUInt8() else {
				return nil
			}
			let filterType = FilterType(rawValue: Int(filterTypeValue))!

			let bppNonRounded = Double(chunkIHDR.bitDepth.rawValue * chunkIHDR.colorType.samples()) / 8.0
			let bpp = Int(ceil(Double(bppNonRounded)))
			let bitDepth = Double(chunkIHDR.bitDepth.rawValue)
			let samples = Double(chunkIHDR.colorType.samples())
			let lineWidth = Double(chunkIHDR.width!)
			let scanlineLength = Int((bitDepth * samples * lineWidth / 8.0) + 0.5)

			guard idatDataStream.bytesRemaining() >= scanlineLength else {
				return nil
			}

			var priorRaw = [Byte](repeating: 0, count: scanlineLength)
			var currentScanline = [Byte](repeating: 0, count: scanlineLength)
			var currentRaw = [Byte](repeating: 0, count: scanlineLength)

			idatDataStream.copyNextBytes(to: &currentScanline, length: scanlineLength)

			switch filterType {
			case .none:
				currentRaw = currentScanline
				break

			case .sub:

				for i in 0..<scanlineLength {
					if i - bpp < 0 {
						currentRaw[i] = currentScanline[i]
					} else {
						currentRaw[i] = Byte((UInt(currentScanline[i]) + UInt(currentRaw[i - bpp])) % 256)
					}
				}

				break

			case .up:

				// TODO test
				for i in 0..<scanlineLength {
					currentRaw[i] = Byte((UInt(currentScanline[i]) + UInt(priorRaw[i])) % 256)
				}

				break

			case .average:

				// TODO test
				for i in 0..<scanlineLength {
					if i - bpp < 0 {
						currentRaw[i] = currentScanline[i]
					} else {
						let currentByte = UInt(currentScanline[i])
						let precedingByte = UInt(currentRaw[i - bpp])
						let upperByte = UInt(priorRaw[i])
						let upperPrecedingMean = Double(precedingByte + upperByte) / 2.0
						currentRaw[i] = Byte((currentByte + UInt(floor(upperPrecedingMean))) % 256)
					}
				}

				break

			case .paeth:

				func paethPredictor(_ left: UInt, upper: UInt, upperLeft: UInt) -> Byte {

					func absDiff(_ first: UInt, second: UInt) -> UInt {
						return (first > second) ? (first - second) : (second - first)
					}

					let estimate: UInt = left + upper - upperLeft // Initial estimate
					let estimateLeft = absDiff(estimate, second: left)
					let estimateUpper = absDiff(estimate, second: upper)
					let estimateUpperLeft = absDiff(estimate, second: upperLeft)

					// Do tie breaker in order of left, upper, upper left
					if estimateLeft <= estimateUpper && estimateLeft <= estimateUpperLeft {
						return Byte(left)
					} else if estimateUpper <= estimateUpperLeft {
						return Byte(upper)
					} else {
						return Byte(upperLeft)
					}
				}

				// TODO test
				for i in 0..<scanlineLength {
					if i - bpp < 0 {
						currentRaw[i] = currentScanline[i]
					} else {
						currentRaw[i] = Byte((UInt(currentScanline[i]) + UInt(paethPredictor(
							UInt(currentRaw[i - bpp]),
							upper: UInt(priorRaw[i]),
							upperLeft: UInt(priorRaw[i - bpp])
						))) % 256)
					}
				}

				break
				
			}

			unfilteredData.append(contentsOf: currentRaw)
			priorRaw = currentRaw
		}

		return unfilteredData
	}

	private func consolidateIDATChunks() -> Bool {

		var dataBytes = [Byte]()

		for idatChunk in idatChunks {
			dataBytes.append(contentsOf: idatChunk.dataBytes)
		}

		guard dataBytes.count > 0 else {
			// 0 length is wasteful, but fine.
			idatDataStream = DataExtractor(data: Data())
			return true
		}

		let zlib = Zlib(data: dataBytes)

		guard let uncompressedData = zlib.inflateStream() else {
			return false
		}

		idatDataStream = DataExtractor(data: (uncompressedData as Data!))

		return true
	}

	private func validateChunks() -> Bool {
		guard chunkIHDR != nil else {
			return false
		}

		switch chunkIHDR.colorType! {
		case .indexedColor:
			guard chunkPLTE != nil else {
				return false
			}
		case .greyscale, .greyscaleWithAlpha:
			guard chunkPLTE == nil else {
				return false
			}
		default:
			break
		}

		// The number of palette entries must not exceed the range that can be
		// represented in the image bit depth (for example, 2^4 = 16 for a bit
		// depth of 4)
		guard chunkPLTE == nil || chunkPLTE!.paletteEntries.count <= Int(pow(2.0, Double(chunkIHDR.bitDepth.rawValue))) else {
			return false
		}

		return true
	}

	private func createChunk(chunkID: [Byte], chunkData: [Byte], chunkCRC: [Byte]) -> Bool {
		
		guard let chunkName = String(bytes: chunkID, encoding: .utf8) else {
			return false
		}

		// Once we have seen the end chunk, we can't see anything else
		guard endChunkFound == false else {
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
			guard idatChunks.count == 0 else {
				// PLTE must precede the first IDAT chunk
				return false
			}
			chunkPLTE = chunk
		case "IDAT":
			guard idatChunks.count == 0 || (idatChunks.count > 0 && previousChunkName == "IDAT") else {
				// All IDAT chunks must be sequential if there are multiple
				return false
			}
			guard let chunk = IDATChunk(identifier: chunkID, data: chunkData, crc: chunkCRC) else {
				return false
			}
			idatChunks.append(chunk)
		case "IEND":
			guard let chunk = IENDChunk(identifier: chunkID, data: chunkData, crc: chunkCRC) else {
				return false
			}
			chunkIEND = chunk
			endChunkFound = true
		default:
			print(chunkName)
		}

		return true
	}

	private func readChunks() -> Bool {

		while data.remainingData() {

			// Chunk length
			guard let chunkLength = data.nextUInt32(reverseBytes: true) else {
				return false
			}


			// Chunk ID
			var chunkID: [Byte] = [Byte](repeating: 0, count: 4)
			data.copyNextBytes(to: &chunkID, length: 4)

			// Chunk Data
			var chunkData: [Byte] = [Byte](repeating: 0, count: Int(chunkLength))
			data.copyNextBytes(to: &chunkData, length: Int(chunkLength))

			// Chunk CRC
			var chunkCRC: [Byte] = [Byte](repeating: 0, count: 4)
			data.copyNextBytes(to: &chunkCRC, length: 4)

			guard createChunk(chunkID: chunkID, chunkData: chunkData, chunkCRC: chunkCRC) else {
				return false
			}

			guard chunkIHDR != nil else {
				// IHDR must be the first chunk. If we have parsed one and it's
				// not set, then it must not have been the first one
				return false
			}
		}

		// Ensure we see the end chunk
		guard chunkIEND != nil else {
			return false
		}

		return true
	}

	private func validateHeader() -> Bool {
		guard data.bytesRemaining() >= Constants.headerLength else {
			return false
		}

		var headerData: [Byte] = [Byte](repeating: 0, count: Constants.headerLength)
		data.copyNextBytes(to: &headerData, length: Constants.headerLength)

		for (a,b) in zip(headerData, Constants.pngHeader) {
			if a != b {
				return false
			}
		}

		return true
	}

}
