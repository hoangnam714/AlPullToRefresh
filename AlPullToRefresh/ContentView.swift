//
//  ContentView.swift
//  AlPullToRefresh
//
//  Created by admin on 13/11/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
//            AlPullToRefreshView(name: "Loading", showIndicator: true) {
//                try? await Task.sleep(nanoseconds: 3_000_000_000)
//            } content: {
//                Color.red.frame(height: 300)
//            }
            
            AlIslandPullToRefresh(name: "Loading", showIndicator: true) {
                
            } content: {
                Color.red.frame(height: 300)
            }

        }
    }
}

#Preview {
    ContentView()
}
