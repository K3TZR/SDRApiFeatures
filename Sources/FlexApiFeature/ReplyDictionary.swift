//
//  ReplyProcessor.swift
//
//
//  Created by Douglas Adams on 5/19/24.
//

import Foundation

public typealias ReplyHandler = (_ command: String, _ reply: String) -> Void
public typealias ReplyTuple = (command: String, callback: ReplyHandler? )

final public actor ReplyDictionary {
  private var replyHandlers = [Int: ReplyTuple]()
  private var sequenceNumber: Int = 0
  
  public func add(_ command: String, callback: ReplyHandler?) -> Int {
    sequenceNumber += 1
    replyHandlers[sequenceNumber] = (command, callback)
    return sequenceNumber
  }
  
  public func remove(_ sequenceNumber: Int) {
    replyHandlers[sequenceNumber] = nil
  }
  
  public func removeAll() {
    replyHandlers.removeAll()
  }
  
  subscript(sequenceNumber: Int) -> ReplyTuple? {
      get { replyHandlers[sequenceNumber] }
  }
}

