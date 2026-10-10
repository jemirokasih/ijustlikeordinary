import SwiftUI
import AppKit

public struct MenuBarView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var battery = BatteryMonitorService.shared
    @ObservedObject var powerMode = PowerModeService.shared
    @State private var showingSudoHelper = false
    @State private var copiedSudoCommand = false

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Battery & Calculation Header
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(battery.isOnACPower ? "🔌 AC Charger" : "🔋 Baterai")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(battery.isOnACPower ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundColor(battery.isOnACPower ? .green : .blue)
                                .cornerRadius(4)

                            if battery.currentWatts > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 9))
                                    Text(String(format: "%.1f W", battery.currentWatts))
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            }
                        }

                        Text(battery.formattedEstimate)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Large Battery Percentage Display
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(spacing: 3) {
                            Text("\(battery.percentage)%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Image(systemName: battery.isCharging ? "battery.100.bolt" : (battery.percentage < 20 ? "battery.25" : "battery.75"))
                                .font(.system(size: 14))
                                .foregroundColor(battery.isCharging ? .green : (battery.percentage < 20 ? .red : .primary))
                        }

                        if !battery.isOnACPower && profileManager.isOrdinaryActive && battery.estimatedSavingsPercent > 0 {
                            Text("Hemat ~\(battery.estimatedSavingsPercent)%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }

                // Battery Level Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(battery.isCharging ? Color.green : (battery.percentage < 20 ? Color.red : Color.accentColor))
                            .frame(width: geo.size.width * CGFloat(Double(battery.percentage) / 100.0), height: 5)
                    }
                }
                .frame(height: 5)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            // MARK: - Master Slide ON / OFF
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ordinary Mode")
                        .font(.system(size: 13, weight: .bold))
                    Text(profileManager.isOrdinaryActive ? "Penghematan daya aktif" : "Spek default M1 Max (Normal)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $profileManager.isOrdinaryActive)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 4)

            Divider()

            // MARK: - Options (When ON)
            if profileManager.isOrdinaryActive {
                VStack(spacing: 12) {
                    // Presets Loader Chips
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("LOAD PRESET CONFIG")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            if let selected = profileManager.selectedPresetName {
                                Text(selected)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(profileManager.profiles) { preset in
                                    let isCur = profileManager.selectedPresetName == preset.name
                                    Button(action: {
                                        profileManager.loadPreset(preset)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: preset.icon)
                                                .font(.system(size: 9))
                                            Text(preset.name)
                                                .font(.system(size: 10, weight: isCur ? .bold : .regular))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(isCur ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(isCur ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Divider()

                    // SLIDER 1: Processor
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Processor", systemImage: "cpu")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text(profileManager.processorLevelName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(profileManager.processorLevel <= 1 ? .green : .primary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(profileManager.processorLevel) },
                                set: { profileManager.processorLevel = Int(round($0)) }
                            ),
                            in: 0...3,
                            step: 1
                        )
                        .accentColor(profileManager.processorLevel <= 1 ? .green : .accentColor)

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

                    // SLIDER 2: Refresh Rate
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Refresh Rate", systemImage: "display")
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
                                    profileManager.targetRefreshRate = rate
                                }) {
                                    Text("\(Int(round(rate)))Hz")
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // SLIDER 3: Display Brightness
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Display Brightness", systemImage: "sun.max")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(round(profileManager.displayBrightness * 100)))%")
                                .font(.system(size: 10, weight: .bold))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "sun.min")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Slider(
                                value: $profileManager.displayBrightness,
                                in: 0.05...1.0
                            )

                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    // SLIDER 4: Keyboard Backlight
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Keyboard Backlight", systemImage: "keyboard")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text(profileManager.keyboardBrightness < 0.01 ? "Mati (0%)" : "\(Int(round(profileManager.keyboardBrightness * 100)))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(profileManager.keyboardBrightness < 0.01 ? .green : .primary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Slider(
                                value: $profileManager.keyboardBrightness,
                                in: 0.0...1.0
                            )

                            Image(systemName: "keyboard.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // OFF State Callout
                VStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Hardware Berjalan Normal")
                        .font(.system(size: 12, weight: .bold))
                    Text("Aktifkan Ordinary Mode untuk membatasi frekuensi M1 Max, refresh rate, kecerahan layar, dan backlight.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
            }

            // MARK: - 1-Click Authorization Banner (if needed)
            if !powerMode.isAuthorized {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Izin Low Power Mode")
                                .font(.system(size: 11, weight: .bold))
                            Text("Klik untuk otorisasi Touch ID / Password 1x saja.")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Button(action: {
                            _ = powerMode.requestOneTimeAuthorization()
                        }) {
                            HStack {
                                Image(systemName: "touchid")
                                Text("Beri Izin (1-Klik)")
                            }
                            .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Spacer()

                        Button(action: {
                            showingSudoHelper.toggle()
                        }) {
                            Text(showingSudoHelper ? "Tutup" : "Terminal")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
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
                                HStack {
                                    Image(systemName: copiedSudoCommand ? "checkmark" : "doc.on.doc")
                                    Text(copiedSudoCommand ? "Tersalin!" : "Salin Perintah")
                                }
                                .font(.system(size: 9))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
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
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
