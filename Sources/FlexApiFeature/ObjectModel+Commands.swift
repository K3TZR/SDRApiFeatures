//
//  ApiModel+Commands.swift
//  
//
//  Created by Douglas Adams on 5/25/23.
//

import Foundation

import SharedFeature

extension ObjectModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Request methods
  
  public func setMtuLimit(_ size: Int, replyTo callback: ReplyHandler? = nil) {
    sendTcp("client set enforce_network_mtu=1 network_mtu=\(size)")
  }
  
  public func setLowBandwidthDax(_ enable: Bool, replyTo callback: ReplyHandler? = nil) {
    sendTcp("client set send_reduced_bw_dax=\(enable.as1or0)")
  }
  
  public func requestAntennaList(replyTo callback: ReplyHandler? = nil) {
    sendTcp("ant list", replyTo: callback)
  }
  
  public func setCwKeyImmediate(state: Bool, replyTo callback: ReplyHandler? = nil) {
    sendTcp("cw key immediate" + " \(state.as1or0)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Amplifier methods
  
  public func requestAmplifier(ip: String, port: Int, model: String, serialNumber: String, antennaPairs: String, replyTo callback: ReplyHandler? = nil) {
    // TODO: add code
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - BandSetting methods
  
  public func requestBandSetting(_ channel: String, replyTo callback: ReplyHandler? = nil) {
    // FIXME: need information
  }
  
  public func removeBandSetting(_ id: UInt32, replyTo callback: ReplyHandler? = nil) {
    // TODO: test this
    
    // tell the Radio to remove a Stream
    sendTcp("transmit band remove " + "\(id)", replyTo: callback)
    
    // notify all observers
    //    NC.post(.bandSettingWillBeRemoved, object: self as Any?)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Equalizer methods
  
  public func requestEqualizerInfo(_ eqType: String, replyTo callback:  ReplyHandler? = nil) {
    // ask the Radio for an Equalizer's settings
    sendTcp("eq " + eqType + " info", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Panadapter methods
  
  public func removePanadapter(_ id: UInt32, replyTo callback: ReplyHandler? = nil) {
    sendTcp("display panafall remove \(id)", replyTo: callback)
  }
  
  public func requestPanadapter(callback: ReplyHandler? = nil) {
    sendTcp("display panafall create x=50, y=50", replyTo: callback)
  }

  public func requestRfGainList(_ streamId: UInt32, replyTo callback: ReplyHandler? = nil) {
    sendTcp("display pan rfgain_info \(streamId.hex)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Profile methods
  
  public func requestDisplayProfile(replyTo callback: ReplyHandler? = nil) {
    sendTcp("profile display info", replyTo: callback)
  }
  
  public func requestGlobalProfile(replyTo callback: ReplyHandler? = nil) {
    sendTcp("profile global info", replyTo: callback)
  }
  
  public func requestMicProfile(replyTo callback: ReplyHandler? = nil) {
    sendTcp("profile mic info", replyTo: callback)
  }
  
  public func requestTxProfile(replyTo callback: ReplyHandler? = nil) {
    sendTcp("profile tx info", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Radio methods
  
  public func requestInfo(replyTo callback: ReplyHandler? = nil) {
    sendTcp("info", replyTo: callback )
  }
  
  public func requestLicense(replyTo callback: ReplyHandler? = nil) {
    sendTcp("license refresh", replyTo: callback)
  }
  
  public func setLowBandwidthConnect(replyTo callback: ReplyHandler? = nil) {
    sendTcp("client low_bw_connect", replyTo: callback)
  }
  
  public func requestMicList(replyTo callback: ReplyHandler? = nil) {
    sendTcp("mic list", replyTo: callback)
  }
  
  public func staticNetParamsReset(replyTo callback: ReplyHandler? = nil) {
    sendTcp("radio static_net_params" + " reset", replyTo: callback)
  }
  
  public func staticNetParamsSet(replyTo callback: ReplyHandler? = nil) {
    //    sendTcp("radio static_net_params" + " ip=\(staticIp) gateway=\(staticGateway) netmask=\(staticMask)")
  }
  public func requestPersistenceOff(replyTo callback: ReplyHandler? = nil) {
    sendTcp("client program start_persistence off", replyTo: callback)
  }

  public func requestReboot(replyTo callback: ReplyHandler? = nil) {
    sendTcp("radio reboot", replyTo: callback)
  }

  public func requestUptime(replyTo callback: ReplyHandler? = nil) {
    sendTcp("radio uptime", replyTo: callback)
  }
  
  public func requestVersion(replyTo callback: ReplyHandler? = nil) {
    sendTcp("version", replyTo: callback )
  }
    
 // ----------------------------------------------------------------------------
  // MARK: - Slice methods
  
  public func removeSlice(_ id: UInt32, replyTo callback: ReplyHandler? = nil) {
    sendTcp("slice remove \(id)", replyTo: callback)
  }
  
  public func requestSlice(callback: ReplyHandler? = nil) {
    sendTcp("slice create", replyTo: callback)
  }
  
  public func requestSlice(panadapter: Panadapter?, mode: String = "", frequency: Hz = 0,  rxAntenna: String = "", usePersistence: Bool = false, replyTo callback: ReplyHandler? = nil) {
    //          if availableSlices > 0 {
    
    var cmd = "slice create"
    if panadapter != nil  { cmd += " pan=\(panadapter!.id.hex)" }
    if frequency != 0     { cmd += " freq=\(frequency.hzToMhz)" }
    if rxAntenna != ""    { cmd += " rxant=\(rxAntenna)" }
    if mode != ""         { cmd += " mode=\(mode)" }
    if usePersistence     { cmd += " load_from=PERSISTENCE" }
    
    // tell the Radio to create a Slice
    sendTcp(cmd, replyTo: callback)
    //          }
  }
  
  public func requestSlice(on panadapter: Panadapter, at frequency: Hz = 0, replyTo callback: ReplyHandler? = nil) {
    //          if availableSlices > 0 {
    sendTcp("slice create " + "pan" + "=\(panadapter.id.hex) \(frequency == 0 ? "" : "freq" + "=\(frequency.hzToMhz)")", replyTo: callback)
    //          }
  }
  
  //  @MainActor public func sliceMakeActive(_ slice: Slice) {
  //    for slice in objectModel.slices {
  //      slice.active = false
  //    }
  //    slice.active = true
  //    objectModel.activeSlice = slice
  //  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tnf methods
  
  public func requestTnf(at frequency: Hz, replyTo callback: ReplyHandler? = nil) {
    sendTcp("tnf create " + "freq" + "=\(frequency.hzToMhz)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: Stream methods
  
  public func requestStream(_ streamType: StreamType, daxChannel: Int = 0, isCompressed: Bool = false, replyTo callback: ReplyHandler? = nil)  {
    switch streamType {
    case .remoteRxAudioStream:  sendTcp("stream create type=\(streamType.rawValue) compression=\(isCompressed ? "opus" : "none")", replyTo: callback)
    case .remoteTxAudioStream:  sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxMicAudioStream:    sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxRxAudioStream:     sendTcp("stream create type=\(streamType.rawValue) dax_channel=\(daxChannel)", replyTo: callback)
    case .daxTxAudioStream:     sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
    case .daxIqStream:          sendTcp("stream create type=\(streamType.rawValue) dax_channel=\(daxChannel)", replyTo: callback)
    default: return
    }
  }

  public func removeStream(_ streamId: UInt32?)  {
    if let streamId {
      sendTcp("stream remove \(streamId.hex)")
    }
  }

}
