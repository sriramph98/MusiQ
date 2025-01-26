import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 8)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 40)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
} 