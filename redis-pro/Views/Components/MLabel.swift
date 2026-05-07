//
//  MLabel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/20.
//

import SwiftUI

struct MLabel: View {
    var name: String
    var icon: String
    var size: MLabelSize = .M
    
    var font: Font {
        switch size {
        case .S: return .footnote
        case .M: return .callout
        case .L: return .body
        }
    }
    
    var body: some View {
        Label {
            Text(name)
                .font(font)
        } icon: {
            Image(systemName: icon)
                .font(font)
        }
        .foregroundColor(.primary)
    }
}

enum MLabelSize {
    case S
    case M
    case L
}

struct MLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MLabel(name: "Add", icon: "plus")
            MLabel(name: "DB\(1)", icon: "cylinder.split.1x2", size: .S)
        }
    }
}
