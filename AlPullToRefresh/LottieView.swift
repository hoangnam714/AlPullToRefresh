//
//  LottieView.swift
//  AlPullToRefresh
//
//  Created by admin on 13/11/2023.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    let name: String
    let loopMode: LottieLoopMode
    let animationView: LottieAnimationView
    @Binding var isPlayAnimation: Bool
    
    init(name: String, loopMode: LottieLoopMode, isPlayAnimation: Binding<Bool> = .constant(true)) {
        self.name = name
        self.loopMode = loopMode
        self.animationView = LottieAnimationView(name: name)
        self._isPlayAnimation = isPlayAnimation
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        animationView.loopMode = loopMode
        animationView.play()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPlayAnimation {
            animationView.play()
        } else {
            animationView.pause()
        }
    }
}
