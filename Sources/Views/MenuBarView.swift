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
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("iJustLikeOrdinary")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Apple Silicon Battery Saver")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Battery & Wattage Pill
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: battery.isCharging ? "bolt.batteryblock.fill" : "battery.75")
                            .foregroundColor(battery.isCharging ? .green : (battery.percentage < 20 ? .red : .primary))
                        Text("\(battery.percentage)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    if battery.currentWatts > 0 {
                        Text(String(format: "%.1f W", battery.currentWatts))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(6)
            }

            Divider()

            // Master Toggle
            Toggle(isOn: $profileManager.isOrdinaryActive) {
                HStack {
                    Image(systemName: profileManager.isOrdinaryActive ? "leaf.fill" : "leaf")
                        .foregroundColor(profileManager.isOrdinaryActive ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ordinary Mode")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(profileManager.isOrdinaryActive ? "Limiting SoC power" : "Unrestricted M1 Max")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(.vertical, 2)

            Divider()

            // Profiles Section
            VStack(alignment: .leading, spacing: 6) {
                Text("PROFILES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                ForEach(profileManager.profiles) { profile in
                    Button(action: {
                        profileManager.selectProfile(profile)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: profile.icon)
                                .frame(width: 16)
                                .foregroundColor(isSelected(profile) ? .green : .secondary)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(profile.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(profile.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isSelected(profile) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(isSelected(profile) ? Color.accentColor.opacity(0.12) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Hardware Live Indicators & Overrides
            VStack(alignment: .leading, spacing: 6) {
                Text("CURRENT HARDWARE STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                // Refresh Rate
                HStack {
                    Label("Display Rate", systemImage: "display")
                        .font(.caption)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(profileManager.displayService.availableRefreshRates, id: \.self) { rate in
                            let isCurrent = abs(profileManager.displayService.currentRefreshRate - rate) < 1.0
                            Button(action: {
                                profileManager.displayService.setRefreshRate(rate)
                            }) {
                                Text("\(Int(round(rate)))Hz")
                                    .font(.system(size: 10, weight: isCurrent ? .bold : .regular))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isCurrent ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundColor(isCurrent ? .white : .primary)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Processor Low Power Mode
                HStack {
                    Label("Processor", systemImage: "cpu")
                        .font(.caption)
                    Spacer()
                    Text(profileManager.powerModeService.isLowPowerModeActive ? "Low Power (Throttled)" : "Full Speed")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(profileManager.powerModeService.isLowPowerModeActive ? .green : .secondary)
                }

                // Keyboard Backlight
                HStack {
                    Label("Keyboard Backlight", systemImage: "keyboard")
                        .font(.caption)
                    Spacer()
                    Text(profileManager.keyboardService.getBrightness() > 0.01 ? "On" : "Off (Saving Power)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(profileManager.keyboardService.getBrightness() > 0.01 ? .secondary : .green)
                }
            }

            Divider()

            // One-Click Authorization Banner
            if !powerMode.isAuthorized {
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
                            Text(showingSudoHelper ? "Tutup Terminal" : "Via Terminal")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if showingSudoHelper {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Atau jalankan di Terminal:")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
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
                        .padding(.top, 2)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

                Divider()
            }

            // Footer
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
        .frame(width: 310)
    }

    private func isSelected(_ profile: BatteryProfile) -> Bool {
        profileManager.isOrdinaryActive && profileManager.activeProfile.id == profile.id
    }
}

