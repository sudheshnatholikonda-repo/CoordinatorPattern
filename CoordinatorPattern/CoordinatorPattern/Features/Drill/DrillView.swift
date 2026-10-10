//
//  DrillView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 07/10/26.
//

import SwiftUI

struct DrillView: View {
    @EnvironmentObject private var presenter: Presenter

    var body: some View {
        VStack(spacing: 20) {
                    Text("Drill")
                        .font(.largeTitle.bold())

                    // dismiss(): closes the sheet -> back to map + Home buttons
                    Button("Close") {
                        presenter.dismiss()
                    }
                    .buttonStyle(.bordered)
                }    }
}

#Preview {
    DrillView()
        .environmentObject(Presenter())

}
