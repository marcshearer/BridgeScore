//
//  Share Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/11/2023.
//

import UIKit
import SwiftUI
import MessageUI

struct ShareScorecardView: View {
    var id = UUID()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    @State var initialYOffset: CGFloat
    @State var yOffset: CGFloat = 0
    @State private var result: Result<MFMailComposeResult, Error>?
    @State private var players: [PlayerViewModel] = []
    @State private var playerIndex: Int = 0
    @State private var showMail = false
    @State private var toPlayer: PlayerViewModel! = nil
    @State private var includeComment = false
    @State private var includeResponsible = false
    @State var attachmentData: Data?
    @State var frame: CGRect
    @State var dismissView: Bool = false
    @State var playerName: String?
    var playerNames: [String] = []
    
    init(scorecard: ScorecardViewModel, frame: CGRect, initialYOffset: CGFloat) {
        self.scorecard = scorecard
        _frame = State(initialValue: frame)
        _initialYOffset = State(initialValue: initialYOffset)
        _yOffset = State(initialValue: initialYOffset)
        playerNames = getPlayerNames()
    }
    
    var body: some View {
        PopupStandardView("Detail", slideInId: id) {
            VStack {
                Banner(title: Binding.constant("Share Scorecard"), alternateStyle: true, back: true, backText: "Cancel", backAction: { dismissView
                    = true ; return false })
                if MFMailComposeViewController.canSendMail() {
                    InsetView(title: "Recipient Details") {
                        VStack {
                            HStack {
                                Spacer().frame(width: 14)
                                if players.count > 0 {
                                    PickerInputSimple(title: "Send to", field: $playerIndex, values: players.map{$0.name} + ["Other"], topSpace: 20, width: 200, titleWidth: 206)
                                }
                                Spacer()
                            }
                            Spacer().frame(height: 10)
                            HStack {
                                Spacer().frame(width: 14)
                                VStack {
                                    LeadingText("Player").frame(width: 200)
                                    Spacer()
                                }
                                .frame(height: 150)
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            ForEach(playerNames.indices, id: \.self) { index in
                                                let playerName = playerNames[index]
                                                VStack(spacing: 0) {
                                                    Spacer()
                                                    HStack {
                                                        Spacer().frame(width: 4)
                                                        Text(playerName)
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                    Rectangle().frame(height: 1).foregroundColor(Palette.separator.background)
                                                }
                                                .id(playerName)
                                                .frame(height: 36)
                                                .if(playerName == self.playerName) { view in
                                                    view.palette(.alternate)
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    self.playerName = playerName
                                                }
                                            }
                                        }
                                    }
                                    .onChange(of: playerName, initial: false) {
                                        proxy.scrollTo(playerName, anchor: .center)
                                    }
                                    .frame(width: 200, height: 150)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Palette.contrastTile.background, lineWidth: 1)
                                    )
                                }
                                Spacer()
                            }
                            Spacer().frame(height: 10)
                        }
                    }
                    InsetView(title: "Content") {
                        VStack {
                            HStack {
                                Spacer().frame(width: 14)
                                InputToggle(title: "Include comments", field: $includeComment, topSpace: 30, width: 40, inlineTitleWidth: 200)
                                Spacer()
                            }
                            HStack {
                                Spacer().frame(width: 14)
                                InputToggle(title: "Include responsible", field: $includeResponsible, topSpace: 10, width: 40, inlineTitleWidth: 200)
                                Spacer()
                            }
                            Spacer().frame(height: 20)
                        }
                    }
                    VStack {
                        Spacer()
                        Button {
                            if let playerName = playerName, let json = Export.export(scorecard: scorecard, playerName: playerName, includeComment: includeComment, includeResponsible: includeResponsible), let data = json.data(using: .utf8) {
                                attachmentData = data
                                showMail = true
                            } else {
                                MessageBox.shared.show("Error Exporting Scorecard")
                            }
                        } label: {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("Send")
                                    Spacer()
                                }
                                Spacer()
                            }
                            .frame(width: 100, height: 40)
                            .palette(.enabledButton)
                            .cornerRadius(10)
                        }
                        Spacer()
                    }
                    if showMail {
                        ScorecardMailView(scorecard: scorecard, toEmail: toPlayer?.email ?? "", fromEmail: MasterData.shared.scorer!.email, attachmentData: attachmentData, isShowing: $showMail, result: $result)
                    }
                } else {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Mail not supported")
                        Spacer()
                    }
                    Spacer()
                }
                Spacer()
            }
            .background(Palette.alternate.background)
            .cornerRadius(10)
            .onAppear {
                players = MasterData.shared.players.filter({(!$0.retired || $0 == scorecard.partner!) && $0.email != "" && !$0.isSelf})
                playerIndex = players.firstIndex(where: {$0.playerId == scorecard.partner?.playerId}) ?? 0
                updatePlayerName()
                withAnimation(.linear(duration: 0.25).delay(0.1)) {
                    yOffset = frame.minY
                }
            }
            .onChange(of: playerIndex, initial: false) {
                updatePlayerName()
            }
            .onChange(of: showMail, initial: false) {
                if !showMail {
                    if case .success(let reason) = result {
                        if reason == .cancelled {
                            // Allow retry
                        } else {
                            // Success - close
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        // Error - report and close
                        MessageBox.shared.show("Error sending mail", okAction: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                }
            }
            .offset(x: frame.minX, y: yOffset)
            .onChange(of: dismissView) {
                if dismissView == true {
                    dismissView = false
                    withAnimation(.linear(duration: 0.25)) {
                        yOffset = initialYOffset
                    }
                    Utility.executeAfter(delay: 0.25) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .frame(width: frame.width, height: frame.height)
        }
    }
    
    func getPlayerNames() -> [String] {
        var names = Array(Set(Scorecard.current.rankingList.map({$0.players}).flatMap({$0.values}))).sorted(by: {$0 < $1})
        if Scorecard.current.isImported && scorecard.importSource == .bbo {
            for index in names.indices {
                if let realName = MasterData.shared.realName(bboName: names[index]) {
                    names[index] = realName
                }
            }
        }
        return names.sorted(by: {$0 < $1})
    }
    
    func updatePlayerName() {
        toPlayer = (playerIndex <= players.count - 1 ? players[playerIndex] : nil)
        if let toPlayer = toPlayer {
            if let playerName = playerNames.first(where: {$0.folding(options: .diacriticInsensitive, locale: nil).lowercased() == toPlayer.name.folding(options: .diacriticInsensitive, locale: nil).lowercased()}) {
                self.playerName = playerName
            }
        }
    }
}

struct ScorecardMailView: UIViewControllerRepresentable {
    @State var scorecard: ScorecardViewModel
    @State var toEmail: String
    @State var fromEmail: String
    @State var attachmentData: Data?
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(isShowing: Binding<Bool>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isShowing = isShowing
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                isShowing = false
            }
            if let error = error {
                self.result = .failure(error)
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ScorecardMailView>) -> MFMailComposeViewController {
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = context.coordinator
        mailViewController.setPreferredSendingEmailAddress(fromEmail)
        mailViewController.setToRecipients([toEmail])
        mailViewController.setSubject("Sharing: \(scorecard.desc)")
        mailViewController.setMessageBody("<html><head/><body><p>Attached is a copy of the \(scorecard.desc) event as played by \(MasterData.shared.scorer!.name) and \(scorecard.partner!.name) in the \(scorecard.location!.name) on \(Utility.dateString(scorecard.date, style: .full)).</p><p>Click on the attachment to import it into your Bridge Score history.</p><p>Regards,<br/>\(MasterData.shared.scorer!.name)</p></body></html>", isHTML: true)
        mailViewController.addAttachmentData(attachmentData!, mimeType: "application/json", fileName: "\(scorecard.desc).bsjson")
        return mailViewController
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<ScorecardMailView>) {

    }
}
