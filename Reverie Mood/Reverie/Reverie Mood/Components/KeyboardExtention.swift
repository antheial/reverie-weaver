// MARK: - FIX 2: Keyboard Dismissal Extension
// ============================================

// Add this extension to any file (or create KeyboardExtension.swift)

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

// **MARK: - Multilingual TextField Support**
extension View {
    func multilingualTextField() -> some View {
        self
            .autocorrectionDisabled(false)
            .textInputAutocapitalization(.never)
    }
}

// **MARK: - Universal Keyboard Dismissal**
extension View {
    /// Adds a "Done" button above keyboard that works with Chinese IME
    func keyboardDismissToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }

    // MARK: - ⌨️ Keyboard Dismissal Helper
    //func dismissKeyboardOnBackgroundTap() -> some View {
    //self.onTapGesture {
    // UIApplication.shared.sendAction(
    //  #selector(UIResponder.resignFirstResponder),
    // to: nil,
    // from: nil,
    // for: nil
    // )
    // }
    //}
    // Adds tap-to-dismiss on ScrollView background
   func dismissKeyboardOnBackgroundTap() -> some View {
        self.background(
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                     hideKeyboard()
                     }
             )
        }
}
