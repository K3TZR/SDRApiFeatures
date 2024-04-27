//
//  ObjectModel.swift
//
//
//  Created by Douglas Adams on 10/22/23.
//

import ComposableArchitecture
import Foundation

import ListenerFeature
import SharedFeature
import TcpFeature
import XCGLogFeature

@MainActor
@Observable
final public class ObjectModel {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = ObjectModel()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var activeSlice: Slice?
  public internal(set) var boundClientId: String?
  public internal(set) var clientInitialized = false
  public var testMode = false
  public var radio: Radio?
  
  // Dynamic Models
  public var amplifiers = IdentifiedArrayOf<Amplifier>()
  public var bandSettings = IdentifiedArrayOf<BandSetting>()
  public var equalizers = IdentifiedArrayOf<Equalizer>()
  public var memories = IdentifiedArrayOf<Memory>()
  public var meters = IdentifiedArrayOf<Meter>()
  public var panadapters = IdentifiedArrayOf<Panadapter>()
  public var profiles = IdentifiedArrayOf<Profile>()
  public var slices = IdentifiedArrayOf<Slice>()
  public var tnfs = IdentifiedArrayOf<Tnf>()
  public var usbCables = IdentifiedArrayOf<UsbCable>()
  public var waterfalls = IdentifiedArrayOf<Waterfall>()
  public var xvtrs = IdentifiedArrayOf<Xvtr>()
  
