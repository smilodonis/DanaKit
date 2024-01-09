//
//  DanaKitPumpManager.swift
//  DanaKit
//
//  Based on OmniKit/PumpManager/OmnipodPumpManager.swift
//  Created by Pete Schwamb on 8/4/18.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import UserNotifications
import os.log
import SwiftUI
import CoreBluetooth

private enum ConnectionResult {
    case success
    case failure
}

public protocol StateObserver: AnyObject {
    func stateDidUpdate(_ state: DanaKitPumpManagerState, _ oldState: DanaKitPumpManagerState)
    func deviceScanDidUpdate(_ device: DanaPumpScan)
}

public class DanaKitPumpManager: DeviceManager {
    private static var bluetoothManager = BluetoothManager()
    
    private var oldState: DanaKitPumpManagerState
    public var state: DanaKitPumpManagerState
    public var rawState: PumpManager.RawStateValue {
        return state.rawValue
    }
    
    public static let pluginIdentifier: String = "Dana" // use a single token to make parsing log files easier
    public let managerIdentifier: String = "Dana"
    
    public let localizedTitle = LocalizedString("Dana-i/RS", comment: "Generic title of the DanaKit pump manager")
    
    public init(state: DanaKitPumpManagerState, dateGenerator: @escaping () -> Date = Date.init) {
        self.state = state
        self.oldState = DanaKitPumpManagerState(rawValue: state.rawValue)
        
        DanaKitPumpManager.bluetoothManager.pumpManagerDelegate = self
    }
    
    public required convenience init?(rawState: PumpManager.RawStateValue) {
        self.init(state: DanaKitPumpManagerState(rawValue: rawState))
    }
    
    private let log = OSLog(category: "DanaKitPumpManager")
    private let pumpDelegate = WeakSynchronizedDelegate<PumpManagerDelegate>()
    
    private let stateObservers = WeakSynchronizedSet<StateObserver>()
    private let scanDeviceObservers = WeakSynchronizedSet<StateObserver>()
    
    private let basalProfileNumber: UInt8 = 1
    
    public var isOnboarded: Bool {
        self.state.isOnBoarded
    }
    
    public var currentBaseBasalRate: Double = 0
    
    public var debugDescription: String {
        let lines = [
            "## DanaKitPumpManager",
            state.debugDescription,
            "#### DanaKit logs:",
            log.getDebugLogs()
        ]
        return lines.joined(separator: "\n")
    }
    
    public func connect(_ peripheral: CBPeripheral, _ view: UIViewController?, _ completion: @escaping (Error?) -> Void) {
        DanaKitPumpManager.bluetoothManager.connect(peripheral, view, completion)
    }
    
    public func disconnect(_ peripheral: CBPeripheral) {
        DanaKitPumpManager.bluetoothManager.disconnect(peripheral)
        self.state.resetState()
    }
    
    public func startScan() throws {
        try DanaKitPumpManager.bluetoothManager.startScan()
    }
    
    public func stopScan() {
        DanaKitPumpManager.bluetoothManager.stopScan()
    }
}

extension DanaKitPumpManager: PumpManager {
    public static var onboardingMaximumBasalScheduleEntryCount: Int {
        return 24
    }
    
    public static var onboardingSupportedBasalRates: [Double] {
        // 0.05 units for rates between 0.00-3U/hr
        // 0 U/hr is a supported scheduled basal rate
        return (0...30).map { Double($0) / 10 }
    }
    
    public static var onboardingSupportedBolusVolumes: [Double] {
        // 0.10 units for rates between 0.10-30U
        // 0 is not a supported bolus volume
        return (1...300).map { Double($0) / 10 }
    }
    
    public static var onboardingSupportedMaximumBolusVolumes: [Double] {
        return DanaKitPumpManager.onboardingSupportedBolusVolumes
    }
    
    public var delegateQueue: DispatchQueue! {
        get {
            return pumpDelegate.queue
        }
        set {
            pumpDelegate.queue = newValue
        }
    }
    
    public var supportedBasalRates: [Double] {
        return DanaKitPumpManager.onboardingSupportedBasalRates
    }
    
    public var supportedBolusVolumes: [Double] {
        return DanaKitPumpManager.onboardingSupportedBolusVolumes
    }
    
