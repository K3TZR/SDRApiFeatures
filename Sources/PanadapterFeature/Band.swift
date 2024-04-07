//
//  BandLIst.swift
//  Sdr6000
//
//  Created by Douglas Adams on 8/19/23.
//

import Cocoa

// ----------------------------------------------------------------------------
// MARK: - Band Model class implementation
// ----------------------------------------------------------------------------

final public class BandList {
  
  typealias BandName      = String
  
  // ----------------------------------------------------------------------------
  // MARK: - Static Properties
  
  static let hfList = [
    ( 160, "160" ),
    ( 80, "80" ),
    ( 60, "60" ),
    ( 40, "40" ),
    ( 30, "30" ),
    ( 20, "20" ),
    ( 17, "17" ),
    ( 15, "15" ),
    ( 12, "12" ),
    ( 10, "10" ),
    ( 6, "6" ),
    ( 4, "4" ),
    ( 0, "" ),
    ( 33, "WWV" ),
    ( 34, "GEN" ),
    ( 2200, "2200" ),
    ( 6300, "6300" ),
    ( -1, "XVTR" )
  ]
  static let xvtrList = [
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( 0, "" ),
    ( -2, "HF" )
  ]
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal Properties
  
  private(set) var segments               = [Segment]()
  private(set) var bands                  = [BandName:Band]()
  private(set) var sortedBands            : [String]!
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Properties
  
  struct Band: Decodable {
    private enum CodingKeys: String, CodingKey {
        case name, number, usage, start, end, segments, useMarkers, enabled
    }
    var name: String
    var number: Int
    var usage: String
    var start: Int
    var end: Int
    var segments: [Segment]
    var useMarkers: Bool
    var enabled: Bool
  }
  
  struct Segment: Codable {
    private enum CodingKeys: String, CodingKey {
        case usage, start, end, isStart, isEnd
    }
    var start: Int
    var end: Int
    var usage: String
    var isStart: Bool
    var isEnd: Bool
    
  }
  
  // constants
  private let kBandSegmentsFile           = "BandSegments"
  
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static let SharedInstance = BandList()
  
  private init() {
    
    var config: [String: Any]?
    if let infoPlistPath = Bundle.main.url(forResource: "Config", withExtension: "plist") {
        do {
            let infoPlistData = try Data(contentsOf: infoPlistPath)
            
            if let dict = try PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any] {
                config = dict
            }
        } catch {
            print(error)
        }
    }
    
    
    
    
    
    // read the BandSegments plist
//    let plistDictArray = Bundle.parsePlist( kBandSegmentsFile, bundle: Bundle.main )
//
//    for entry in plistDictArray {
//      if bands[entry["band"]] == nil {
//        bands.append(Band(entry["band"] ?? "???"), )
//      }
//
//      segments.append(Segment(band: entry["band"] ?? "Unknown",
//                              title: entry["segment"] ?? "",
//                              start: (entry["start"] ?? "").asInt,
//                              end: (entry["end"] ?? "").asInt,
//                              startIsEdge: (entry["startIsEdge"] ?? "").asBool,
//                              endIsEdge: (entry["endIsEdge"] ?? "").asBool,
//                              useMarkers: (entry["useMarkers"] ?? "").asBool,
//                              enabled: (entry["enabled"] ?? "").asBool))
//    }
//    for segment in segments {
//      // is the band already in the Bands dictionary?
//      if var bandExtent = bands[segment.band] {
//        // YES, add its segments
//        if bandExtent.start > segment.start { bandExtent.start = segment.start }
//        if bandExtent.end < segment.end {  bandExtent.end = segment.end }
//        bands[segment.band] = bandExtent
//
//      } else {
//        // NO, add the band to the dictionary
//        bands[segment.band] = ( start: segment.start, end: segment.end )
//      }
//    }
//    // sort by frequency
//    sortedBands = bands.keys.sorted {return Int($0) ?? 0 > Int($1) ?? 0}
  }
}

extension Bundle {
  static func parsePlist(_ name: String, bundle: Bundle) -> [[String: String]] {
    var arrayOfDict = NSArray()
    // check if plist data available
    if let plistURL = bundle.url(forResource: name, withExtension: "plist") {
      arrayOfDict = NSArray(contentsOf: plistURL) ?? arrayOfDict
    }
    if let array = arrayOfDict as? [[String: String]] {
      return array
    }
    fatalError("Unable to return array of dictionary")
  }
}

public extension String {
  var asInt:  Int     { Int(self, radix: 10) ?? 0 }
  var asBool: Bool    { self == "1" ? true : false }
}
