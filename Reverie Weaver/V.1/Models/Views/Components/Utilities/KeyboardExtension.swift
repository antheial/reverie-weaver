
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
    func keyboardDismissToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.sageGreen)
            }
        }
    }

    // MARK: - ⌨️ Keyboard Dismissal Helper
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
