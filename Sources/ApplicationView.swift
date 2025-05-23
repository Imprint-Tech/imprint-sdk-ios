//
//  ApplicationView.swift
//
//
//  Created by Wanting Shao on 10/7/24.
//

import SwiftUI

struct ApplicationView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var viewModel: ApplicationViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      ZStack {
        if let logoUrl = viewModel.logoUrl {
          AsyncImage(url: logoUrl) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          } placeholder: {
            EmptyView()
          }
          .frame(height: 24)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, alignment: .center)
        }
        
        HStack {
          Spacer()
          Button(action: {
            dismissView()
          }) {
            Image(systemName: "xmark")
              .frame(width: 48, height: 48)
              .foregroundColor(Color(red: 0.137, green: 0.137, blue: 0.137))
              .font(.system(size: 16, weight: .semibold))
          }
          .padding(.trailing, 4)
        }
      }
      .frame(height: 56)
      
      WebViewWrapper(viewModel: viewModel)
    }
    .background(Color.white.ignoresSafeArea())
    .onReceive(viewModel.$processState) { newState in
      if newState == .closed {
        dismissView()
      }
    }
  }
  
  private func dismissView() {
    DispatchQueue.main.async {
      viewModel.onDismiss()
    }
    presentationMode.wrappedValue.dismiss()
  }
}

#Preview {
  ApplicationView(viewModel: .init(configuration: .init(clientSecret: "")))
}
