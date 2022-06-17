//
//  StatisticsViewModel.swift
//  LeitnerBox
//
//  Created by hamed on 5/20/22.
//

import Foundation
import SwiftUI
import CoreData

class StatisticsViewModel:ObservableObject{
    
    @Published
    var viewContext:NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    @Published
    var statistics:[Statistic] = []
    
    @State
    var percentage:Double = 0
    
    @Published
    var timeframe: Timeframe = .week
    
    init(isPreview:Bool = false ){
        viewContext = isPreview ? PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
        load()
    }
    
    func saveDB(){
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func load(){
        let req = Statistic.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Statistic.actionDate, ascending: true)]
        do {
            self.statistics = try viewContext.fetch(req)
        }catch{
            print("Fetch failed: Error \(error.localizedDescription)")
        }
    }
    
    private func byWeek()->[Statistic]{
        let lastWeek = Calendar.current.date(byAdding: .weekday, value: -8, to: .now)
        return statistics.filter({ lastWeek?.timeIntervalSince1970 ?? 0 <= $0.actionDate?.timeIntervalSince1970 ?? 0  })
    }
    
    private func byMonth()->[Statistic]{
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now)
        return statistics.filter({ lastMonth?.timeIntervalSince1970 ?? 0 <= $0.actionDate?.timeIntervalSince1970 ?? 0  })
    }
    
    private func byYear()->[Statistic]{
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: .now)
        return statistics.filter({ lastYear?.timeIntervalSince1970 ?? 0 <= $0.actionDate?.timeIntervalSince1970 ?? 0  })
    }
    
    private func successOfWeek()-> [[IndexingIterator<Array<Statistic>>.Element]]{
        let gorupedByDate = byWeek().groupSort(byDate: {$0.actionDate ?? Date() })
        return gorupedByDate
    }
    
    private func stateByPassed()->[[Statistic]]{
        return  [byWeek().filter{$0.isPassed}, byWeek().filter{$0.isPassed == false} ]
    }
    
    private func weekPlotable()->[PloatableItem]{
        let data = byWeek()
        return totolPlottables(data: data)
    }
    
    private func monthPlotable()->[PloatableItem]{
        let data = byMonth()
        return totolPlottables(data: data)
    }
    
    private func yearPlotable()->[PloatableItem]{
        let data = byYear()
        return totolPlottables(data: data)
    }
    
    private func totolPlottables(data:[Statistic])->[PloatableItem]{
        return plotables(data, isPassed: true) + plotables(data, isPassed: false)
    }
    
    private func plotables(_ array :[Statistic], isPassed:Bool)->[PloatableItem]{
        var arr:[PloatableItem] = []
        array.filter({$0.isPassed == isPassed}).forEach { statistic in
            //if exist add count
            if let index = arr.firstIndex(where: {$0.date.isInInSameDay(statistic.actionDate) && $0.isPassed == isPassed}){
                arr[index].count += 1
            }else{
                //add new Item to array and set count to 1
                let day = PloatableItem(count:1, date: statistic.actionDate?.startOfDay ?? Date(), isPassed: isPassed )
                arr.append(day)
            }
        }
        return arr
    }
    
    var plaotsForSelectedTime:[PloatableItem]{
        switch timeframe {
        case .today:
            fatalError("not implemented")
        case .week:
            return weekPlotable()
        case .month:
            return monthPlotable()
        case .year:
            return yearPlotable()
        }
    }
}

struct PloatableItem:Hashable{
    var count:Int
    let date:Date
    let isPassed:Bool
}

public enum Timeframe: String, Hashable, CaseIterable, Sendable {
    case today
    case week
    case month
    case year
}

