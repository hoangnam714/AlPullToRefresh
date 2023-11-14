//
//  AlIslandPullToRefresh.swift
//  AlPullToRefresh
//
//  Created by admin on 14/11/2023.
//

import Foundation
import SwiftUI
import Lottie

private let minimumSpaceRefresh: CGFloat = 100

struct AlIslandPullToRefresh<Content: View>: View {
    var name: String
    var content: Content
    var showIndicator: Bool
    var onRefresh: () async -> ()
    
    @State var isPlayAnimation = true
    
    @StateObject var scrollDelegate: ScrollViewModel = .init()
    
    let id = UUID().uuidString
    
    init( name: String ,showIndicator: Bool, isPlayAnimation: Bool = true, onRefresh: @escaping ()async->(), content: @escaping ()-> Content) {
        self.name = name
        self.content = content()
        self.showIndicator = showIndicator
        self.onRefresh = onRefresh
        self.isPlayAnimation = isPlayAnimation
    }
    
    var body: some View {
        ScrollView( .vertical, showsIndicators: showIndicator){
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: scrollDelegate.progress*minimumSpaceRefresh)
                content
            }
            .offset(coordinateSpace: id) { offSet in
                scrollDelegate.contentOffset = offSet
                if !scrollDelegate.isEligible {
                    var progress = offSet / minimumSpaceRefresh
                    progress = (progress < 0 ? 0 : progress)
                    progress = (progress > 1 ? 1 : progress)
                    scrollDelegate.scrollOffset = offSet
                    scrollDelegate.progress = progress
                }
                if scrollDelegate.isEligible && !scrollDelegate.isRefreshsing {
                    scrollDelegate.isRefreshsing = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
        .overlay(alignment: .top, content: {
            ZStack{
                Capsule()
                    .fill(.black)
            }
            .frame(width: 126 ,height: 37)
            .offset(y: 11)
            .frame(maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .top, content: {
                Canvas{ context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .black))
                    context.addFilter(.blur(radius: 10))
                    context.drawLayer { ctx in
                        for index in [1,2] {
                            if let resloveView = context.resolveSymbol(id: index){
                                ctx.draw(resloveView, at: CGPoint(x: size.width/2, y: 30))
                            }
                        }
                    }
                } symbols: {
                    CanvasSymboy()
                        .tag(1)
                    CanvasSymboy(isCircle: true)
                        .tag(2)
                }
                .allowsHitTesting(false)
            })
            .overlay(alignment: .top, content: {
                RefreshView
                    .offset(y: 11)
            })
            .ignoresSafeArea()
        })
        .coordinateSpace(name: id)
        .onAppear(perform: scrollDelegate.addGesture)
        .onDisappear(perform: scrollDelegate.removeGesture)
        .onChange(of: scrollDelegate.isRefreshsing) { newValue in
            if newValue {
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await onRefresh()
                    withAnimation(.easeInOut(duration: 0.25)){
                        self.scrollDelegate.progress = 0
                        scrollDelegate.isEligible = false
                        scrollDelegate.isRefreshsing = false
                        scrollDelegate.scrollOffset = 0
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    func CanvasSymboy(isCircle: Bool = false)-> some View {
        if isCircle {
            let centerOffset = scrollDelegate.isEligible ? (scrollDelegate.contentOffset > 95 ? scrollDelegate.contentOffset : 95): scrollDelegate.scrollOffset
            let offset = scrollDelegate.scrollOffset > 0 ? centerOffset : 0
            let scalling = ((scrollDelegate.progress/1)*0.21)
             Circle()
                .fill(.black)
                .frame(width: 47, height: 47)
                .scaleEffect(0.79 + scalling, anchor: .center)
                .offset(y: offset)
        } else {
            Capsule()
                .fill(.black)
                .frame(width: 126, height: 37)
        }
    }
    
    @ViewBuilder
    var RefreshView: some View {
        let centerOffset = scrollDelegate.isEligible ? (scrollDelegate.contentOffset > 95 ? scrollDelegate.contentOffset :95): scrollDelegate.scrollOffset
        let offset = scrollDelegate.scrollOffset > 0 ? centerOffset : 0
        ZStack {
            Image(systemName: "arrow.down")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .rotationEffect(.degrees(scrollDelegate.progress*180))
                .opacity(scrollDelegate.isEligible ? 0 : 1 )
            ProgressView()
                .tint(.white)
                .frame(width: 35, height: 38)
                .opacity(scrollDelegate.isEligible ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.25), value: scrollDelegate.isEligible)
        .opacity(scrollDelegate.progress)
        .offset(y: offset)
    }
}


#Preview {
    AlIslandPullToRefresh(name: "Loading", showIndicator: true) {
        
    } content: {
        VStack {
            Rectangle()
                .fill(Color.red)
                .frame(height: 200)
            Rectangle()
                .fill(Color.blue)
                .frame(height: 200)
        }
    }
}