    public var supportedMaximumBolusVolumes: [Double] {
        // 0.05 units for rates between 0.05-30U
        // 0 is not a supported bolus volume
        return DanaKitPumpManager.onboardingSupportedBolusVolumes
    }
    
    public var maximumBasalScheduleEntryCount: Int {
        return DanaKitPumpManager.onboardingMaximumBasalScheduleEntryCount
    }
    
    public var minimumBasalScheduleEntryDuration: TimeInterval {
        return TimeInterval(30 * 60)
    }
    
    public var pumpManagerDelegate: LoopKit.PumpManagerDelegate? {
        get {
            return pumpDelegate.delegate
        }
        set {
            pumpDelegate.delegate = newValue
        }
    }
    
    public var pumpRecordsBasalProfileStartEvents: Bool {
        return false
    }
    
    public var pumpReservoirCapacity: Double {
        return Double(self.state.reservoirLevel)
    }
    
    public var lastSync: Date? {
        return self.state.lastStatusDate
    }
    
    public var status: LoopKit.PumpManagerStatus {
        return PumpManagerStatus(timeZone: TimeZone(identifier: "Europe/Amsterdam")!, device: device(), pumpBatteryChargeRemaining: nil, basalDeliveryState: nil, bolusState: .noBolus, insulinType: nil)
    }
    
    public func addStatusObserver(_ observer: PumpManagerStatusObserver, queue: DispatchQueue) {
    }
    
    public func removeStatusObserver(_ observer: PumpManagerStatusObserver) {
    }
    
