import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    static let windowWidth: CGFloat = 420
    @ObservedObject var model: AppModel

    private var status: String {
        if !model.permissionGranted { return "Input Monitoring needed" }
        if !model.enabled { return "Sounds paused" }
        return model.monitoring ? "Listening for mouse clicks" : "Monitoring unavailable"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                   let icon = NSImage(contentsOf: url) {
                    Image(nsImage: icon)
                        .resizable().frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mouse Click Sound").font(.headline)
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Toggle("Enable sounds", isOn: $model.enabled)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Volume").foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Slider(value: $model.volume, in: 0...1)
                            .accessibilityLabel("Sound volume")
                            .controlSize(.small)
                        Text(model.volume, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                GridRow {
                    Text("Preview").foregroundStyle(.secondary)
                    ControlGroup {
                        ForEach(Sound.allCases) { sound in
                            Button(sound.title) { model.preview(sound) }
                        }
                    }
                    .controlSize(.small)
                    .help("Preview at the current volume, even while sounds are paused")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Launch at login")
                    Spacer()
                    Toggle("Launch at login", isOn: Binding(
                        get: { model.loginEnabled },
                        set: { model.setLoginEnabled($0) }
                    ))
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                if model.loginNeedsApproval {
                    Button("Approve in Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                        .controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Input Monitoring").font(.callout)
                        Text("Left and right clicks are detected. Nothing is recorded or sent.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: model.permissionGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(model.permissionGranted ? Color.green : Color.orange)
                        Text(model.permissionGranted ? "Allowed" : "Required")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .fixedSize()
                }

                if !model.permissionGranted {
                    Text("Allow access to detect clicks outside this app.")
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Allow access…") { model.requestPermission() }
                        Button("Open System Settings…") { model.openPrivacySettings() }
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .frame(width: Self.windowWidth, alignment: .leading)
        .alert("Mouse Click Sound", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