  // Static Models
  public var atu = Atu()
  public var cwx = Cwx()
  public var gps = Gps()
  public var interlock = Interlock()
  public var transmit = Transmit()
  public var wan = Wan()
  public var waveform = Waveform()
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum ObjectType: String {
    case amplifier
    case atu
    case bandSetting = "band"
    case client
    case cwx
    case display
    case equalizer = "eq"
    case gps
    case interlock
    case memory
    case meter
    case panadapter = "pan"
    case profile
    case radio
    case slice
    case stream
    case tnf
    case transmit
    case usbCable = "usb_cable"
    case wan
    case waterfall
    case waveform
    case xvtr
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  public func clientInitialized(_ state: Bool) {
    clientInitialized = state
  }

  public func parse(_ statusType: String, _ statusMessage: String, _ connectionHandle: UInt32?) {
    
    // Check for unknown Object Types
    guard let objectType = ObjectType(rawValue: statusType)  else {
      // log it and ignore the message
      log("ApiModel: unknown status token = \(statusType)", .warning, #function, #file, #line)
      return
    }
    
    switch objectType {
    case .amplifier:            amplifierStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .atu:                  atu.parse( Array(statusMessage.keyValuesArray() ))
    case .bandSetting:          bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst(1) ), !statusMessage.contains(kRemoved))
    case .client:               preProcessClient(statusMessage.keyValuesArray(), !statusMessage.contains(kDisconnected), connectionHandle)
    case .cwx:                  cwx.parse( Array(statusMessage.keyValuesArray().dropFirst(1) ))
    case .display:              preProcessDisplay(statusMessage)
    case .equalizer:            equalizerStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .gps:                  gps.parse( Array(statusMessage.keyValuesArray(delimiter: "#").dropFirst(1)) )
    case .interlock:            preProcessInterlock(statusMessage)
    case .memory:               memoryStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .meter:                meterStatus(statusMessage.keyValuesArray(delimiter: "#"), !statusMessage.contains(kRemoved))
    case .profile:              profileStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse), statusMessage)
    case .radio:                radio!.parse(statusMessage.keyValuesArray())
    case .slice:                sliceStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse))
    case .stream:               StreamModel.shared.parse(statusMessage, connectionHandle, testMode)
    case .tnf:                  tnfStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .transmit:             preProcessTransmit(statusMessage)
    case .usbCable:             usbCableStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .wan:                  wan.parse( Array(statusMessage.keyValuesArray().dropFirst(1)) )
    case .waveform:             waveform.parse( Array(statusMessage.keyValuesArray(delimiter: "=").dropFirst(1)) )
    case .xvtr:                 xvtrStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse))
      
    case .panadapter, .waterfall: break                                                   // handled by "display"
    }
  }
  
  // ----- Meter methods -----
  
  public func meterBy(shortName: Meter.ShortName, slice: Slice? = nil) -> Meter? {
    
    if slice == nil {
      for meter in meters where meter.name == shortName.rawValue {
        return meter
      }
    } else {
      for meter in meters where slice!.id == UInt32(meter.group) && meter.name == shortName.rawValue {
        return meter
      }
    }
    return nil
  }
  
  // ----- Slice methods -----
  
  /// Find a Slice by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              a Slice (if any)
  ///
  public func findSlice(using channel: Int) -> Slice? {
    // find the Slices with the specified Channel (if any)
    let filteredSlices = slices.filter { $0.daxChannel == channel }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  
  public func sliceMove(_ panadapter: Panadapter, _ clickFrequency: Int) {
    
    let slices = slices.filter{ $0.panadapterId == panadapter.id }
    if slices.count == 1 {
      let roundedFrequency = clickFrequency - (clickFrequency % slices[0].step)
      slices[0].setProperty(.frequency, roundedFrequency.hzToMhz)
      
    } else {
      let nearestSlice = slices.min{ a, b in
        abs(clickFrequency - a.frequency) < abs(clickFrequency - b.frequency)
      }
      if let nearestSlice {
        let roundedFrequency = clickFrequency - (clickFrequency % nearestSlice.step)
        nearestSlice.setProperty(.frequency, roundedFrequency.hzToMhz)
      }
    }
  }
  
  // ----- Tnf methods -----
  
  /// Remove a Tnf
  /// - Parameters:
  ///   _ id:                            a TnfId
  ///   - callback:     ReplyHandler (optional)
  public func removeTnf(_ id: UInt32, replyTo callback: ReplyHandler? = nil) {
    ApiModel.shared.sendCommand("tnf remove \(id)", replyTo: callback)
    
    // remove it immediately (Tnf does not send status on removal)
    tnfs.remove(id: id)
    log("ObjectModel: Tnf removed, id = \(id)", .debug, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  
  /// Remove all Radio objects
  func removeAllObjects() {
    radio = nil
    removeAll(of: .amplifier)
    removeAll(of: .bandSetting)
    removeAll(of: .equalizer)
    removeAll(of: .memory)
    removeAll(of: .meter)
    removeAll(of: .panadapter)
    removeAll(of: .profile)
    removeAll(of: .slice)
    removeAll(of: .tnf)
    removeAll(of: .usbCable)
    removeAll(of: .waterfall)
    removeAll(of: .xvtr)
    ApiModel.shared.replyHandlers.removeAll()
  }
  
  func removeAll(of type: ObjectType) {
    switch type {
    case .amplifier:            amplifiers.removeAll()
    case .bandSetting:          bandSettings.removeAll()
    case .equalizer:            equalizers.removeAll()
    case .memory:               memories.removeAll()
    case .meter:                meters.removeAll()
    case .panadapter:           panadapters.removeAll()
    case .profile:              profiles.removeAll()
    case .slice:                slices.removeAll()
    case .tnf:                  tnfs.removeAll()
    case .usbCable:             usbCables.removeAll()
    case .waterfall:            waterfalls.removeAll()
    case .xvtr:                 xvtrs.removeAll()
    default:            break
    }
    log("ObjectModel: removed all \(type.rawValue) objects", .debug, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Object Status methods
  
  /// Evaluate a Status messaage
  /// - Parameters:
  ///   - properties: properties in KeyValuesArray form
  ///   - inUse: bool indicating status
  private func amplifierStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if amplifiers[id: id] == nil { amplifiers.append( Amplifier(id) ) }
        // parse the properties
        amplifiers[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        amplifiers.remove(id: id)
        log("Amplifier \(id.hex): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func bandSettingStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if bandSettings[id: id] == nil { bandSettings.append( BandSetting(id) ) }
        // parse the properties
        bandSettings[id: id]!.parse(Array(properties.dropFirst(1)) )
      } else {
        // NO, remove it
        bandSettings.remove(id: id)
        log("BandSetting \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func equalizerStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    let id = properties[0].key
    if id == "tx" || id == "rx" { return } // legacy equalizer ids, ignore
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if equalizers[id: id] == nil { equalizers.append( Equalizer(id) ) }
      // parse the properties
      equalizers[id: id]!.parse(Array(properties.dropFirst(1)) )
      
    } else {
      // NO, remove it
      equalizers.remove(id: id)
      log("Equalizer \(id): REMOVED", .debug, #function, #file, #line)
    }
  }
  
  private func memoryStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if memories[id: id] == nil { memories.append( Memory(id) ) }
        // parse the properties
        memories[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        memories.remove(id: id)
        log("Memory \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func meterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = UInt32(properties[0].key.components(separatedBy: ".")[0], radix: 10) {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if meters[id: id] == nil { meters.append( Meter(id) ) }
        // parse the properties
        meters[id: id]!.parse(properties )
        
      } else {
        // NO, remove it
        meters.remove(id: id)
        log("Meter \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func panadapterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.streamId {
      // is it in use?
      if inUse {
        // parse the properties
        // YES, add it if not already present
        if panadapters[id: id] == nil {
          panadapters.append( Panadapter(id) )
          StreamModel.shared.panadapterStreams.append( PanadapterStream(id) )
        }
        panadapters[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        panadapters.remove(id: id)
        StreamModel.shared.panadapterStreams.remove(id: id)
        log("Panadapter \(id.hex): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func profileStatus(_ properties: KeyValuesArray, _ inUse: Bool, _ statusMessage: String) {
    // get the id
    let id = properties[0].key
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if profiles[id: id] == nil { profiles.append( Profile(id) ) }
      // parse the properties
      profiles[id: id]!.parse(statusMessage )
      
    } else {
      // NO, remove it
      profiles.remove(id: id)
      log("Profile \(id): REMOVED", .debug, #function, #file, #line)
    }
  }
  
  private func sliceStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if slices[id: id] == nil { slices.append(Slice(id)) }
        // parse the properties
        slices[id: id]!.parse(Array(properties.dropFirst(1)) )
        //        if slices[id: id]!.active { activeSlice = slices[id: id] }
        
      } else {
        // NO, remove it
        slices.remove(id: id)
        log("Slice \(id) REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func tnfStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = UInt32(properties[0].key, radix: 10) {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if tnfs[id: id] == nil { tnfs.append( Tnf(id) ) }
        // parse the properties
        tnfs[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        tnfs.remove(id: id)
        log("Tnf \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  private func usbCableStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    let id = properties[0].key
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if usbCables[id: id] == nil { usbCables.append( UsbCable(id) ) }
      // parse the properties
      usbCables[id: id]!.parse(Array(properties.dropFirst(1)) )
      
    } else {
      // NO, remove it
      usbCables.remove(id: id)
      log("USBCable \(id): REMOVED", .debug, #function, #file, #line)
    }
  }
  
  private func waterfallStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.streamId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if waterfalls[id: id] == nil {
          waterfalls.append( Waterfall(id) )
          StreamModel.shared.waterfallStreams.append( WaterfallStream(id) )
        }
        // parse the properties
        waterfalls[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        waterfalls.remove(id: id)
        StreamModel.shared.waterfallStreams.remove(id: id)
        log("Waterfall \(id.hex): REMOVED", .info, #function, #file, #line)
      }
    }
  }
  
  private func xvtrStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[1].key.streamId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if xvtrs[id: id] == nil { xvtrs.append( Xvtr(id) ) }
        // parse the properties
        xvtrs[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        xvtrs.remove(id: id)
        log("Xvtr \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Pre-Process methods
  
  private func preProcessClient(_ properties: KeyValuesArray, _ inUse: Bool = true, _ connectionHandle: UInt32?) {
    // is there a valid handle"
    if let handle = properties[0].key.handle {
      switch properties[1].key {
        
      case kConnected:       parseConnection(properties: properties, handle: handle, connectionHandle: connectionHandle)
      case kDisconnected:    parseDisconnection(properties: properties, handle: handle, connectionHandle: connectionHandle)
      default:                      break
      }
    }
  }
  
  private func preProcessDisplay(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Waterfall or Panadapter?
    switch properties[0].key {
    case ObjectType.panadapter.rawValue:  panadapterStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    case ObjectType.waterfall.rawValue:   waterfallStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    default: break
    }
  }
  
  private func preProcessInterlock(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Band Setting or Interlock?
    switch properties[0].key {
    case ObjectType.bandSetting.rawValue:   bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    default:                                interlock.parse(properties) ; interlockStateChange(interlock.state)
    }
  }
  
  private func preProcessTransmit(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Band Setting or Transmit?
    switch properties[0].key {
    case ObjectType.bandSetting.rawValue:   bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst(1) ), !statusMessage.contains(kRemoved))
    default:                                transmit.parse( Array(properties.dropFirst() ))
    }
  }
  
  /// Change the MOX property when an Interlock state change occurs
  /// - Parameter state:            a new Interloack state
  private func interlockStateChange(_ state: String) {
    let currentMox = radio?.mox
    
    // if PTT_REQUESTED or TRANSMITTING
    if state == Interlock.States.pttRequested.rawValue || state == Interlock.States.transmitting.rawValue {
      // and mox not on, turn it on
      if currentMox == false { radio?.mox = true }
      
      // if READY or UNKEY_REQUESTED
    } else if state == Interlock.States.ready.rawValue || state == Interlock.States.unKeyRequested.rawValue {
      // and mox is on, turn it off
      if currentMox == true { radio?.mox = false  }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private parse methods
  
  /// Parse a client connect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseConnection(properties: KeyValuesArray, handle: UInt32, connectionHandle: UInt32?) {
    var clientId = ""
    var program = ""
    var station = ""
    var isLocalPtt = false
    
    enum Property: String {
      case clientId = "client_id"
      case localPttEnabled = "local_ptt"
      case program
      case station
    }
    
    // if handle is mine, this client is fully initialized
    clientInitialized = ( handle == connectionHandle )
    
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown properties
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore this Key
        log("ObjectModel: unknown client property, \(property.key)=\(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known properties, in alphabetical order
      switch token {
        
      case .clientId:         clientId = property.value
      case .localPttEnabled:  isLocalPtt = property.value.bValue
      case .program:          program = property.value.trimmingCharacters(in: .whitespaces)
      case .station:          station = property.value.replacingOccurrences(of: "\u{007f}", with: "").trimmingCharacters(in: .whitespaces)
      }
    }
    
    if let packet = ListenerModel.shared.activePacket {
      // is this GuiClient already in GuiClients?
      if let guiClient = packet.guiClients[id: handle] {
        // YES, are all fields populated?
        //        if !clientId.isEmpty && !program.isEmpty && !station.isEmpty {
        // the fields are populated
        
        // update the packet's GuiClients collection
        guiClient.clientId = clientId
        guiClient.program = program
        guiClient.station = station
        guiClient.isLocalPtt = isLocalPtt
        
        packet.guiClients[id: handle] = guiClient
        
        // log the addition
        log("ObjectModel: guiClient UPDATED, \(guiClient.handle.hex), \(guiClient.station), \(guiClient.program), \(guiClient.clientId ?? "nil")", .info, #function, #file, #line)
        
        if !radio!.isGui && station == ListenerModel.shared.activeStation {
          boundClientId = clientId
          ApiModel.shared.sendCommand("client bind client_id=\(clientId)")
          log("ObjectModel: NonGui bound to \(guiClient.station), \(guiClient.program)", .debug, #function, #file, #line)
        }
        //        }
      } else {
        // NO
        let guiClient = GuiClient(handle: handle,
                                  station: station,
                                  program: program,
                                  clientId: clientId,
                                  isLocalPtt: isLocalPtt,
                                  isThisClient: handle == connectionHandle)
        packet.guiClients[id: handle] = guiClient
        
        // log the addition
        log("ObjectModel: guiClient ADDED, \(guiClient.handle.hex), \(guiClient.station), \(guiClient.program), \(guiClient.clientId ?? "nil")", .info, #function, #file, #line)
        
        if !clientId.isEmpty && !program.isEmpty && !station.isEmpty {
          // the fields are populated
          
          packet.guiClients[id: handle] = guiClient
          
          if !radio!.isGui && station == ListenerModel.shared.activeStation {
            boundClientId = clientId
            ApiModel.shared.sendCommand("client bind client_id=\(clientId)")
            log("ObjectModel: NonGui bound to \(guiClient.station), \(guiClient.program)", .debug, #function, #file, #line)
          }
        }
      }
    }
  }
  
  /// Parse a client disconnect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseDisconnection(properties: KeyValuesArray, handle: UInt32, connectionHandle: UInt32?) {
    var reason = ""
    
    enum Property: String {
      case duplicateClientId        = "duplicate_client_id"
      case forced
      case wanValidationFailed      = "wan_validation_failed"
    }
    
    // is it me?
    if handle == connectionHandle {
      // YES, parse remaining properties
      for property in properties.dropFirst(2) {
        // check for unknown property
        guard let token = Property(rawValue: property.key) else {
          // log it and ignore this Key
          log("ApiModel: unknown client disconnection property, \(property.key)=\(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known properties, in alphabetical order
        switch token {
          
        case .duplicateClientId:    if property.value.bValue { reason = "Duplicate ClientId" }
        case .forced:               if property.value.bValue { reason = "Forced" }
        case .wanValidationFailed:  if property.value.bValue { reason = "Wan validation failed" }
        }
      }
      log("ObjectModel: client disconnection, reason = \(reason)", .warning, #function, #file, #line)
      
      clientInitialized = false
      
    } else {
      // NO, not me
      print("----->>>>>> TODO: Client disconnected, properties = \(properties), handle = \(handle.hex)")
    }
  }
}

//  public func altAntennaName(for stdName: String) -> String {
//    // return alternate name (if any)
//    for antenna in settingsModel.altAntennaNames where antenna.stdName == stdName {
//      return antenna.customName
//    }
//    return stdName
//  }
//
//  public func altAntennaName(for stdName: String, _ customName: String) {
//    for (i, antenna) in settingsModel.altAntennaNames.enumerated() where antenna.stdName == stdName {
//      settingsModel.altAntennaNames[i].customName = customName
//      let oldAntList = antList
//      antList = oldAntList
//      return
//    }
//    settingsModel.altAntennaNames.append(Settings.AntennaName(stdName: stdName, customName: customName))
//    let oldAntList = antList
//    antList = oldAntList
//  }
  
//  public func altAntennaNameRemove(for stdName: String) {
//    for (i, antenna) in altAntennaList.enumerated() where antenna.stdName == stdName {
//      altAntennaList.remove(at: i)
//    }
//  }
