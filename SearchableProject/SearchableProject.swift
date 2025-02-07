//
//  SearchableProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 08.02.2025.
//

import SwiftUI
import Combine

struct Restaurant: Identifiable, Hashable {
    var id: String
    var name: String
    var cuisines: Cuisine
}

enum Cuisine: String {
    case American, Italian, Japanese
}

final class RestaurantsManager {
    func getAllRestaurants() async throws -> [Restaurant] {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        return [
            Restaurant(id: "1", name: "Sushi sel", cuisines: .Japanese),
            Restaurant(id: "2", name: "Tunguska", cuisines: .American),
            Restaurant(id: "3", name: "LosAndLosos", cuisines: .American),
            Restaurant(id: "4", name: "MamaRoma", cuisines: .Italian)
        ]
    }
}



@MainActor
final class SearchableProjectViewModel: ObservableObject {
    @Published private(set) var allRestaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var allSearchScopes: [SearchScopeOption] = []
    
    private let manager = RestaurantsManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    var showSearchSuggestions: Bool {
        searchText.count < 5
    }
    
    enum SearchScopeOption: Hashable {
        case all
        case cuisine(option: Cuisine)
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .cuisine(let option):
                return option.rawValue.capitalized
            }
        }
    }
    
    init(){
        addSubscribers()
    }
    
    private func addSubscribers(){
        $searchText
            .combineLatest($searchScope)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] searchText, searchScope in
                self?.filterRestaurants(restText: searchText, restScope: searchScope)
            }
            .store(in: &cancellables)
    }
    
    private func filterRestaurants(restText: String, restScope: SearchScopeOption){
        guard !restText.isEmpty else {
            filteredRestaurants = []
            searchScope = .all
            return
        }
        
        var restaurantInScope = allRestaurants
        switch restScope {
        case .all:
            break
        case .cuisine(let option):
            restaurantInScope = allRestaurants.filter({$0.cuisines == option})
        }
        
        let search = restText.lowercased()
        filteredRestaurants = restaurantInScope.filter({ restaurant in
            let titleContainsSearch = restaurant.name.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisines.rawValue.lowercased().contains(search)
            return titleContainsSearch || cuisineContainsSearch
        })
    }
    
    func loadRestaurants() async {
        do{
            allRestaurants = try await manager.getAllRestaurants()
            let allCuisines = Set(allRestaurants.map({$0.cuisines}))
            allSearchScopes = [.all] + allCuisines.map({ SearchScopeOption.cuisine(option: $0) })
        } catch {
            print(error)
        }
    }
    
    func getSearchSuggestions() -> [String] {
        guard showSearchSuggestions else {
            return []
        }
        var suggestions:[String] = []
        let search = searchText.lowercased()
        if search.contains("pa") {
            suggestions.append("Pasta")
        }
        if search.contains("su") {
            suggestions.append("Sushi")
        }
        if search.contains("bu") {
            suggestions.append("Burgers")
        }
        suggestions.append("Market")
        suggestions.append("Grocery")
        suggestions.append(Cuisine.Italian.rawValue.capitalized)
        suggestions.append(Cuisine.American.rawValue.capitalized)
        suggestions.append(Cuisine.Japanese.rawValue.capitalized)
        return suggestions
    }
    
    //функция для перехода сразу на страницу detailView
    func getRestaurantSuggestions() -> [Restaurant] {
        guard showSearchSuggestions else {
            return []
        }
        var suggestions:[Restaurant] = []
        let search = searchText.lowercased()
        if search.contains("ita") {
            suggestions.append(contentsOf: allRestaurants.filter({$0.cuisines == .Italian}))
        }
        if search.contains("jpa") {
            suggestions.append(contentsOf: allRestaurants.filter({$0.cuisines == .Japanese}))
        }
        if search.contains("ame") {
            suggestions.append(contentsOf: allRestaurants.filter({$0.cuisines == .American}))
        }
        return suggestions
    }
}

struct SearchableProject: View {
    @StateObject private var viewModel = SearchableProjectViewModel()
    var body: some View {
        NavigationStack {
            ScrollView{
                VStack(spacing: 20) {
                    ForEach(viewModel.isSearching ? viewModel.filteredRestaurants: viewModel.allRestaurants, id: \.id) { restaurant in
                        NavigationLink(value: restaurant) {
                            restaurantRow(restaurant: restaurant)
                        }
                    }
                    Text("ViewModel is searching: \(viewModel.isSearching.description)")
                    SearchChildView()
                }
                .padding()
                //placement - формат размещения компонента (для iPhone особой разницы нет), предположительно разница есть под iPad
                //очень крутая реализация из коробки - с анимацией - вариантов поиска
                .searchable(text: $viewModel.searchText, placement: .automatic, prompt: "Search Restaurants")
                //реализация поиска по категориям
                
                //поиск по категориям (в дополнении к .searchable ($viewModel.searchText))
                .searchScopes($viewModel.searchScope, scopes: {
                    ForEach(viewModel.allSearchScopes, id: \.self) { scope in
                        Text(scope.title)
                            .tag(scope)
                    }
                })
                
                //подсказки при поиске (следующий модификатор)
                .searchSuggestions {
                    ForEach(viewModel.getSearchSuggestions(), id: \.self) { item in
                        Text(item)
                            .searchCompletion(item)
                    }
                    
                    //сразу переходит на detailView по ссылке NavigationLink
                    ForEach(viewModel.getRestaurantSuggestions(), id: \.self) { item in
                        NavigationLink(value: item) {
                            Text(item.name)
                        }
                    }
                    /*
                     Text("ghbdtn")
                     .searchCompletion("ghbdtn")
                     //обязательный модификатор для продолжения поиска текста .searchCompletion()
                     */
                }
            }
            .navigationTitle("Restaurants")
            .navigationDestination(for: Restaurant.self) { rest in
                Text(rest.name.uppercased())
            }
        }
        
        .task {
            await viewModel.loadRestaurants()
        }
        
    }
    
}

struct SearchChildView: View {
    @Environment(\.isSearching) private var isSearching
    var body: some View {
        Text("Child View is seaching: \(isSearching)")
    }
}

#Preview {
    NavigationStack{
        SearchableProject()
    }
}


extension SearchableProject {
    
    private func restaurantRow(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.name)
                .font(.headline)
                .foregroundStyle(Color.red)
            Text(restaurant.cuisines.rawValue.capitalized)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
        .tint(.primary)
    }
    
}