    public func ensureCurrentPumpData(completion: ((Date?) -> Void)?) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion?(nil)
                return
            case .success:
                Task {
                    do {
                        try await DanaKitPumpManager.bluetoothManager.updateInitialState()
                        completion?(Date.now)
                    } catch {
                        completion?(nil)
                    }
                }
            }
        }
    }
    
    public func setMustProvideBLEHeartbeat(_ mustProvideBLEHeartbeat: Bool) {
    }
    
    public func createBolusProgressReporter(reportingOn dispatchQueue: DispatchQueue) -> LoopKit.DoseProgressReporter? {
        return nil
    }
    
    public func estimatedDuration(toBolus units: Double) -> TimeInterval {
        switch(self.state.bolusSpeed) {
        case .speed12:
            return units / 720
        case .speed30:
            return units / 1800
        case .speed60:
            return units / 3600
        }
    }
    
    public func enactBolus(units: Double, activationType: BolusActivationType, completion: @escaping (PumpManagerError?) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(PumpManagerError.connection(DanaKitPumpManagerError.noConnection))
                return
            case .success:
                Task {
                    do {
                        let packet = generatePacketBolusStart(options: PacketBolusStart(amount: units, speed: self.state.bolusSpeed))
                        let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                        
                        if (!result.success) {
                            completion(PumpManagerError.uncertainDelivery)
                            return
                        }
                        
                        completion(nil)
                    } catch {
                        self.log.error("%{public}@: Failed to do bolus. Error: %{public}@", #function, error.localizedDescription)
                        completion(PumpManagerError.connection(DanaKitPumpManagerError.noConnection))
                    }
                }
            }
        }
    }
    
    public func cancelBolus(completion: @escaping (PumpManagerResult<DoseEntry?>) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(.failure(PumpManagerError.connection(DanaKitPumpManagerError.noConnection)))
                return
            case .success:
                Task {
                    do {
                        let packet = generatePacketBolusStop()
                        let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                        
                        if (!result.success) {
                            completion(.failure(PumpManagerError.communication(nil)))
                            return
                        }
                        
                        completion(.success(nil))
                    } catch {
                        completion(.failure(PumpManagerError.communication(DanaKitPumpManagerError.noConnection)))
                    }
                }
            }
        }
    }
    
    /// NOTE: There are 2 ways to set a temp basal:
    /// - The normal way (which only accepts full hours)
    /// - A short APS-special temp basal command (which only accepts 15 (only above 100%) or 30 min (only below 100%)
    /// TODO: Need to discuss what to do here / how to make this work within the Loop algorithm AND if the convertion from absolute to percentage is acceptable
    public func enactTempBasal(unitsPerHour: Double, for duration: TimeInterval, completion: @escaping (PumpManagerError?) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(PumpManagerError.connection(DanaKitPumpManagerError.noConnection))
                return
            case .success:
                Task {
                    if (duration < .ulpOfOne) {
                        do {
                            let packet = generatePacketBasalCancelTemporary()
                            let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                            
                            if (!result.success) {
                                completion(PumpManagerError.configuration(DanaKitPumpManagerError.failedTempBasalAdjustment))
                                return
                            }
                            
                            completion(nil)
                        } catch {
                            completion(PumpManagerError.communication(nil))
                        }
                    } else {
                        do {
                            var tempBasalPercentage: UInt16 = 0
                            // Any basal less than 0.10u/h will be dumped once per hour. So if it's less than .10u/h, set a zero temp.
                            if (unitsPerHour >= 0.1) {
                                tempBasalPercentage = UInt16(ceil(unitsPerHour / self.currentBaseBasalRate * 100))
                            }
                            
                            let packet = generatePacketLoopSetTemporaryBasal(options: PacketLoopSetTemporaryBasal(percent: tempBasalPercentage))
                            let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                            
                            if (!result.success) {
                                completion(PumpManagerError.configuration(DanaKitPumpManagerError.failedTempBasalAdjustment))
                                return
                            }
                            
                            completion(nil)
                        } catch {
                            completion(PumpManagerError.communication(nil))
                        }
                    }
                }
            }
        }
    }
    
    public func suspendDelivery(completion: @escaping (Error?) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(PumpManagerError.connection(DanaKitPumpManagerError.noConnection))
                return
            case .success:
                Task {
                    do {
                        let packet = generatePacketBasalSetSuspendOn()
                        let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                        
                        if (!result.success) {
                            completion(PumpManagerError.configuration(DanaKitPumpManagerError.failedSuspensionAdjustment))
                            return
                        }
                        
                        completion(nil)
                    } catch {
                        completion(PumpManagerError.communication(DanaKitPumpManagerError.noConnection))
                    }
                }
            }
        }
    }
    
    public func resumeDelivery(completion: @escaping (Error?) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(PumpManagerError.connection(DanaKitPumpManagerError.noConnection))
                return
            case .success:
                Task {
                    do {
                        let packet = generatePacketBasalSetSuspendOff()
                        let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                        
                        if (!result.success) {
                            completion(PumpManagerError.configuration(DanaKitPumpManagerError.failedSuspensionAdjustment))
                            return
                        }
                        
                        completion(nil)
                    } catch {
                        completion(PumpManagerError.communication(DanaKitPumpManagerError.noConnection))
                    }
                }
            }
        }
    }
    
    public func syncBasalRateSchedule(items scheduleItems: [RepeatingScheduleValue<Double>], completion: @escaping (Result<BasalRateSchedule, Error>) -> Void) {
        self.ensureConnected { result in
            switch result {
            case .failure:
                completion(.failure(PumpManagerError.connection(DanaKitPumpManagerError.noConnection)))
                return
            case .success:
                Task {
                    do {
                        let basal = self.convertBasal(scheduleItems)
                        let packet = try generatePacketBasalSetProfileRate(options: PacketBasalSetProfileRate(profileNumber: self.basalProfileNumber, profileBasalRate: basal))
                        let result = try await DanaKitPumpManager.bluetoothManager.writeMessage(packet)
                        
                        if (!result.success) {
                            completion(.failure(PumpManagerError.configuration(DanaKitPumpManagerError.failedBasalAdjustment)))
                            return
                        }
                        
                        guard let schedule = DailyValueSchedule<Double>(dailyItems: scheduleItems) else {
                            completion(.failure(PumpManagerError.configuration(DanaKitPumpManagerError.failedBasalGeneration)))
                            return
                        }
                        
                        completion(.success(schedule))
                    } catch {
                        completion(.failure(PumpManagerError.communication(DanaKitPumpManagerError.noConnection)))
                    }
                }
            }
        }
    }
    
    public func syncDeliveryLimits(limits deliveryLimits: DeliveryLimits, completion: @escaping (Result<DeliveryLimits, Error>) -> Void) {
        // Dana does not allow the max basal and max bolus to be set
        // Max basal = 3 U/hr
        // Max bolus = 20U
        
        completion(.success(deliveryLimits))
    }
    
    private func device() -> HKDevice {
        return HKDevice(
            name: managerIdentifier,
            manufacturer: "Sooil",
            model: self.state.getFriendlyDeviceName(),
            hardwareVersion: String(self.state.hwModel),
            firmwareVersion: String(self.state.pumpProtocol),
            softwareVersion: "",
            localIdentifier: self.state.deviceName,
            udiDeviceIdentifier: nil
        )
    }
    
    private func convertBasal(_ scheduleItems: [RepeatingScheduleValue<Double>]) -> [Double] {
        let basalIntervals: [TimeInterval] = Array(0..<24).map({ TimeInterval(60 * 30 * $0) })
        var output: [Double] = []
        
        var currentIndex = 0
        for i in 0..<24 {
            if (scheduleItems[currentIndex].startTime != basalIntervals[i]) {
                output.append(scheduleItems[currentIndex - 1].value)
            } else {
                output.append(scheduleItems[currentIndex].value)
                currentIndex += 1
            }
        }
        
        return output
    }
    
    private func ensureConnected(_ completion: @escaping (ConnectionResult) -> Void) {
        // Device still has an active connection with pump
        if DanaKitPumpManager.bluetoothManager.isConnected {
            completion(.success)
        
        // There is no active connection, but we stored the peripheral. We can quickly reconnect
        } else if !DanaKitPumpManager.bluetoothManager.isConnected && DanaKitPumpManager.bluetoothManager.peripheral != nil {
            self.connect(DanaKitPumpManager.bluetoothManager.peripheral!, nil, { error in
                if error == nil {
                    completion(.success)
                } else {
                    completion(.failure)
                }
            })
            
        // No active connection and no stored peripheral. We have to scan for device before being able to send command
        } else if !DanaKitPumpManager.bluetoothManager.isConnected && self.state.bleIdentifier != nil {
            do {
                try DanaKitPumpManager.bluetoothManager.connect(self.state.bleIdentifier!, nil, { error in
                    if error == nil {
                        completion(.success)
                    } else {
                        completion(.failure)
                    }
                })
            } catch {
                completion(.failure)
            }
        
        // Should never reach, but is only possible if device is not onboard (we have no ble identifier to search for)
        } else {
            log.error("%{public}@: Pump is not onboarded", #function)
            completion(.failure)
        }
    }
}

