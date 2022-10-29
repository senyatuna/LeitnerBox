//
// LevelRow.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 9/2/22.

import SwiftUI
import AVFoundation
import CoreData

struct LevelRow: View {
    @EnvironmentObject
    var vm: LevelsViewModel

    @EnvironmentObject
    var level: Level

    @Environment(\.horizontalSizeClass)
    var sizeClass

    @Environment(\.avSpeechSynthesisVoice)
    var voiceSpeech: AVSpeechSynthesisVoice

    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    var body: some View {
        NavigationLink {
            LazyView(ReviewView())
                .environmentObject(ReviewViewModel(viewContext: context, level: level, voiceSpeech: voiceSpeech))
        } label: {
            HStack {
                HStack {
                    Text(verbatim: "\(level.level)")
                        .foregroundColor(.white)
                        .font(.title.weight(.bold))
                        .frame(width: 48, height: 48)
                        .accessibilityIdentifier("levelRow")
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                    let favCount = level.allQuestions.filter { $0.favorite == true }.count

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.accentColor)
                        Text(verbatim: "\(favCount)")
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack {
                    HStack(spacing: 0) {
                        Text(verbatim: "\(level.reviewableCountInsideLevel)")
                            .foregroundColor(.accentColor.opacity(1))
                        Spacer()
                        Text(verbatim: "\(level.notCompletdCount)")
                            .foregroundColor(.primary.opacity(1))
                    }
                    .font(.footnote)

                    ProgressView(
                        value: Float(level.reviewableCountInsideLevel),
                        total: Float(level.notCompletdCount)
                    )
                    .progressViewStyle(.linear)
                }
                .frame(maxWidth: sizeClass == .regular ? 192 : 128)
            }
            .contextMenu {
                Button {
                    vm.selectedLevel = level
                    vm.daysToRecommend = Int(level.daysToRecommend)
                    vm.showDaysAfterDialog.toggle()
                } label: {
                    Label("Days to recommend", systemImage: "calendar")
                }
            }
            .padding([.leading, .top, .bottom], 8)
        }
    }
}

struct LevelRow_Previews: PreviewProvider {
    static var previews: some View {
        LevelRow()
        .environmentObject(LevelsViewModel(
            viewContext: PersistenceController.previewVC,
            leitner: LeitnerView_Previews.leitner
        ))
        .environmentObject(LeitnerView_Previews.leitner.levels.first!)
    }
}
