import SwiftUI
import UIKit

/// Stato batteria persistente — non si resetta quando la taskbar viene nascosta.
@MainActor
final class BatteryService: ObservableObject {
    @Published private(set) var level: Float
    @Published private(set) var isCharging: Bool

    private var useMock = false
    private var mockLevel: Float = 0.8
    private var mockCharging = false
    private var timer: Timer?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let device = UIDevice.current
        let raw = device.batteryLevel
        level = raw < 0 ? 0.8 : raw
        isCharging = Self.isDeviceCharging(device.batteryState)

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshFromDevice() }
        }
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshFromDevice() }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshFromDevice() }
        }
    }

    func configureMock(useMock: Bool, level: Float, charging: Bool) {
        self.useMock = useMock
        mockLevel = level
        mockCharging = charging
        if useMock {
            self.level = level
            isCharging = charging
        } else {
            refreshFromDevice()
        }
    }

    private func refreshFromDevice() {
        guard !useMock else { return }
        let raw = UIDevice.current.batteryLevel
        if raw >= 0 { level = raw }
        isCharging = Self.isDeviceCharging(UIDevice.current.batteryState)
    }

    private static func isDeviceCharging(_ state: UIDevice.BatteryState) -> Bool {
        state == .charging || state == .full
    }
}
