//
//  SearchView.swift
//  LeitnerBox
//
//  Created by hamed on 5/19/22.
//

import SwiftUI
import CoreData

struct SearchView: View {
    
    @ObservedObject
    var vm:SearchViewModel
    
    var body: some View {
        ZStack{
            
            List {
                ForEach(vm.questions) { item in
                    SearchRowView(question: item, vm: vm)
                }
                .onDelete(perform: vm.deleteItems)
            }
            .listStyle(.plain)
            .searchable(text: $vm.searchText, placement: .navigationBarDrawer, prompt: "Search inside leitner...") {
                if vm.suggestions.count > 0 || vm.searchText.isEmpty{
                    ForEach(vm.suggestions){ suggestion in
                        SearchRowView(question: suggestion, vm: vm)
                    }
                }else{
                    HStack{
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.gray.opacity(0.8))
                        Text("Nothind has found.")
                            .foregroundColor(.gray.opacity(0.8))
                       
                    }
                }
            }
            .onChange(of: vm.searchText) { newValue in
                vm.suggestions = vm.questions.filter({$0.question?.lowercased().contains(vm.searchText.lowercased()) ?? false })
            }
            
            if vm.isSpeaking{
                VStack(alignment:.leading){
                    Spacer()
                    HStack{
                        VStack(alignment:.leading, spacing: 8){
                            Text(verbatim: vm.lastPlayedQuestion?.question ?? "")
                                .foregroundColor(.primary)
                                .font(.title.weight(.bold))
                            
                            Text(verbatim: vm.lastPlayedQuestion?.answer ?? "")
                                .foregroundColor(.primary)
                                .font(.body.weight(.medium))
                            
                            Text(verbatim: "\(vm.reviewdCount) / \(vm.questions.count)")
                                .font(.footnote.bold())
                        }
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, 24)
                    .background(
                        Color(named: "reviewBackground")
                            .cornerRadius(24, corners: [.topLeft,.topRight])
                            .shadow(radius: 5)
                    )
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea()
            }
        
            NavigationLink(isActive:$vm.showAddQuestionView) {
                let levels = vm.leitner.level?.allObjects as? [Level]
                let firstLevel = levels?.first(where: {$0.level == 1})
                AddOrEditQuestionView(vm: .init(level:  firstLevel!, editQuestion: vm.selectedQuestion))
            } label: {
                EmptyView()
            }
            .hidden()
        }
//        .customDialog(isShowing:$vm.showLeitnersListDialog, content: {
//            let vm = LeitnerViewModel()
//            VStack{
//                List {
//                    ForEach(vm.leitners) { leitner in
//                        Text(leitner.name ?? "")
//                            .contentShape(Rectangle())
//                            .onTapGesture {
//                                withAnimation {
//                                    self.vm.moveQuestionTo(leitner)
//                                    self.vm.showLeitnersListDialog.toggle()
//                                }
//                            }
//                    }
//                }
//                .listStyle(.plain)
//                
//                Button {
//                    self.vm.showLeitnersListDialog.toggle()
//                } label: {
//                    HStack{
//                        Spacer()
//                        Text("Cancel")
//                            .foregroundColor(.red)
//                        Spacer()
//                    }
//                }
//                .controlSize(.large)
//                .buttonStyle(.bordered)
//                .frame(maxWidth: .infinity)
//            }
//        })
        .animation(.easeInOut, value: vm.isSpeaking)
        .navigationTitle("Advance Search in \(vm.leitner.name ?? "")")
        .toolbar {
            ToolbarItem {
                Button {
                    vm.selectedQuestion = nil
                    vm.showAddQuestionView.toggle()
                } label: {
                    Label("Add", systemImage: "plus.square")
                }
            }
            
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
               
                Button {
                    vm.stopReview()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!vm.isSpeaking)
                
                
                Button {
                    vm.pauseReview()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(!vm.isSpeaking)
                
                
                Button {
                    vm.playReview()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }.disabled(vm.isSpeaking)
                
                Button {
                    vm.playNextImmediately()
                } label: {
                    Label("Next", systemImage: "forward.end.fill")
                }.disabled(!vm.isSpeaking)
                
                Menu {
                    Text("Sort By")
                    
                    ForEach(searchSorts, id:\.self){ sortItem in
                        Button {
                            withAnimation {
                                vm.sort(sortItem.sortType)
                            }
                        } label: {
                            Label( "\(vm.selectedSort == sortItem.sortType ? "✔︎ " : "")" + sortItem.title, systemImage: sortItem.iconName)
                        }
                    }
                    
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    
    static var vm:SearchViewModel{
        let vm = SearchViewModel(leitner: LeitnerView_Previews.leitner, isPreview: true)
        vm.isSpeaking = false
        return vm
    }
    
    static var previews: some View {
        SearchView(vm: vm)
            .preferredColorScheme(.light)
    }
}