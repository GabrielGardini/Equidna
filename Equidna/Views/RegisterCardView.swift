//
//  RegisterCardView.swift
//  EquidnaApp
//
//  Created by Giovanna Spigariol on 02/09/25.
//

import SwiftUI

struct RegisterCardView: View {
    var title: String
    var subtitle: String
    var icon: String
    var backgroundImage: String
    
    var body: some View {
        ZStack() {
            Image(backgroundImage) // depois tenho que adiciona no Assets
                .resizable()
                .scaledToFill()
                .frame(height: 97)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.85, green: 0.84, blue: 0.89)) // equivalente ao #D9D7E3
                    .padding(.leading, 16)

            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}
