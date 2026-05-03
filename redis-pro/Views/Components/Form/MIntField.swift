//
//  MIntField.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/11.
//

import SwiftUI
import Logging

struct MIntField: View {
    @Binding var value:Int
    var placeholder:String?
    @FocusState private var isFocused: Bool
    var onCommit: (() -> Void)?
    
    // 是否有编辑过，编辑过才会触commit
    @State private var isEdited:Bool = false
    
    let logger = Logger(label: "int-field")
    
    @ViewBuilder
    private var field: some View {
        if #available(macOS 12.0, *) {
            TextField("", value: $value, formatter: NumberHelper.intFormatter, prompt: Text(placeholder ?? ""))
                .onSubmit {
                    doCommit()
                }
                .focused($isFocused)
        } else {
            TextField(placeholder ?? "", value: $value, formatter: NumberHelper.intFormatter, onEditingChanged: { isEditing in
                self.isEdited = isEditing
            }, onCommit: doCommit)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            field
                .labelsHidden()
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .font(.body)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .glassField(cornerRadius: LiquidGlass.radiusXS, isActive: isFocused)
    }
    
    func doCommit() -> Void {
        logger.info("on textField commit, value: \(value)")
        onCommit?()
    }
}

//struct MIntField_Previews: PreviewProvider {
//    static var previews: some View {
//        MIntField()
//    }
//}
