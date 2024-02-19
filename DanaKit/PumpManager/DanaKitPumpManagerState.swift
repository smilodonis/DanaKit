//
//  DanaKitPumpManagerState.swift
//  DanaKit
//
//  Based on OmniKit/PumpManager/OmnipodPumpManagerState.swift
//  Created by Pete Schwamb on 8/4/18.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import LoopKit

public enum DanaKitBasal: Int {
    case active = 0
    case suspended = 1
    case tempBasal = 2
}

public enum BolusState: Int {
    case noBolus = 0
    case initiating = 1
    case inProgress = 2
    case canceling = 3
}

public struct DanaKitPumpManagerState: RawRepresentable, Equatable {
    public typealias RawValue = PumpManager.RawStateValue
    
    public init(rawValue: RawValue) {
        self.lastStatusDate = rawValue["lastStatusDate"] as? Date ?? Date()
        self.deviceName = rawValue["deviceName"] as? String
        self.bleIdentifier = rawValue["bleIdentifier"] as? String
        self.isConnected = false // To prevent having an old isConnected state
        self.reservoirLevel = rawValue["reservoirLevel"] as? Double ?? 0
        self.hwModel = rawValue["hwModel"] as? UInt8 ?? 0
        self.pumpProtocol = rawValue["pumpProtocol"] as? UInt8 ?? 0
        self.isInFetchHistoryMode = rawValue["isInFetchHistoryMode"] != nil
        self.ignorePassword = rawValue["ignorePassword"] as? Bool ?? false
        self.devicePassword = rawValue["devicePassword"] as? UInt16 ?? 0
        self.bolusSpeed = rawValue["bolusSpeed"] as? BolusSpeed ?? .speed12
        self.isOnBoarded = rawValue["isOnBoarded"] as? Bool ?? false
        self.basalDeliveryDate = rawValue["basalDeliveryDate"] as? Date ?? Date.now
        self.bolusState = rawValue["bolusState"] as? BolusState ?? .noBolus
        self.pumpTime = rawValue["pumpTime"] as? Date
        self.pumpTimeSyncedAt = rawValue["pumpTimeSyncedAt"] as? Date
        self.basalSchedule = rawValue["basalSchedule"] as? [Double] ?? []
        self.tempBasalUnits = rawValue["tempBasalUnits"] as? Double
        self.tempBasalDuration = rawValue["tempBasalDuration"] as? Double
        self.ble5Keys = rawValue["ble5Keys"] as? Data ?? Data([0, 0, 0, 0, 0, 0])
        self.isTimeDisplay24H = rawValue["isTimeDisplay24H"] as? Bool ?? false
        self.isButtonScrollOnOff = rawValue["isButtonScrollOnOff"] as? Bool ?? false
        self.lcdOnTimeInSec = rawValue["lcdOnTimeInSec"] as? UInt8 ?? 0
        self.backlightOnTimInSec = rawValue["backlightOnTimInSec"] as? UInt8 ?? 0
        self.units = rawValue["units"] as? UInt8 ?? 0
        self.lowReservoirRate = rawValue["lowReservoirRate"] as? UInt8 ?? 0
        self.selectedLanguage = rawValue["selectedLanguage"] as? UInt8 ?? 0
        self.shutdownHour = rawValue["shutdownHour"] as? UInt8 ?? 0
        self.cannulaVolume = rawValue["cannulaVolume"] as? UInt16 ?? 0
        self.refillAmount = rawValue["refillAmount"] as? UInt16 ?? 0
        self.targetBg = rawValue["targetBg"] as? UInt16
        self.useSilentTones = rawValue["useSilentTones"] as? Bool ?? true
        self.batteryRemaining = rawValue["batteryRemaining"] as? Double ?? 0
        
        if let rawInsulinType = rawValue["insulinType"] as? InsulinType.RawValue {
            insulinType = InsulinType(rawValue: rawInsulinType)
        }
        
        if let rawBeepAndAlarmType = rawValue["beepAndAlarm"] as? UInt8 {
            beepAndAlarm = BeepAlarmType(rawValue: rawBeepAndAlarmType) ?? .sound
        } else {
            beepAndAlarm = .sound
        }
        
        if let rawBasalDeliveryOrdinal = rawValue["basalDeliveryOrdinal"] as? DanaKitBasal.RawValue {
            self.basalDeliveryOrdinal = DanaKitBasal(rawValue: rawBasalDeliveryOrdinal) ?? .active
        } else {
            self.basalDeliveryOrdinal = .active
        }
    }
    
