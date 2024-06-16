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
  
  public var activePacket: Packet?
  public var activeSlice: Slice?
  public var activeStation: String?
  public internal(set) var boundClientId: String?
  public internal(set) var clientInitialized = false
  public var testMode = false
  public var radio: Radio?
  
  public var apiModel: ApiModel?
  
  // single objects
  public var atu = Atu()
  public var cwx = Cwx()
  public var gps = Gps()
  public var interlock = Interlock()
  public var remoteRxAudio: RemoteRxAudio?
  public var transmit = Transmit()
  public var wan = Wan()
  public var waveform = Waveform()

  // collection objects
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
  
  // single stream objects
  public var daxMicAudio: DaxMicAudio?
  public var daxTxAudio: DaxTxAudio?
  public var meterStream: MeterStream?
  public var remoteTxAudio: RemoteTxAudio?

  // collection stream objects
  public var daxIqs = IdentifiedArrayOf<DaxIq>()
  public var daxRxAudios = IdentifiedArrayOf<DaxRxAudio>()
  public var panadapterStreams = IdentifiedArrayOf<PanadapterStream>()
  public var waterfallStreams = IdentifiedArrayOf<WaterfallStream>()

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

  /// Send a command to the Radio (hardware) via TCP
  /// - Parameters:
  ///   - command:        a Command String
  ///   - diagnostic:     use "D"iagnostic form
  ///   - replyTo:       a callback function (if any)
  public func sendTcp(_ cmd: String, diagnostic: Bool = false, replyTo callback: ReplyHandler? = nil) {
    apiModel?.sendTcp(cmd, diagnostic: diagnostic, replyTo: callback)
  }
  
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
    case .stream:               preProcessStream(statusMessage, connectionHandle, testMode)
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
    sendTcp("tnf remove \(id)", replyTo: callback)
    
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
  
  private func daxIqStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxIqs[id: id] == nil { daxIqs.append( DaxIq(id) ) }
      // parse the properties
      daxIqs[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxMicAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxMicAudio == nil { daxMicAudio = DaxMicAudio(id) }
      // parse the properties
      daxMicAudio?.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxRxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxRxAudios[id: id] == nil { daxRxAudios.append( DaxRxAudio(id) ) }
      // parse the properties
      daxRxAudios[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxTxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxTxAudio == nil { daxTxAudio = DaxTxAudio(id) }
      // parse the properties
      daxTxAudio?.parse( Array(properties.dropFirst(1)) )
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
        }
        panadapters[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        panadapters.remove(id: id)
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
  
  private func remoteRxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteRxAudio == nil { remoteRxAudio = RemoteRxAudio(id) }
      // parse the properties
      remoteRxAudio?.parse( Array(properties.dropFirst(2)) )
    }
  }

  private func remoteTxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteTxAudio == nil { remoteTxAudio = RemoteTxAudio(id)  }
      // parse the properties
      remoteTxAudio?.parse( Array(properties.dropFirst(2)) )
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
        }
        // parse the properties
        waterfalls[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        waterfalls.remove(id: id)
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
  
  public func preProcessStream(_ statusMessage: String, _ connectionHandle: UInt32?, _ testMode: Bool) {
    let properties = statusMessage.keyValuesArray()
    
    // is the 1st KeyValue a StreamId?
    if let id = properties[0].key.streamId {
      
      // is it a removal?
      if statusMessage.contains(kRemoved) {
        // YES
        removeStream(having: id)
        
      } else {
        // NO is it for me?
        if isForThisClient(properties, connectionHandle, testMode) {
          // YES
          guard properties.count > 1 else {
            log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
            return
          }
          guard let token = StreamType(rawValue: properties[1].value) else {
            // log it and ignore the Key
            log("StreamModel: unknown Stream type: \(properties[1].value)", .warning, #function, #file, #line)
            return
          }
          switch token {
            
          case .daxIqStream:          daxIqStatus(properties)
          case .daxMicAudioStream:    daxMicAudioStatus(properties)
          case .daxRxAudioStream:     daxRxAudioStatus(properties)
          case .daxTxAudioStream:     daxTxAudioStatus(properties)
          case .remoteRxAudioStream:  remoteRxAudioStatus(properties)
          case .remoteTxAudioStream:  remoteTxAudioStatus(properties)
            
          case .panadapter, .waterfall: break     // should never be seen here
          }
        }
      }
    } else {
      log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
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
    
    if activePacket != nil {
      // is this GuiClient already in GuiClients?
      if activePacket!.guiClients[id: handle] != nil {
        
        // update the packet's GuiClients collection
        activePacket!.guiClients[id: handle]!.clientId = clientId
        activePacket!.guiClients[id: handle]!.program = program
        activePacket!.guiClients[id: handle]!.station = station
        activePacket!.guiClients[id: handle]!.isLocalPtt = isLocalPtt
        
//        activePacket!.guiClients[id: handle] = guiClient
        
        // log the addition
        log("ObjectModel: guiClient UPDATED, \(handle.hex), \(station), \(program), \(clientId)", .info, #function, #file, #line)
        
        if radio!.isGui == false && station == activeStation {
          boundClientId = clientId
          sendTcp("client bind client_id=\(clientId)")
          log("ObjectModel: NonGui bound to \(station), \(program)", .debug, #function, #file, #line)
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
        activePacket!.guiClients[id: handle] = guiClient
        
        // log the addition
        log("ObjectModel: guiClient ADDED, \(handle.hex), \(station), \(program), \(clientId)", .info, #function, #file, #line)
        
        if !clientId.isEmpty && !program.isEmpty && !station.isEmpty {
          // the fields are populated
          
          activePacket!.guiClients[id: handle] = guiClient
          
          if radio!.isGui == false && station == activeStation {
            boundClientId = clientId
            sendTcp("client bind client_id=\(clientId)")
            log("ObjectModel: NonGui bound to \(station), \(program)", .debug, #function, #file, #line)
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
      activePacket?.guiClients[id: handle] = nil
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Removal methods

  private func removeStream(having id: UInt32) {
    if daxIqs[id: id] != nil {
      daxIqs.remove(id: id)
      log("ObjectModel: DaxIq \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxMicAudio?.id == id {
      daxMicAudio = nil
      log("ObjectModel: DaxMicAudio \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxRxAudios[id: id] != nil {
      daxRxAudios.remove(id: id)
      log("ObjectModel: DaxRxAudio \(id.hex): REMOVED", .debug, #function, #file, #line)

    } else if daxTxAudio?.id == id {
      daxTxAudio = nil
      log("ObjectModel: DaxTxAudio \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteRxAudio?.id == id {
      remoteRxAudio = nil
      log("ObjectModel: RemoteRxAudio \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteTxAudio?.id == id {
      remoteTxAudio = nil
      log("ObjectModel: RemoteTxAudio \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Helper methods

  /// Determine if status is for this client
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - clientHandle:   the handle of ???
  /// - Returns:          true if a mtch
  private func isForThisClient(_ properties: KeyValuesArray, _ connectionHandle: UInt32?, _ testMode: Bool) -> Bool {
    var clientHandle : UInt32 = 0
    
    guard testMode == false else { return true }
    
    if let connectionHandle {
      // find the handle property
      for property in properties.dropFirst(2) where property.key == "client_handle" {
        clientHandle = property.value.handle ?? 0
      }
      return clientHandle == connectionHandle
    }
    return false
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