extension DanaKitPumpManager: AlertSoundVendor {
    public func getSoundBaseURL() -> URL? {
        return nil
    }

    public func getSounds() -> [LoopKit.Alert.Sound] {
        return []
    }
}

extension DanaKitPumpManager {
    public func acknowledgeAlert(alertIdentifier: LoopKit.Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
    }
}

// MARK: State observers
extension DanaKitPumpManager {
    public func addStateObserver(_ observer: StateObserver, queue: DispatchQueue) {
        stateObservers.insert(observer, queue: queue)
    }

    public func removeStateObserver(_ observer: StateObserver) {
        stateObservers.removeElement(observer)
    }
    
    func notifyStateDidChange() {
        DispatchQueue.main.async {
            self.stateObservers.forEach { (observer) in
                observer.stateDidUpdate(self.state, self.oldState)
            }
            
            self.pumpDelegate.notify { (delegate) in
                delegate?.pumpManagerDidUpdateState(self)
            }
            
            self.oldState = DanaKitPumpManagerState(rawValue: self.state.rawValue)
        }
    }
    
    public func addScanDeviceObserver(_ observer: StateObserver, queue: DispatchQueue) {
        scanDeviceObservers.insert(observer, queue: queue)
    }

    public func removeScanDeviceObserver(_ observer: StateObserver) {
        scanDeviceObservers.removeElement(observer)
    }
    
    func notifyScanDeviceDidChange(_ device: DanaPumpScan) {
        DispatchQueue.main.async {
            self.scanDeviceObservers.forEach { (observer) in
                observer.deviceScanDidUpdate(device)
            }
        }
    }
}
