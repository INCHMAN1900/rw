//
//  SettingView.swift
//  rw
//
//  Created by Asia Fu on 2024/10/22.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct SettingView: View {
    @Default(.launchAtLogin) var launchAtLogin: Bool
    @Default(.includes) var includes: [URL]
    @Default(.excludes) var excludes: [URL]

    var body: some View {
        VStack {
            Form {
                Section(content: {
                    Toggle(isOn: $launchAtLogin, label: {
                        Text("Launch at Login")
                    })
                }, header: {
                    Text("System")
                        .padding(.horizontal, -8)
                })
                DirectorySection(label: "Includes", directories: $includes)
                Section {
                    Text("If you don't add any folders here, the root path will be monitored.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                }
                DirectorySection(label: "Excludes", directories: $excludes)
            }
            .formStyle(.grouped)
            Spacer()
            HStack {
                Text("Made by INCHMAN1900")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 400, height: 600)
        .onChange(of: launchAtLogin, {
            LaunchAtLogin.isEnabled = launchAtLogin
        })
        .onChange(of: includes, {
            RWState.global.includes = includes
        })
        .onChange(of: excludes, {
            RWState.global.excludes = excludes
        })
    }
}

struct DirectorySection: View {
    var label: String
    @Binding var directories: [URL]
    
    @State private var selected = Set<URL>()
    
    var body: some View {
        Section(content: {
            List(selection: $selected) {
                ForEach($directories, id: \.self, content: { directory in
                    HStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: directory.wrappedValue.path))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text(directory.wrappedValue.lastPathComponent)
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
                    .id(directory.wrappedValue)
                })
            }
            .modifier(EmptyModifier(active: directories.count == 0, tooltip: "Click + to add folders."))
            .onDeleteCommand {
                removeSelected()
            }
        }, header: {
            HStack(spacing: 0) {
                Text(label)
                Spacer()
                AccessoryButton(icon: "plus", iconSize: 10, onClick: {
                    addDirectories()
                })
                AccessoryButton(icon: "minus", iconSize: 12, disabled: selected.isEmpty, onClick: {
                    removeSelected()
                })
            }
            .padding(.horizontal, -8)
        })
    }
    
    func removeSelected() {
        directories.removeAll(where: { selected.contains($0) })
        selected.removeAll()
    }
    
    private func addDirectories() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin(completionHandler: { response in
            guard response == .OK else { return }
            for url in panel.urls {
                if directories.contains(url) {
                    continue
                }
                if FileManager.default.directoryExists(atPath: url.path) {
                    directories.append(url)
                }
            }
        })
    }
}

struct EmptyModifier: ViewModifier {
    var active: Bool
    var tooltip: String
    
    func body(content: Content) -> some View {
        if active {
            HStack {
                Spacer()
                Text(tooltip)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 16)
        } else {
            content
        }
    }
}
