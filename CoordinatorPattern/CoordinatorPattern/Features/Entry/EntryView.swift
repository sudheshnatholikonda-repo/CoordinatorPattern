//
//  EntryView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 07/10/26.
//

import SwiftUI

struct EntryView: View {
    @EnvironmentObject private var presenter: Presenter
    
    var body: some View {
        VStack(spacing: 20) {
                    Text("Entry")
                        .font(.largeTitle.bold())

                    // dismiss(): closes the sheet -> back to map + Home buttons
                    Button("Close") {
                        presenter.dismiss()
                    }
                    .buttonStyle(.bordered)
                }
    }
}

#Preview {
    EntryView()
        .environmentObject(Presenter())
}
