//
//  SearchViewModel.swift
//  LeitnerBox
//
//  Created by hamed on 5/20/22.
//

import Foundation
import SwiftUI
import CoreData
import AVFoundation

class SearchViewModel:ObservableObject{
   
    @Published
    var viewContext:NSManagedObjectContext = PersistenceController.shared.container.viewContext

    @Published
    var questions:[Question] = []
    
    @Published
    var suggestions:[Question] = []
    
    @Published
    var searchText:String = ""
    
    @Published
    var showAddQuestionView = false
    
    @Published
    var showLeitnersListDialog = false
    
    @Published
    var selectedQuestion:Question? = nil
    
    @Published
    var leitner:Leitner
    
    @Published
    var selectedSort:SearchSort = .LEVEL
    
    var synthesizer = AVSpeechSynthesizer()
    
    var speechDelegate:SpeechDelegate
    
    @Published
    var isSpeaking = false
    
    init(leitner:Leitner, isPreview:Bool = false ){
        self.speechDelegate = SpeechDelegate()
        synthesizer.delegate = speechDelegate
        viewContext = isPreview ? PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
        self.leitner = leitner
        let predicate = NSPredicate(format: "level.leitner.id == %d", leitner.id)
        let req = Question.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Question.passTime, ascending: true)]
        req.predicate = predicate
        do {
            self.questions = try viewContext.fetch(req)
        }catch{
            print("Fetch failed: Error \(error.localizedDescription)")
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { questions[$0] }.forEach(viewContext.delete)
            saveDB()
        }
    }
    
    func delete(_ question:Question){
        viewContext.delete(question)
        if let index = questions.firstIndex(where: {$0 == question}){
            questions.remove(at: index)
        }
        saveDB()
    }
    
    func sort(_ sort:SearchSort){
        selectedSort = sort
        switch sort {
        case .LEVEL:
            questions.sort(by: {
                ($0.level?.level ?? 0) < ($1.level?.level ?? 0)
            })
        case .COMPLETED:
            questions.sort(by: { first,second in
                first.completed
            })
        case .ALPHABET:
            questions.sort(by: {
                ($0.question ?? "") < ($1.question ?? "")
            })
        case .FAVORITE:
            questions.sort(by: { first, second in
                return first.favorite
            })
        case .DATE:
            questions.sort(by: {
                ($0.passTime ?? Date()) < ($1.passTime ?? Date())
            })
        }
    }
    
    func toggleCompleted(_ question:Question){
        question.completed.toggle()
        saveDB()
    }
    
    func toggleFavorite(_ question:Question){
        question.favorite.toggle()
        saveDB()
    }
    
    func resetToFirstLevel(_ question:Question){        
        question.level?.level = 1
        question.completed = false
        saveDB()
    }
    
    func pronounce(_ question:Question){
        isSpeaking                   = true
        let utterance                = AVSpeechUtterance(string          : question.question ?? "")
        utterance.voice              = AVSpeechSynthesisVoice(language : "en-GB")
        utterance.rate               = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier    = 1
//        utterance.voice              = AVSpeechSynthesisVoice.speechVoices().last
        utterance.postUtteranceDelay = 0
        synthesizer.speak(utterance)
    }
    
    func saveDB(){
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    var timer:Timer? = nil
    var lastPlayedQuestion:Question? = nil
    func playReview(){
        
        if speechDelegate.viewModel == nil{
            speechDelegate.viewModel = self
        }
        
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }else if lastPlayedQuestion == nil, let firstQuestion = questions.first{
            pronounce(firstQuestion)
            lastPlayedQuestion = firstQuestion
        }else if let firstQuestion = questions.first{
            pronounce(firstQuestion)
            lastPlayedQuestion = firstQuestion
        }
    }
    
    func playNext(){
        guard let lastPlayedQuestion = lastPlayedQuestion else { return }
        if let index = questions.firstIndex(of: lastPlayedQuestion){
            
            if questions.indices.contains(index + 1){
                let nextQuestion = questions[index + 1]
                pronounce(nextQuestion)
                self.lastPlayedQuestion = nextQuestion
            }
        }
    }
    
    func playNextImmediately(){
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = speechDelegate
        playNext()
    }
    
    func hasNext()->Bool{
        if let lastPlayedQuestion = lastPlayedQuestion , let index = questions.firstIndex(of: lastPlayedQuestion), questions.indices.contains(index + 1){
            return true
        }else{
            return false
        }
    }
    
    func pauseReview(){
        isSpeaking = false
        speechDelegate.timer?.invalidate()
        if synthesizer.isSpeaking{
            synthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        }
    }
    
    func stopReview(){
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speechDelegate.timer?.invalidate()
        self.lastPlayedQuestion = nil
    }
    
    func finished(){
        isSpeaking = false
        lastPlayedQuestion = nil
    }
    
    var reviewdCount:Int{
        if let lastPlayedQuestion = lastPlayedQuestion , let index = questions.firstIndex(of: lastPlayedQuestion){
            return index + 1
        }else{
            return 0
        }
    }
    
    func moveQuestionTo(_ leitner:Leitner){
        if let selectedQuestion = selectedQuestion, let firstLevel = (leitner.level?.allObjects as? [Level])?.first(where: {$0.level == 1}) {
            selectedQuestion.level = firstLevel
            saveDB()
            questions.removeAll(where: {$0 == selectedQuestion})
        }
    }
}

class SpeechDelegate:NSObject, AVSpeechSynthesizerDelegate{

    var viewModel:SearchViewModel? = nil
    var timer:Timer? = nil
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if viewModel?.hasNext() == true{
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                self.viewModel?.playNext()
            }
        }else{
            viewModel?.finished()
        }
    }
}


var searchSorts:[SortModel] = [
    .init(iconName:"textformat.abc", title:"Alphabet", sortType:.ALPHABET),
    .init(iconName:"arrow.up.arrow.down.square", title:"Level", sortType:.LEVEL),
    .init(iconName:"calendar.badge.clock", title:"Date", sortType:.DATE),
    .init(iconName:"star", title:"Favorite", sortType:.FAVORITE),
    .init(iconName:"flag.2.crossed", title:"Completed", sortType:.COMPLETED),
]

struct SortModel:Hashable{
    let iconName:String
    let title:String
    let sortType:SearchSort
}

enum SearchSort{
    
    case LEVEL
    case COMPLETED
    case ALPHABET
    case FAVORITE
    case DATE
}