    public init(basalSchedule: [Double]? = nil) {
        self.lastStatusDate = Date()
        self.isConnected = false // To prevent having an old isConnected state
        self.reservoirLevel = 0
        self.hwModel = 0
        self.pumpProtocol = 0
        self.isInFetchHistoryMode = false
        self.ignorePassword = false
        self.devicePassword = 0
        self.bolusSpeed = .speed12
        self.isOnBoarded = false
        self.basalDeliveryDate = Date.now
        self.bolusState = .noBolus
        self.basalSchedule = basalSchedule ?? []
        self.ble5Keys = Data([0, 0, 0, 0, 0, 0])
        self.basalDeliveryOrdinal = .active
        self.isTimeDisplay24H = false
        self.isButtonScrollOnOff = false
        self.beepAndAlarm = .sound
        self.lcdOnTimeInSec = 0
        self.backlightOnTimInSec = 0
        self.units = 0
        self.lowReservoirRate = 0
        self.selectedLanguage = 0
        self.shutdownHour = 0
        self.cannulaVolume = 0
        self.refillAmount = 0
        self.targetBg = nil
        self.useSilentTones = false
        self.batteryRemaining = 0
    }
    
    public var rawValue: RawValue {
        var value: [String : Any] = [:]
        
        value["lastStatusDate"] = self.lastStatusDate
        value["deviceName"] = self.deviceName
        value["bleIdentifier"] = self.bleIdentifier
        value["reservoirLevel"] = self.reservoirLevel
        value["hwModel"] = self.hwModel
        value["pumpProtocol"] = self.pumpProtocol
        value["isInFetchHistoryMode"] = self.isInFetchHistoryMode
        value["ignorePassword"] = self.ignorePassword
        value["devicePassword"] = self.devicePassword
        value["insulinType"] = self.insulinType?.rawValue
        value["bolusSpeed"] = self.bolusSpeed.rawValue
        value["isOnBoarded"] = self.isOnBoarded
        value["basalDeliveryDate"] = self.basalDeliveryDate
        value["basalDeliveryOrdinal"] = self.basalDeliveryOrdinal.rawValue
        value["bolusState"] = self.bolusState.rawValue
        value["pumpTime"] = self.pumpTime
        value["pumpTimeSyncedAt"] = self.pumpTimeSyncedAt
        value["basalSchedule"] = self.basalSchedule
        value["tempBasalUnits"] = self.tempBasalUnits
        value["tempBasalDuration"] = self.tempBasalDuration
        value["ble5Keys"] = self.ble5Keys
        value["isTimeDisplay24H"] = self.isTimeDisplay24H
        value["isButtonScrollOnOff"] = self.isButtonScrollOnOff
        value["beepAndAlarm"] = self.beepAndAlarm.rawValue
        value["lcdOnTimeInSec"] = self.lcdOnTimeInSec
        value["backlightOnTimInSec"] = self.backlightOnTimInSec
        value["units"] = self.units
        value["selectedLanguage"] = self.selectedLanguage
        value["shutdownHour"] = self.shutdownHour
        value["cannulaVolume"] = self.cannulaVolume
        value["refillAmount"] = self.refillAmount
        value["targetBg"] = self.targetBg
        value["useSilentTones"] = self.useSilentTones
        value["batteryRemaining"] = self.batteryRemaining
        
        return value
    }
    
    /// The last moment this state has been updated (only for relavant values like isConnected or reservoirLevel)
    public var lastStatusDate: Date = Date()
    
    public var isOnBoarded = false
    
    /// The name of the device. Needed for en/de-crypting messages
    public var deviceName: String? = nil
    
    /// The bluetooth identifier. Used to reconnect to pump
    public var bleIdentifier: String? = nil
    
    /// Flag for checking if the device is still connected
    public var isConnected: Bool = false
    
    /// Current reservoir levels
    public var reservoirLevel: Double = 0
    
    /// The hardware model of the pump. Dertermines the friendly device name
    public var hwModel: UInt8 = 0x00
    
    /// Pump protocol
    public var pumpProtocol: UInt8 = 0x00
    
    public var bolusSpeed: BolusSpeed = .speed12
    
    public var batteryRemaining: Double = 0
    
    public var isPumpSuspended: Bool = false
    
    public var isTempBasalInProgress: Bool = false
    
    public var bolusState: BolusState = .noBolus
    
    public var insulinType: InsulinType? = nil
    
    /// The pump should be in history fetch mode, before requesting history data
    public var isInFetchHistoryMode: Bool = false
    
    public var ignorePassword: Bool = false
    public var devicePassword: UInt16 = 0
    
