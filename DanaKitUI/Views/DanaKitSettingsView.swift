//
//  DanaKitSettingsView.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 03/01/2024.
//  Copyright © 2024 Randall Knutson. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI

struct DanaKitSettingsView: View {
    @Environment(\.guidanceColors) private var guidanceColors
    @Environment(\.dismissAction) private var dismiss
    
    @ObservedObject var viewModel: DanaKitSettingsViewModel
    
    var supportedInsulinTypes: [InsulinType]
    var imageName: String
    
    var removePumpManagerActionSheet: ActionSheet {
        ActionSheet(title: Text(LocalizedString("Remove Pump", comment: "Title for Dana-i/RS PumpManager deletion action sheet.")),
                    message: Text(LocalizedString("Are you sure you want to stop using Dana-i/RS?", comment: "Message for Dana-i/RS PumpManager deletion action sheet")),
                    buttons: [
                        .destructive(Text(LocalizedString("Delete pump", comment: "Button text to confirm Dana-i/RS PumpManager deletion"))) {
                            viewModel.stopUsingDana()
                        },
                        .cancel()
        ])
    }
    
    var body: some View {
        List {
            Section() {
                Image(uiImage: UIImage(named: imageName, in: Bundle(for: DanaKitHUDProvider.self), compatibleWith: nil)!)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal)
                    .frame(height: 200)
                
                HStack(alignment: .top) {
                    deliveryStatus
                    Spacer()
                    reservoirStatus
                }
                .padding(.bottom, 5)
            }
            
            Section {
                HStack {
                    Button($viewModel.basalButtonText.wrappedValue) {
                        viewModel.suspendResumeButtonPressed()
                    }
                }
            }
            
            Section(header: SectionHeader(label: LocalizedString("Configuration", comment: "The title of the configuration section in DanaKit settings")))
            {
                NavigationLink(destination: InsulinTypeSetting(initialValue: viewModel.insulineType, supportedInsulinTypes: supportedInsulinTypes, allowUnsetInsulinType: false, didChange: viewModel.didChangeInsulinType)) {
                    HStack {
                        Text(LocalizedString("Insulin Type", comment: "Text for confidence reminders navigation link")).foregroundColor(Color.primary)
                        Spacer()
                        Text(viewModel.insulineType.brandName)
                            .foregroundColor(.secondary)
                        }
                }
            }
            
            Section() {
                Button(action: {
                    viewModel.showingDeleteConfirmation = true
                }) {
                    Text(LocalizedString("Delete Pump", comment: "Label for PumpManager deletion button"))
                        .foregroundColor(guidanceColors.critical)
                }
                .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
                    removePumpManagerActionSheet
                }
            }
        }
        .insetGroupedListStyle()
        .navigationBarItems(trailing: doneButton)
        .navigationBarTitle(viewModel.pumpModel)
    }
    
    private var doneButton: some View {
        Button("Done", action: {
            dismiss()
        })
    }
    
    var reservoirStatus: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedString("Insulin Remaining", comment: "Header for insulin remaining on pod settings screen"))
                .foregroundColor(Color(UIColor.secondaryLabel))
//            if let reservoirReading = viewModel.reservoirReading,
//               let reservoirLevelHighlightState = viewModel.reservoirLevelHighlightState,
//               let reservoirPercent = viewModel.reservoirPercentage
//            {
//                HStack {
//                    MinimedReservoirView(filledPercent: reservoirPercent, fillColor: reservoirColor(for: reservoirLevelHighlightState))
//                        .frame(width: 23, height: 32)
//                    Text(viewModel.reservoirText(for: reservoirReading.units))
//                        .font(.system(size: 28))
//                        .fontWeight(.heavy)
//                        .fixedSize()
//                }
//            }
        }
    }
    
    var deliveryStatus: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(deliverySectionTitle)
                .foregroundColor(Color(UIColor.secondaryLabel))
            if viewModel.isSuspended {
                HStack(alignment: .center) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(viewModel.isSuspended ? guidanceColors.warning : Color.accentColor)
                    Text(LocalizedString("Insulin\nSuspended", comment: "Text shown in insulin delivery space when insulin suspended"))
                        .fontWeight(.bold)
                        .fixedSize()
                }
            } else if let basalRate = self.viewModel.basalRate {
                HStack(alignment: .center) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(viewModel.basalRateFormatter.string(from: basalRate) ?? "")
                            .font(.system(size: 28))
                            .fontWeight(.heavy)
                            .fixedSize()
                        Text(LocalizedString("U/hr", comment: "Units for showing temp basal rate"))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(alignment: .center) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(guidanceColors.warning)
                    Text(LocalizedString("Unknown", comment: "Text shown in basal rate space when delivery status is unknown"))
                        .fontWeight(.bold)
                        .fixedSize()
                }
            }
        }
    }
    
    var deliverySectionTitle: String {
        if !self.viewModel.isSuspended {
            return LocalizedString("Scheduled Basal", comment: "Title of insulin delivery section")
        } else {
            return LocalizedString("Insulin Delivery", comment: "Title of insulin delivery section")
        }
    }
}

#Preview {
    DanaKitSettingsView(viewModel: DanaKitSettingsViewModel(nil, nil), supportedInsulinTypes: InsulinType.allCases, imageName: "danai")
}
