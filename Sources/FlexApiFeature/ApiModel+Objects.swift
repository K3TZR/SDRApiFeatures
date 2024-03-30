//
//  File.swift
//
//
//  Created by Douglas Adams on 10/22/23.
//

import Foundation

import ListenerFeature
import SharedFeature
import XCGLogFeature

extension ApiModel {
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
//  public func setActiveStation(_ station: String?) {
//    self.activeStation = station
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func parse(_ type: ObjectType, _ statusMessage: String) async {
    
    switch type {
    case .amplifier:            amplifierStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .atu:                  atu.parse( Array(statusMessage.keyValuesArray() ))
    case .bandSetting:          bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst(1) ), !statusMessage.contains(kRemoved))
    case .client:               preProcessClient(statusMessage.keyValuesArray(), !statusMessage.contains(kDisconnected))
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
    case .tnf:                  tnfStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .transmit:             preProcessTransmit(statusMessage)
    case .usbCable:             usbCableStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .wan:                  wan.parse( Array(statusMessage.keyValuesArray().dropFirst(1)) )
    case .waveform:             waveform.parse( Array(statusMessage.keyValuesArray(delimiter: "=").dropFirst(1)) )
    case .xvtr:                 xvtrStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse))
      
    case .panadapter, .waterfall: break                                                   // handled by "display"
    case .stream: break                                                                   // handled by streamModel
    case .daxIqStream, .daxMicAudioStream, .daxRxAudioStream, .daxTxAudioStream:  break   // handled by "stream"
    case .remoteRxAudioStream, .remoteTxAudioStream:  break                               // handled by "stream"
    }
  }
  
  /// Remove all Radio objects
  func removeAllObjects() {    
    radio = nil
    removeAll(of: .amplifier)
    removeAll(of: .bandSetting)
    removeAll(of: .daxIqStream)
    removeAll(of: .daxMicAudioStream)
    removeAll(of: .daxRxAudioStream)
    removeAll(of: .daxTxAudioStream)
    removeAll(of: .equalizer)
    removeAll(of: .memory)
    removeAll(of: .meter)
    removeAll(of: .panadapter)
    removeAll(of: .profile)
    removeAll(of: .remoteRxAudioStream)
    removeAll(of: .remoteTxAudioStream)
    removeAll(of: .slice)
    removeAll(of: .tnf)
    removeAll(of: .usbCable)
    removeAll(of: .waterfall)
    removeAll(of: .xvtr)
    replyHandlers.removeAll()
  }
  
  func removeAll(of type: ObjectType) {
    switch type {
    case .amplifier:            amplifiers.removeAll()
    case .bandSetting:          bandSettings.removeAll()
    case .daxIqStream:          daxIqStreams.removeAll()
    case .daxMicAudioStream:    daxMicAudioStreams.removeAll()
    case .daxRxAudioStream:     daxRxAudioStreams.removeAll()
    case .daxTxAudioStream:     daxTxAudioStreams.removeAll()
    case .equalizer:            equalizers.removeAll()
    case .memory:               memories.removeAll()
    case .meter:                meters.removeAll()
    case .panadapter:
      panadapters.removeAll()
    case .profile:              profiles.removeAll()
    case .remoteRxAudioStream:  remoteRxAudioStreams.removeAll()
    case .remoteTxAudioStream:  remoteTxAudioStreams.removeAll()
    case .slice:                slices.removeAll()
    case .tnf:                  tnfs.removeAll()
    case .usbCable:             usbCables.removeAll()
    case .waterfall:
      waterfalls.removeAll()
    case .xvtr:                 xvtrs.removeAll()
    default:            break
    }
    log("ApiModel: removed all \(type.rawValue) objects", .debug, #function, #file, #line)
  }
  
//  public func meterBy(shortName: Meter.ShortName, slice: Slice? = nil) -> Meter? {
//    
//    if slice == nil {
//      for meter in meters where meter.name == shortName.rawValue {
//        return meter
//      }
//    } else {
//      for meter in meters where slice!.id == UInt32(meter.group) && meter.name == shortName.rawValue {
//        return meter
//      }
//    }
//    return nil
//  }
  
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
        if amplifiers[id: id] == nil { amplifiers.append( Amplifier(id, self) ) }
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
        if bandSettings[id: id] == nil { bandSettings.append( BandSetting(id, self) ) }
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
      if equalizers[id: id] == nil { equalizers.append( Equalizer(id, self) ) }
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
        if memories[id: id] == nil { memories.append( Memory(id, self) ) }
        // parse the properties
        memories[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        memories.remove(id: id)
        log("Memory \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  //  private func meterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
  //    // get the id
  //    if let id = UInt32(properties[0].key.components(separatedBy: ".")[0], radix: 10) {
  //      // is it in use?
  //      if inUse {
  //        // YES, add it if not already present
  //        if meters[id: id] == nil { meters.append( Meter(id) ) }
  //        // parse the properties
  //        meters[id: id]!.parse(properties )
  //
  //      } else {
  //        // NO, remove it
  //        meters.remove(id: id)
  //        log("Meter \(id): REMOVED", .debug, #function, #file, #line)
  //      }
  //    }
  //  }
  
  private func panadapterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.streamId {
      // is it in use?
      if inUse {
        // parse the properties
        // YES, add it if not already present
        if panadapters[id: id] == nil {
          panadapters.append( Panadapter(id, self) )
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
      if profiles[id: id] == nil { profiles.append( Profile(id, self) ) }
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
        if slices[id: id] == nil { slices.append(Slice(id, self)) }
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
        if tnfs[id: id] == nil { tnfs.append( Tnf(id, self) ) }
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
      if usbCables[id: id] == nil { usbCables.append( UsbCable(id, self) ) }
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
        if waterfalls[id: id] == nil { waterfalls.append( Waterfall(id, self) ) }
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
        if xvtrs[id: id] == nil { xvtrs.append( Xvtr(id, self) ) }
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
  
  private func preProcessClient(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is there a valid handle"
    if let handle = properties[0].key.handle {
      switch properties[1].key {
        
      case kConnected:       parseConnection(properties: properties, handle: handle)
      case kDisconnected:    parseDisconnection(properties: properties, handle: handle)
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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Helper methods
  
  /// Parse a client connect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseConnection(properties: KeyValuesArray, handle: UInt32) {
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
    if handle == connectionHandle { clientInitialized = true }
    
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown properties
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore this Key
        log("ApiModel: unknown client property, \(property.key)=\(property.value)", .warning, #function, #file, #line)
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
          log("ApiModel: guiClient UPDATED, \(guiClient.handle.hex), \(guiClient.station), \(guiClient.program), \(guiClient.clientId ?? "nil")", .info, #function, #file, #line)

          if !_isGui && station == ListenerModel.shared.activeStation {
             boundClientId = clientId
            sendCommand("client bind client_id=\(boundClientId!)")
            log("ApiModel: NonGui bound to \(guiClient.station), \(guiClient.program)", .debug, #function, #file, #line)
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
        log("ApiModel: guiClient ADDED, \(guiClient.handle.hex), \(guiClient.station), \(guiClient.program), \(guiClient.clientId ?? "nil")", .info, #function, #file, #line)
        
        if !clientId.isEmpty && !program.isEmpty && !station.isEmpty {
          // the fields are populated

          packet.guiClients[id: handle] = guiClient

          if !_isGui && station == ListenerModel.shared.activeStation {
             boundClientId = clientId
            sendCommand("client bind client_id=\(boundClientId!)")
            log("ApiModel: NonGui bound to \(guiClient.station), \(guiClient.program)", .debug, #function, #file, #line)
          }
        }
      }
    }
  }
  
  /// Parse a client disconnect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseDisconnection(properties: KeyValuesArray, handle: UInt32) {
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
      log("ApiModel: client disconnection, reason = \(reason)", .warning, #function, #file, #line)
      
      //      apiModel.disconnect(reason)
      
    } else {
      // NO
      //      print("-----> Client disconnected, properties = \(properties), handle = \(handle.hex)")
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
  // MARK: - Private Subscription methods
  
  /// Process the AsyncStream of inbound TCP messages
  //  private func subscribeToMessages()  {
  //    Task(priority: .low) {
  //      log("Api: TcpMessage subscription STARTED", .debug, #function, #file, #line)
  //      for await tcpMessage in Tcp.shared.inboundMessagesStream {
  //        radio?.tcpInbound(tcpMessage.text)
  //      }
  //      log("Api: TcpMessage subscription STOPPED", .debug, #function, #file, #line)
  //    }
  //  }
  //
  //  /// Process the AsyncStream of TCP status changes
  //  private func subscribeToTcpStatus() {
  //    Task(priority: .low) {
  //      log("Api: TcpStatus subscription STARTED", .debug, #function, #file, #line)
  //      for await status in Tcp.shared.statusStream {
  //        radio?.tcpStatus(status)
  //      }
  //      log("Api: TcpStatus subscription STOPPED", .debug, #function, #file, #line)
  //    }
  //  }
  //
  //  /// Process the AsyncStream of UDP status changes
  //  private func subscribeToUdpStatus() {
  //    Task(priority: .low) {
  //      log("Api: UdpStatus subscription STARTED", .debug, #function, #file, #line)
  //      for await status in Udp.shared.statusStream {
  //        radio?.udpStatus(status)
  //      }
  //      log("Api: UdpStatus subscription STOPPED", .debug, #function, #file, #line)
  //    }
  //  }
}
