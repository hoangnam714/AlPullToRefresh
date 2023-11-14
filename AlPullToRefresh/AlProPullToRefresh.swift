//
//  AlProPullToRefresh.swift
//  AlPullToRefresh
//
//  Created by admin on 13/11/2023.
//

import Foundation
import SwiftUI

struct AlProPullToRefresh: View {
    @State var refresh = RefreshModel(started: false, released: false)
    
    @State var dumpDatas: [Int] = Array(1...10)
    var body: some View {
        ScrollView (.vertical, showsIndicators: true) {
            ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                GeometryReader { proxy -> AnyView in
                    DispatchQueue.main.async {
                        if refresh.startOffset == 0 {
                            refresh.startOffset = proxy.frame(in: .global).minY
                        }
                        refresh.offSet = proxy.frame(in: .global).minY
                        refresh.proggress = refresh.proggress < 0 ? 0 : refresh.proggress
                        refresh.proggress = refresh.proggress > 1 ? 1 : refresh.proggress
                        refresh.proggress = (refresh.offSet-refresh.startOffset)/90
                        print(refresh.proggress)
                        
//                        print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
//                        print("start offset: \(refresh.startOffset)")
//                        print("offset :\(refresh.offSet)")
                        if refresh.offSet - refresh.startOffset > 90 && !refresh.started {
                            refresh.started = true
                        }
                        if refresh.startOffset == refresh.offSet && refresh.started && !refresh.released {
                            withAnimation(.linear) { refresh.released = true }
                            updateData()
                        }
                        if refresh.startOffset == refresh.offSet && refresh.started && refresh.released && refresh.invailid {
                            refresh.invailid = false
                            updateData()
                        }
                    }
                    return AnyView(Color.black.frame(width: 0, height: 0))
                }
                .frame(width: 0, height: 0)
                if refresh.started && refresh.released {
                    LottieView(name: "Loading", loopMode: .loop)
                        .frame(height: 100)
                        .offset(y: -100)

                } else {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .rotationEffect(.init(degrees: refresh.started ? 180 : 0))
                        .offset(y: -25)
                        .animation(.easeIn, value: refresh.started)
                }
                VStack {
                    ForEach(dumpDatas, id: \.self) { index in
                        Text("Item at index: \(index)")
                            .frame(height: 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.06).ignoresSafeArea())
            }
            .offset(y: refresh.released ? 100 : 0 )
        }
        .clipped()
    }
    
    func updateData(){
        print("update data")
        DispatchQueue.main.asyncAfter(deadline: .now()+1){
            withAnimation(.linear) {
//                print("=====================================")
//                print("start offset: \(refresh.startOffset)")
//                print("offset :\(refresh.offSet)")
                if refresh.startOffset + 100 == refresh.offSet {
                    dumpDatas.append(dumpDatas.last!+1)
                    refresh.released = false
                    refresh.started = false
                    refresh.proggress = 0
                } else {
                    refresh.invailid = true
                }
            }
        }
    }
}

#Preview {
    AlProPullToRefresh()
}

struct RefreshModel{
    var startOffset: CGFloat = 0
    var offSet: CGFloat = 0
    var started: Bool
    var released: Bool
    var invailid: Bool = false
    var proggress: CGFloat = 0
}
