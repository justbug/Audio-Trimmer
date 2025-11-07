//
//  DetailRow.swift
//  App
//
//  Created by 陳琮諺 on 2025/11/7.
//

import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .bold()
        }
    }
}

#Preview {
    DetailRow(label: "123", value: "456")
}
