//
//  Presenter.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI
import Combine
/*
 Presenter holds what is on screen.
 Views never show screens themselves; they ask the Presenter.

 Now it holds TWO things:
 - fullScreenStack: normal screens, slide in from the right
 - sheet:  ONE bottom sheet shown on top of everything

 - ObservableObject: SwiftUI can watch this class for changes.
 - @MainActor: it drives the UI, so it runs on the main thread.
 - final class (not struct): ONE shared instance that every view talks to.
 */
@MainActor
final class Presenter: ObservableObject {

    /*
     fullScreenStack: the ordered list of screens.
     Index 0 = bottom screen, .last = the screen the user sees.

     - @Published: when the array changes, SwiftUI redraws.
     - private(set): anyone can READ it, only the Presenter can CHANGE it.
     */
 @Published private(set) var fullScreenStack: [Destination] = []
    
    /*
        NEW
        sheet: the destination currently shown as a bottom sheet.
        - nil = no sheet showing.
        - Optional (not an array) to keep it simple: one sheet at a time.
          (The Latest app uses an array + SheetManager to stack many sheets.)
        */
 @Published private(set) var sheet: Destination?

    /*
        CHANGED
        present: screens still just call presenter.present(.signup).
        The Presenter decides HOW to show it using isFullScreen (Sheet Step 1):
        - true  -> push onto fullScreenStack (slides from the right)
        - false -> set as the sheet          (slides up from the bottom)
        */
    
    func present(_ destination: Destination) {
           if destination.isFullScreen {
               fullScreenStack.append(destination)
           } else {
               sheet = destination
           }
       }

    /*
        CHANGED
        dismiss: close whatever is on TOP.
        - A sheet is always above the full screens, so close it first.
        - Otherwise pop the top full screen (same as before).
        */
       func dismiss() {
           if sheet != nil {
               sheet = nil
           } else {
               guard !fullScreenStack.isEmpty else { return }
               fullScreenStack.removeLast()
           }
       }

    /*
     replaceAll: wipe the stack and show only this screen.
     Use it when going back must NOT be possible,
     e.g. Splash -> Welcome (the user should never go back to Splash).
     */
    func replaceAll(with destination: Destination) {
        sheet = nil
        fullScreenStack = [destination]
    }
    
    /*
          NEW
          sheetBinding: SwiftUI's .sheet(item:) needs a Binding (get + set).
          - get: reads the current sheet.
          - set: SwiftUI calls this with nil when the user SWIPES the sheet down.
            That keeps our `sheet` in sync, so the Presenter always knows the truth.
          - Needed because `sheet` is private(set): views can't write to it directly.
     
     sheet
   ┌─────────┐
   │ .signup │
   └─────────┘
      ↑   ↓
      │   │
SET ───┘   └─── GET
↑             ↓
write/change       read/value
↑             ↓
SwiftUI
          */
         var sheetBinding: Binding<Destination?> {
             Binding(
                 get: { self.sheet },
                 set: { print("drag closed it")
                     self.sheet = $0 }
             )
         }
    
    /*
     NEW
     dismissAll: close EVERYTHING, so only the base layer (the map) shows.
     - sheet = nil: closes the bottom sheet (Signup slides down).
     - fullScreenStack = []: removes every full screen (Welcome slides out).
     - The map isn't in the stack, it lives in RootView's ZStack
       underneath, so it's what's left on screen.

     Difference from the others:
    
     present(_:)        → open a screen (push or sheet)
     dismiss()          → close the top one
     replaceAll(with:)  → wipe + show one screen
     dismissAll()     -> clears all, shows NOTHING  (just the map)
     sheetBinding       → lets SwiftUI close the sheet on drag
     */
    func dismissAll() {
        sheet = nil
        fullScreenStack = []
    }
}
