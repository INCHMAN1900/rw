//
//  RWView.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import SwiftUI
import Foundation

extension Int64 {
    func toDateString() -> String {
        Date(timeIntervalSince1970: Double(self)).formattedDateString
    }
}

extension Int {
    func readableSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB, .usePB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}

extension Date {
    var timestamp: Int64 { Int64(timeIntervalSince1970) }
    
    var formattedDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: self)
    }
}

struct RWView: View {
    @StateObject private var state = RWState.global
    
    @State private var selected = Set<RWFileModel.Entity.ID>()
    @State private var rows = [RWFileModel.Entity]()
    @State private var total = 0
    @State private var pageNumber = 1
    @State private var pageSize = 300
    
    @State private var searchKeyword = ""
    @State private var searchTimer: Timer? = nil
    
    @FocusState private var focused
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Keyword")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField(text: $searchKeyword, label: {  })
                    .focused($focused)
                    .onSubmit {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                    .onExitCommand {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                Spacer()
                Button(action: {
                    state.isRunning.toggle()
                }, label: {
                    Text(state.isRunning ? "Running" : "Paused")
                        .font(.system(size: 12))
                        .opacity(0.9)
                        .padding(.trailing, 2)
                    Circle()
                        .fill(state.isRunning ? Color(.systemGreen) : Color(.systemRed))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(.shadowColor).opacity(0.2), radius: 2)
                })
                .padding(.leading, 6)
                SettingsLink(label: {
                    Image(systemName: "gear")
                })
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            
            Divider()
            Table(rows, selection: $selected, columns: {
                TableColumn("Path", content: { row in
                    HStack {
                        Text(row.path)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .contextMenu(menuItems: {
                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: row.path)])
                        }, label: {
                            Text("Reveal in Finder")
                        })
                        .disabled(!FileManager.default.fileExists(atPath: row.path))
                        Divider()
                        Button(action: {
                            searchKeyword = URL(fileURLWithPath: row.path).deletingLastPathComponent().path
                        }, label: {
                            Text("Show log in this directory")
                        })
                    })
                })
                .width(min: 300, ideal: 600)
                TableColumn("Log Date", content: { row in
                    Text(row.createdAt.toDateString())
                })
                .width(min: 60, ideal: 150)
                TableColumn("Log Type", content: { row in
                    Text(row.eventType.label)
                })
                .width(min: 60, ideal: 120)
                TableColumn("File Creation Date", content: { row in
                    HStack {
                        if row.creationDate < 0 {
                            Text("-")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(row.creationDate.toDateString())
                        }
                    }
                })
                .width(ideal: 150)
                TableColumn("File Size", content: { row in
                    HStack {
                        if row.creationDate <= 0 {
                            Text("-")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(row.size.readableSize())
                        }
                    }
                })
                .width(ideal: 90)
            })
            HStack {
                Button(action: {
                    pageNumber = max(pageNumber - 1, 1)
                    refresh()
                }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(pageNumber == 1)
                
                Text("Page \(pageNumber)")
                
                Button(action: {
                    pageNumber = pageNumber + 1
                    refresh()
                }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(pageNumber == total / pageSize + 1)
                
                Text("\((pageNumber - 1) * pageSize + 1)-\((pageNumber - 1) * pageSize + min(pageSize, rows.count)) in \(total.description) records")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Button(action: {
                    refresh()
                }) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                Spacer()
                
            }
            .padding()
        }
        .onAppear {
            refresh()
        }
        .onChange(of: searchKeyword, {
            searchTimer?.invalidate()
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { _ in
                self.refresh()
            })
        })
    }
    
    func refresh() {
        let result = RWFileModel.select(searchKeyword, pageNumber: pageNumber, pageSize: pageSize)
        total = result.0
        rows = result.1
    }
}

#Preview {
    RWView()
}