    public var basalSchedule: [Double]
    
    public var ble5Keys: Data = Data([0, 0, 0, 0, 0, 0])
    
    public var pumpTime: Date? {
        didSet {
            pumpTimeSyncedAt = Date.now
        }
    }
    public var pumpTimeSyncedAt: Date?
    
    /// User options
    public var isTimeDisplay24H: Bool
    public var isButtonScrollOnOff: Bool
    public var beepAndAlarm: BeepAlarmType
    public var lcdOnTimeInSec: UInt8
    public var backlightOnTimInSec: UInt8
    public var selectedLanguage: UInt8
    public var units: UInt8
    public var shutdownHour: UInt8
    public var lowReservoirRate: UInt8
    public var cannulaVolume: UInt16
    public var refillAmount: UInt16
    public var targetBg: UInt16?
    
    public var basalDeliveryDate: Date = Date.now
    public var basalDeliveryOrdinal: DanaKitBasal = .active
    public var tempBasalUnits: Double?
    public var tempBasalDuration: Double?
    public var basalDeliveryState: PumpManagerStatus.BasalDeliveryState {
        switch(self.basalDeliveryOrdinal) {
        case .active:
            return .active(self.basalDeliveryDate)
        case .suspended:
            return .suspended(self.basalDeliveryDate)
        case .tempBasal:
            return .tempBasal(DoseEntry.tempBasal(absoluteUnit: tempBasalUnits ?? 0, duration: tempBasalDuration ?? 0, insulinType: insulinType!, startDate: basalDeliveryDate))
        }
    }
    
    public var useSilentTones: Bool = false
    
    mutating func resetState() {
        self.ignorePassword = false
        self.devicePassword = 0
        self.isInFetchHistoryMode = false
    }
    
    func getFriendlyDeviceName() -> String {
        switch (self.hwModel) {
            case 0x01:
                return "DanaR Korean"

            case 0x03:
            switch (self.pumpProtocol) {
                case 0x00:
                  return "DanaR old"
                case 0x02:
                  return "DanaR v2"
                default:
                  return "DanaR" // 0x01 and 0x03 known
              }

            case 0x05:
                return self.pumpProtocol < 10 ? "DanaRS" : "DanaRS v3"

            case 0x06:
                return "DanaRS Korean"

            case 0x07:
                return "Dana-i (BLE4.2)"

            case 0x09:
                return "Dana-i (BLE5)"
            case 0x0a:
                return "Dana-i (BLE5, Korean)"
            default:
                return "Unknown Dana pump"
          }
    }
    
    func getDanaPumpImageName() -> String {
        switch (self.hwModel) {
        case 0x03:
            return "danars"
        case 0x05:
            return "danars"
        case 0x06:
            return "danars"
            
        case 0x07:
            return "danai"
        case 0x09:
            return "danai"
        case 0x0a:
            return "danai"
            
        default:
            return "danai"
        }
    }
    
    static func convertBasal(_ scheduleItems: [RepeatingScheduleValue<Double>]) -> [Double] {
        let basalIntervals: [TimeInterval] = Array(0..<24).map({ TimeInterval(60 * 60 * $0) })
        var output: [Double] = []
        
        var currentIndex = 0
        for i in 0..<24 {
            if (currentIndex >= scheduleItems.count) {
                output.append(scheduleItems[currentIndex - 1].value)
            } else if (scheduleItems[currentIndex].startTime != basalIntervals[i]) {
                output.append(scheduleItems[currentIndex - 1].value)
            } else {
                output.append(scheduleItems[currentIndex].value)
                currentIndex += 1
            }
        }
        
        return output
    }
}

extension DanaKitPumpManagerState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "## DanaKitPumpManagerState",
            "* isOnboarded: \(isOnBoarded)",
            "* isConnected: \(isConnected)",
            "* deviceName: \(String(describing: deviceName))",
            "* bleIdentifier: \(String(describing: bleIdentifier))",
            "* friendlyDeviceName: \(getFriendlyDeviceName())",
            "* insulinType: \(String(describing: insulinType))",
            "* reservoirLevel: \(reservoirLevel)",
            "* bolusState: \(bolusState.rawValue)",
            "* basalDeliveryDate: \(basalDeliveryDate)",
            "* basalDeliveryOrdinal: \(basalDeliveryOrdinal)",
            "* hwModel: \(hwModel)",
            "* pumpProtocol: \(pumpProtocol)",
            "* isInFetchHistoryMode: \(isInFetchHistoryMode)",
            "* ignorePassword: \(ignorePassword)"
        ].joined(separator: "\n")
    }
}
