//
//  WelcomeView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI
/*
 
 - ZStack stacks views on top of each other, back to front: the colour is behind and the text is in front.
 - .ignoresSafeArea() lets the colour fill the whole screen, including behind the notch and the home bar.
 */

struct WelcomeView: View {
    @EnvironmentObject private var presenter: Presenter
    
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Welcome")
                    .font(.largeTitle.bold())
                
                Button("Continue") {
                    gotoSignup()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
        }
    }
    
    func gotoSignup(){
        print("signup", presenter.fullScreenStack)
        presenter.present(.signup)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(Presenter())
}
