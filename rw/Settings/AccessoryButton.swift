//
//  AccessoryButton.swift
//  rw
//
//  Created by Asia Fu on 2024/10/23.
//

import SwiftUI

struct AccessoryButton: View {
    var icon: String
    var iconSize: CGFloat? = 14
    var size: CGFloat? = 22
    var disabled = false
    var onClick: (() -> Void)? = nil
    
    @State private var background = Color.clear
    @State private var opacity = 0.8
    @State private var timer: Timer?
    
    var body: some View {
        
        let view = VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: size, height: size)
        .opacity(disabled ? 0.4 : opacity)
        .background(background)
        .cornerRadius(5)
        .clipped()
        .onHover(perform: { hovering in
            if !disabled && hovering {
                background = Color(nsColor: .textColor).opacity(0.1)
            } else {
                background = .clear
            }
        })
        
        if let onClick {
            view.onTapGesture {
                if disabled { return }
                opacity = 1.0
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
                    self.opacity = 0.8
                })
                onClick()
            }
        } else {
            view
        }
    }
}
