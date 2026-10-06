//
//  SplashView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var presenter: Presenter
    
    var body: some View {
        ZStack {
               Color.black.ignoresSafeArea()
               Text("SPLASH")
                   .font(.largeTitle.bold())
                   .foregroundStyle(.white)
           }//ZStack
        /*
         .task { } runs some work when a SwiftUI view appears. some async work
         onAppear vs .task is designed to work naturally with Swift concurrency
         SwiftUI manages the task's lifetime. If the view disappears, SwiftUI can cancel that task.
         .task can run again if the view is recreated or appears again. It is not automatically “run once for the entire app
         .task is a view modifier. It must be attached to a view.
         */
        
        .task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            presenter.replaceAll(with: .welcome)
        }
        /*
         Task { } creates a new Swift concurrency task manually.
         “Start this async work now.”
         we can use inside view
         */
    }
}

#Preview {
    SplashView()
        .environmentObject(Presenter())
}
