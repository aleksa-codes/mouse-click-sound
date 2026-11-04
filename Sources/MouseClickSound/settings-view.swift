import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    static let windowSize = NSSize(width: 420, height: 360)
    @ObservedObject var model: AppModel
    @State private var showsDetails = false

    private var status: String {
        if !model.permissionGranted { return "Input Monitoring needed" }
        if !model.enabled { return "Sounds paused" }
        return model.monitoring ? "Listening for left clicks" : "Monitoring unavailable"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

                DisclosureGroup("Permission & app details", isExpanded: $showsDetails) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !model.permissionGranted {
                            Text("Allow Input Monitoring to play sounds outside this app. After enabling it, quit and reopen if macOS asks.")
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Button("Allow access…") { model.requestPermission() }
                                Button("System Settings…") { model.openPrivacySettings() }
                            }
                            Text("Already enabled but blocked? Remove the old permission entry and add this copy of the app.")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack {
                            Label(model.permissionGranted ? "Access granted" : "Access needed", systemImage: model.permissionGranted ? "checkmark.shield" : "lock")
                            Spacer()
                            Button("Check again") { model.refreshMonitoring() }
                        }
                        Text(model.appPath)
                            .font(.caption).textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Show app in Finder") { model.revealApp() }
                        Text("Only left-button events are observed. Nothing is recorded or sent anywhere.")
                            .font(.caption).fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(.secondary)
                    .controlSize(.small)
                    .padding(.top, 10)
                }
                .font(.callout)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
        .onChange(of: model.permissionGranted, initial: true) {
            if !model.permissionGranted { showsDetails = true }
        }
        .alert("Mouse Click Sound", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
