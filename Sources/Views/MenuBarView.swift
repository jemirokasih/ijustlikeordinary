import SwiftUI
import AppKit

public struct MenuBarView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var battery = BatteryMonitorService.shared
    @ObservedObject var powerMode = PowerModeService.shared
    @State private var showingSudoHelper = false
    @State private var copiedSudoCommand = false

    public init() {}

    private var selectedPresetBinding: Binding<String> {
        Binding(
            get: { profileManager.selectedPresetName ?? "Custom" },
            set: { newName in
                if newName == "Custom" {
                    profileManager.selectedPresetName = "Custom"
                } else if let preset = profileManager.profiles.first(where: { $0.name == newName }) {
                    profileManager.loadPreset(preset)
                }
            }
        )
    }

    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Battery & Power Status Card
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    // Source & Wattage
                    HStack(spacing: 6) {
                        Text(battery.isOnACPower ? "AC Power" : "On Battery")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(battery.isOnACPower ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundColor(battery.isOnACPower ? .green : .blue)
                            .cornerRadius(4)

                        if battery.currentWatts > 0 {
                            Text(String(format: "%.1f W", battery.currentWatts))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }

                    Spacer()

                    // Battery Percentage
                    Text("\(battery.percentage)%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }

                // Time Estimate & Power Saved
                HStack {
                    Text(battery.formattedEstimate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    if !battery.isOnACPower && profileManager.isOrdinaryActive && battery.estimatedSavingsPercent > 0 {
                        Text("~\(battery.estimatedSavingsPercent)% Saved")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }

                // Battery Level Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(battery.isCharging ? Color.green : (battery.percentage < 20 ? Color.red : Color.accentColor))
                            .frame(width: geo.size.width * CGFloat(Double(battery.percentage) / 100.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(8)

            // MARK: - Master Toggle
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ordinary Mode")
                        .font(.system(size: 13, weight: .bold))
                    Text(profileManager.isOrdinaryActive ? "Battery optimization active" : "Default performance (Unrestricted)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $profileManager.isOrdinaryActive)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 2)

            Divider()

            // MARK: - Optimization Controls (When ON)
            if profileManager.isOrdinaryActive {
                VStack(spacing: 12) {
                    // Optional Preset Dropdown
                    HStack {
                        Text("Preset")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Picker("", selection: selectedPresetBinding) {
                            Text("Custom").tag("Custom")
                            Divider()
                            ForEach(profileManager.profiles) { preset in
                                Text(preset.name).tag(preset.name)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }

                    // 1. Processor
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Processor")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text(profileManager.processorLevelName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(profileManager.processorLevel <= 1 ? .green : .primary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(profileManager.processorLevel) },
                                set: {
                                    profileManager.selectedPresetName = "Custom"
                                    profileManager.processorLevel = Int(round($0))
                                }
                            ),
                            in: 0...3,
                            step: 1
                        )

                        HStack {
                            Text("Super Low").font(.system(size: 8)).foregroundColor(.secondary)
                            Spacer()
                            Text("Low").font(.system(size: 8)).foregroundColor(.secondary)
                            Spacer()
                            Text("Medium").font(.system(size: 8)).foregroundColor(.secondary)
                            Spacer()
                            Text("Normal").font(.system(size: 8)).foregroundColor(.secondary)
                        }
                    }

                    // 2. Refresh Rate
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Refresh Rate")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(round(profileManager.targetRefreshRate))) Hz")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(profileManager.targetRefreshRate <= 60 ? .green : .primary)
                        }

                        HStack(spacing: 4) {
                            ForEach([48.0, 50.0, 60.0, 120.0], id: \.self) { rate in
                                let isSelected = abs(profileManager.targetRefreshRate - rate) < 1.0
                                Button(action: {
                                    profileManager.selectedPresetName = "Custom"
                                    profileManager.targetRefreshRate = rate
                                }) {
                                    Text("\(Int(round(rate)))Hz")
                                        .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 3. Display Brightness
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Display Brightness")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(round(profileManager.displayBrightness * 100)))%")
                                .font(.system(size: 10, weight: .bold))
                        }

                        Slider(
                            value: Binding(
                                get: { profileManager.displayBrightness },
                                set: {
                                    profileManager.selectedPresetName = "Custom"
                                    profileManager.displayBrightness = $0
                                }
                            ),
                            in: 0.05...1.0
                        )
                    }

                    // 4. Keyboard Backlight
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Keyboard Backlight")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text(profileManager.keyboardBrightness < 0.01 ? "Off" : "\(Int(round(profileManager.keyboardBrightness * 100)))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(profileManager.keyboardBrightness < 0.01 ? .green : .primary)
                        }

                        Slider(
                            value: Binding(
                                get: { profileManager.keyboardBrightness },
                                set: {
                                    profileManager.selectedPresetName = "Custom"
                                    profileManager.keyboardBrightness = $0
                                }
                            ),
                            in: 0.0...1.0
                        )
                    }
                }
            } else {
                // OFF State Callout
                VStack(spacing: 4) {
                    Text("Default Performance Active")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Turn on Ordinary Mode to configure processor limits, refresh rate, and backlight.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(6)
            }

            // MARK: - Low Power Mode Authorization Banner
            if !powerMode.isAuthorized {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Low Power Mode Permission")
                            .font(.system(size: 11, weight: .bold))
                        Text("Grant one-time permission for instant processor switching.")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Button("Grant Permission (1-Click)") {
                            _ = powerMode.requestOneTimeAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Spacer()

                        Button(showingSudoHelper ? "Hide" : "Terminal") {
                            showingSudoHelper.toggle()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    }

                    if showingSudoHelper {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(PowerModeService.sudoersCommand)
                                .font(.system(size: 8, design: .monospaced))
                                .padding(4)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(4)

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(PowerModeService.sudoersCommand, forType: .string)
                                copiedSudoCommand = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedSudoCommand = false
                                }
                            }) {
                                Text(copiedSudoCommand ? "Copied!" : "Copy Command")
                                    .font(.system(size: 9))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }

            Divider()

            // MARK: - Footer
            HStack {
                Text("M1 Max • Liquid Retina XDR")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit") {
                    profileManager.isOrdinaryActive = false
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
        .padding(12)
        .frame(width: 300)
    }
}
