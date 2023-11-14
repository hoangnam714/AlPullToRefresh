//
//  AlPullToRefresh.swift
//  AlPullToRefresh
//
//  Created by admin on 13/11/2023.
//

import Foundation
import SwiftUI
import Lottie

private let minimumSpaceRefresh: CGFloat = 100

struct AlPullToRefreshView<Content: View>: View {
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
                ResizeLottieView(fileName: name, isPlay: $scrollDelegate.isRefreshsing)
                    .scaleEffect(scrollDelegate.isEligible ? 1 : 0.001)
                    .animation(.easeInOut(duration: 0.2), value: scrollDelegate.isEligible)
                    .overlay(content: {
                        VStack(spacing: 12, content: {
                            Image(systemName: "arrow.down")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.primary, in: Circle())
                            Text("Pull to refresh")
                        })
                        .opacity(scrollDelegate.isEligible ? 0 : 1)
                        .animation(.easeInOut(duration: 0.25), value: scrollDelegate.isEligible)
                    })
                    .frame(height: minimumSpaceRefresh*scrollDelegate.progress)
                    .opacity(scrollDelegate.progress)
                    .offset(y: scrollDelegate.isEligible ? -(scrollDelegate.contentOffset < 0 ? 0 : scrollDelegate.contentOffset) : -(scrollDelegate.scrollOffset < 0 ? 0 : scrollDelegate.scrollOffset ))
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
        .coordinateSpace(name: id)
        .onAppear(perform: scrollDelegate.addGesture)
        .onDisappear(perform: scrollDelegate.removeGesture)
        .onChange(of: scrollDelegate.isRefreshsing) { newValue in
            if newValue {
                Task {
                    await onRefresh()
                    withAnimation(.easeInOut(duration: 0.25)){
                        self.scrollDelegate.progress = 0
                        scrollDelegate.isEligible = false
                        scrollDelegate.isRefreshsing = false
                        scrollDelegate.scrollOffset = 0
                        //                        scrollDelegate.contentOffset = 0
                    }
                }
            }
        }
        .clipped()
        
    }
}

struct ResizeLottieView: UIViewRepresentable {
    let lottieView: LottieAnimationView
    var fileName: String
    @Binding var isPlay: Bool
    
    init(fileName: String, isPlay: Binding<Bool> = .constant(true)) {
        self.fileName = fileName
        self._isPlay = isPlay
        self.lottieView = LottieAnimationView(name: fileName)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        addLottieView(view: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if !isPlay {
            lottieView.play()
        } else {
            lottieView.pause()
        }
    }
    
    func addLottieView(view to: UIView){
        lottieView.backgroundColor = .clear
        lottieView.loopMode = .loop
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            lottieView.widthAnchor.constraint(equalTo: to.widthAnchor),
            lottieView.heightAnchor.constraint(equalTo: to.heightAnchor)
        ]
        to.addSubview(lottieView)
        to.addConstraints(constraints)
    }
    
}

class ScrollViewModel: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    @Published var isEligible: Bool = false
    @Published var isRefreshsing: Bool = false
    @Published var scrollOffset: CGFloat = 0
    @Published var progress: CGFloat = 0
    @Published var contentOffset: CGFloat = 0
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func addGesture(){
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChanger(gesture: )))
        panGesture.delegate = self
        rootController().view.addGestureRecognizer(panGesture)
    }
    
    func removeGesture(){
        rootController().view.gestureRecognizers?.removeAll()
    }
    
    @objc func onGestureChanger(gesture: UIPanGestureRecognizer){
        if gesture.state == .cancelled || gesture.state == .ended {
            if scrollOffset > minimumSpaceRefresh {
                isEligible = true
            } else {
                isEligible = false
            }
        }
    }
    
    func rootController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .init() }
        guard let root = screen.windows.first?.rootViewController else { return .init() }
        return root
    }
}

extension View {
    @ViewBuilder
    func offset(coordinateSpace: String, offSet: @escaping(CGFloat)->()) -> some View {
        
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named(coordinateSpace)).minY
            self
                .preference(key: OffsetKey.self, value: minY)
                .onPreferenceChange(OffsetKey.self, perform: { value in
                    offSet(value)
                    print(value)
                })
        }
        
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

#Preview {
    AlPullToRefreshView(name: "Loading", showIndicator: true) {
        
    } content: {
        Rectangle()
            .fill(Color.red)
            .frame(height: 100)
    }
    
}

