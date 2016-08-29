//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation
import zlib

class Zlib {

    struct Constants {
        private static let chunkSize: UInt32 = 16384
    }

    private var rawData: [Byte]

    init(data: [Byte]) {
        rawData = data
    }

    func inflateStream() -> NSData? {

        let allOutput = NSMutableData()
        var returnCode: Int32 = 0
        var have: UInt32 = 0
        var stream = z_stream()

        var outChunk: [Byte] = [Byte](count: Int(Constants.chunkSize), repeatedValue: 0)

        stream.avail_in = 0
        returnCode = inflateInit_(&stream, ZLIB_VERSION, Int32(sizeof(z_stream)))

        guard returnCode == Z_OK else {
          return nil
        }

        /* decompress until deflate stream ends or end of file */
        repeat {
            stream.avail_in = UInt32(rawData.count)
            if (stream.avail_in == 0) {
                break
            }

            stream.next_in = UnsafeMutablePointer<Bytef>(rawData)

            /* run inflate() on input until output buffer not full */
            repeat {

                stream.avail_out = Constants.chunkSize;
                stream.next_out = UnsafeMutablePointer<Bytef>(outChunk);

                returnCode = inflate(&stream, Z_NO_FLUSH)

                guard returnCode != Z_STREAM_ERROR else {
                    return nil
                }

                switch returnCode {
                case Z_NEED_DICT:
                    return nil
                case Z_DATA_ERROR:
                    inflateEnd(&stream)
                    return nil
                case Z_MEM_ERROR:
                    inflateEnd(&stream)
                    return nil
                default:
                    break
                }

                have = Constants.chunkSize - stream.avail_out

                allOutput.appendBytes(&outChunk, length: Int(have))

            } while stream.avail_out == 0
        } while returnCode != Z_STREAM_END

        inflateEnd(&stream)

        guard returnCode == Z_STREAM_END else {
            return nil
        }

        return allOutput
    }
}