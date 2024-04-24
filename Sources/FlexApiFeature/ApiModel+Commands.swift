//
//  ApiModel+Commands.swift
//  
//
//  Created by Douglas Adams on 5/25/23.
//

import Foundation

import SharedFeature
import TcpFeature
import UdpFeature
import XCGLogFeature

extension ApiModel {
  
  public func addReplyHandler(_ sequenceNumber: UInt, _ replyTuple: ReplyTuple) {
    replyHandlers[sequenceNumber] = replyTuple
  }
  
  public func removeReplyHandler(_ sequenceNumber: UInt) {
    replyHandlers[sequenceNumber] = nil
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  /// Send a command to the Radio (hardware) via TCP
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  public func sendCommand(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    let sequenceNumber = Tcp.shared.send(command, diagnostic: flag)
    
    // register to be notified when reply received
    addReplyHandler(sequenceNumber, (replyTo: callback, command: command))
  }
  
  /// Send data to the Radio (hardware) via UDP
  /// - Parameters:
  ///   - data: a Data
  public func sendUdp(data: Data) {
    // tell Udp to send the Data message
    Udp.shared.send(data)
  }
  
  /// Send data to the Radio (hardware) via UDP
  /// - Parameters:
  ///   - string: a String
  public func sendUdp(string: String) {
    // tell Udp to send the String message
    Udp.shared.send(string)
  }
  
  //  public func removeReplyHandler(_ seqNumber: UInt) {
  //    self.replyHandlers[seqNumber] = nil
  //  }
  
  public func bindToGuiClient(_ clientId: UUID?, callback:  ReplyHandler? = nil) {
    if let clientId = clientId, ApiModel.shared.isGui == false, boundClientId == nil {
      sendCommand("client bind client_id=" + clientId.uuidString, replyTo: callback)
    }
    Task { await MainActor.run { boundClientId = clientId?.uuidString }}
  }
  // ----------------------------------------------------------------------------
  // MARK: - Public Request methods
  
  public func requestMtuLimit(_ size: Int, callback: ReplyHandler? = nil) {
    sendCommand("client set enforce_network_mtu=1 network_mtu=\(size)")
  }
  
  public func requestLowBandwidthDax(_ enable: Bool, callback: ReplyHandler? = nil) {
    sendCommand("client set send_reduced_bw_dax=\(enable.as1or0)")
  }
  
  public func requestAntennaList(callback: ReplyHandler? = nil) {
    sendCommand("ant list", replyTo: callback)
  }
  
  public func requestCwKeyImmediate(state: Bool, callback: ReplyHandler? = nil) {
    sendCommand("cw key immediate" + " \(state.as1or0)", replyTo: callback)
  }
  
  public func requestInfo(callback: ReplyHandler? = nil) {
    sendCommand("info", replyTo: callback )
  }
  
  public func requestLicense(callback: ReplyHandler? = nil) {
    sendCommand("license refresh", replyTo: callback)
  }
  
  public func requestLowBandwidthConnect(callback: ReplyHandler? = nil) {
    sendCommand("client low_bw_connect", replyTo: callback)
  }
  
  public func requestMicList(callback: ReplyHandler? = nil) {
    sendCommand("mic list", replyTo: callback)
  }
  
  public func requestPersistenceOff(callback: ReplyHandler? = nil) {
    sendCommand("client program start_persistence off", replyTo: callback)
  }
  
  public func requestDisplayProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile display info", replyTo: callback)
  }
  
  public func requestGlobalProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile global info", replyTo: callback)
  }
  
  public func requestMicProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile mic info", replyTo: callback)
  }
  
  public func requestTxProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile tx info", replyTo: callback)
  }
  
  public func requestReboot(callback: ReplyHandler? = nil) {
    sendCommand("radio reboot", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Panadapter methods
  
  public func removePanadapter(_ id: UInt32, callback: ReplyHandler? = nil) {
    sendCommand("display panafall remove \(id)", replyTo: callback)
  }
  
  public func requestPanadapter(callback: ReplyHandler? = nil) {
    sendCommand("display panafall create x=50, y=50", replyTo: callback)
  }
  
 // ----------------------------------------------------------------------------
  // MARK: - Slice methods
  

  public func removeSlice(_ id: UInt32, callback: ReplyHandler? = nil) {
    sendCommand("slice remove \(id)", replyTo: callback)
  }
  
  public func requestSlice(callback: ReplyHandler? = nil) {
    sendCommand("slice create", replyTo: callback)
  }
  
  public func requestSlice(panadapter: Panadapter?, mode: String = "", frequency: Hz = 0,  rxAntenna: String = "", usePersistence: Bool = false, callback: ReplyHandler? = nil) {
    //          if availableSlices > 0 {
    
    var cmd = "slice create"
    if panadapter != nil  { cmd += " pan=\(panadapter!.id.hex)" }
    if frequency != 0     { cmd += " freq=\(frequency.hzToMhz)" }
    if rxAntenna != ""    { cmd += " rxant=\(rxAntenna)" }
    if mode != ""         { cmd += " mode=\(mode)" }
    if usePersistence     { cmd += " load_from=PERSISTENCE" }
    
    // tell the Radio to create a Slice
    sendCommand(cmd, replyTo: callback)
    //          }
  }
  
  public func requestSlice(on panadapter: Panadapter, at frequency: Hz = 0, callback: ReplyHandler? = nil) {
    //          if availableSlices > 0 {
    sendCommand("slice create " + "pan" + "=\(panadapter.id.hex) \(frequency == 0 ? "" : "freq" + "=\(frequency.hzToMhz)")", replyTo: callback)
    //          }
  }
  
  //  @MainActor public func sliceMakeActive(_ slice: Slice) {
  //    for slice in objectModel.slices {
  //      slice.active = false
  //    }
  //    slice.active = true
  //    objectModel.activeSlice = slice
  //  }
  
  
  public func requestTnf(at frequency: Hz, callback: ReplyHandler? = nil) {
    sendCommand("tnf create " + "freq" + "=\(frequency.hzToMhz)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK:
  
  public func requestUptime(replyTo callback: ReplyHandler? = nil) {
    sendCommand("radio uptime", replyTo: callback)
  }
  
  public func requestVersion(replyTo callback: ReplyHandler? = nil) {
    sendCommand("version", replyTo: callback )
  }
  
  public func staticNetParamsReset(replyTo callback: ReplyHandler? = nil) {
    sendCommand("radio static_net_params" + " reset", replyTo: callback)
  }
  
  public func staticNetParamsSet(replyTo callback: ReplyHandler? = nil) {
    //    sendTcp("radio static_net_params" + " ip=\(staticIp) gateway=\(staticGateway) netmask=\(staticMask)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: Stream methods
  
  public func requestStream(_ streamType: StreamType, daxChannel: Int = 0, isCompressed: Bool = false, replyTo callback: ReplyHandler? = nil)  {
    switch streamType {
    case .remoteRxAudioStream:  sendCommand("stream create type=\(streamType.rawValue) compression=\(isCompressed ? "opus" : "none")", replyTo: callback)
    case .remoteTxAudioStream:  sendCommand("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxMicAudioStream:    sendCommand("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxRxAudioStream:     sendCommand("stream create type=\(streamType.rawValue) dax_channel=\(daxChannel)", replyTo: callback)
    case .daxTxAudioStream:     sendCommand("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxIqStream:          sendCommand("stream create type=\(streamType.rawValue)", replyTo: callback)
    default: return
    }
  }

}
