//
//  SearchView.swift
//  CheeseApp
//
//  🔍 搜索页面
//  聚合搜索租房、二手、拼车、组队、论坛真实数据
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var selectedHotCategory: SearchCategory = .rent
    @State private var destination: SearchNavigationDestination?
    @State private var selectedResult: UnifiedSearchResult?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        searchBar
                        categoryFilter

                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            recentSearchesSection
                            hotByTypeSection
                            categoriesGrid
                        } else {
                            searchResults
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(L10n.tr("Search", "搜尋"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $destination) { target in
                destinationView(for: target)
            }
            .navigationDestination(item: $selectedResult) { result in
                SearchResultDetailRouter(result: result)
            }
            .task {
                await viewModel.loadInitialData()
                viewModel.updateSearch(text: searchText, category: selectedCategory)
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSearch(text: newValue, category: selectedCategory)
            }
            .onChange(of: selectedCategory) { _, newValue in
                viewModel.updateSearch(text: searchText, category: newValue)
            }
        }
    }

    // MARK: - 搜索框
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(L10n.tr("Search everything...", "搜尋你想找的內容..."), text: $searchText)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit {
                    guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    viewModel.addRecentSearch(searchText)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - 分类筛选
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    SearchCategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    // MARK: - 最近搜索
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("Recent", "最近搜尋"))
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                if !viewModel.recentSearches.isEmpty {
                    Button(L10n.tr("Clear", "清除")) {
                        viewModel.clearRecentSearches()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            }

            if viewModel.recentSearches.isEmpty {
                Text(L10n.tr("Your recent searches will appear here", "你的最近搜尋會顯示在這裡"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 10) {
                    ForEach(Array(viewModel.recentSearches.enumerated()), id: \.offset) { _, query in
                        Button(action: {
                            searchText = query
                            viewModel.updateSearch(text: query, category: selectedCategory)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                Text(query)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBackground)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 热门榜（文字榜单 + 分类切换）
    private var hotByTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Hot Ranking", "熱門排行榜"))
                .font(.system(size: 18, weight: .semibold))

            hotCategorySwitch

            let rankingItems = viewModel.hotPosts(for: selectedHotCategory)

            if rankingItems.isEmpty {
                Text(L10n.tr("No trending content yet", "目前沒有熱門內容"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rankingItems.prefix(10).enumerated()), id: \.element.id) { index, item in
                        Button {
                            selectedResult = item
                        } label: {
                            TextHotRankRow(rank: index + 1, item: item)
                        }
                        .buttonStyle(.plain)

                        if index < min(rankingItems.count, 10) - 1 {
                            Divider()
                                .padding(.leading, 42)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            }
        }
    }

    private var hotCategorySwitch: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            selectedHotCategory = category
                        }
                    } label: {
                        Text(category.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedHotCategory == category ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedHotCategory == category ? AppColors.selectedBackground : AppColors.cardBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 分类网格
    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Browse by Category", "依分類瀏覽"))
                .font(.system(size: 18, weight: .semibold))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(SearchCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    Button(action: {
                        destination = category.navigationDestination
                    }) {
                        CategoryCard(
                            icon: category.icon,
                            title: category.displayName,
                            count: viewModel.count(for: category),
                            color: category.color
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 搜索结果
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Results", "搜尋結果"))
                .font(.system(size: 18, weight: .semibold))

            if viewModel.isSearching {
                ProgressView()
                    .padding(.vertical, 24)
            } else if viewModel.filteredResults.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text(L10n.tr("No matching result", "沒有符合的結果"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.filteredResults) { result in
                    Button(action: {
                        selectedResult = result
                    }) {
                        SearchResultCard(item: result)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SearchNavigationDestination) -> some View {
        switch destination {
        case .rent:
            RentListView()
        case .market:
            SecondhandListView()
        case .carpool:
            RideListView()
        case .groups:
            TeamListView()
        case .forum:
            ForumListView()
        }
    }
}

// MARK: - 搜索分类
enum SearchCategory: String, CaseIterable, Hashable {
    case all
    case rent
    case market
    case carpool
    case groups
    case forum

    var displayName: String {
        switch self {
        case .all: return L10n.tr("All", "全部")
        case .rent: return L10n.tr("Rent", "租房")
        case .market: return L10n.tr("Market", "二手")
        case .carpool: return L10n.tr("Carpool", "拼車")
        case .groups: return L10n.tr("Groups", "群組")
        case .forum: return L10n.tr("Forum", "論壇")
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .rent: return "key"
        case .market: return "bag"
        case .carpool: return "car"
        case .groups: return "person.2"
        case .forum: return "bubble.left"
        }
    }

    var color: Color {
        switch self {
        case .all: return .secondary
        case .rent: return AppColors.categoryColor(for: "rent")
        case .market: return AppColors.categoryColor(for: "market")
        case .carpool: return AppColors.categoryColor(for: "carpool")
        case .groups: return AppColors.categoryColor(for: "groups")
        case .forum: return AppColors.categoryColor(for: "forum")
        }
    }

    var navigationDestination: SearchNavigationDestination? {
        switch self {
        case .all: return nil
        case .rent: return .rent
        case .market: return .market
        case .carpool: return .carpool
        case .groups: return .groups
        case .forum: return .forum
        }
    }
}

enum SearchNavigationDestination: String, Identifiable {
    case rent
    case market
    case carpool
    case groups
    case forum

    var id: String { rawValue }
}

struct UnifiedSearchResult: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let category: SearchCategory
    let createdAt: Date?
    let searchableText: String
    let previewImageURL: String?
    let hotScore: Double
    let highlightType: PostHighlightType
    let highlightRank: Int

    var relativeTimeText: String {
        guard let createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    func relevanceScore(for query: String) -> Int {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let titleLowercased = title.lowercased()
        let searchableLowercased = searchableText.lowercased()

        if titleLowercased == normalizedQuery { return 100 }
        if titleLowercased.hasPrefix(normalizedQuery) { return 80 }
        if titleLowercased.contains(normalizedQuery) { return 60 }
        if searchableLowercased.contains(normalizedQuery) { return 40 }
        return 0
    }
}

// MARK: - 搜索结果详情路由
private struct SearchResultDetailRouter: View {
    let result: UnifiedSearchResult

    var body: some View {
        switch result.category {
        case .rent:
            SearchRentDetailLoaderView(postId: result.id)
        case .market:
            SearchSecondhandDetailLoaderView(postId: result.id)
        case .carpool:
            SearchRideDetailLoaderView(postId: result.id)
        case .groups:
            SearchTeamDetailLoaderView(postId: result.id)
        case .forum:
            SearchForumDetailLoaderView(postId: result.id)
        case .all:
            EmptyView()
        }
    }
}

private struct SearchRentDetailLoaderView: View {
    let postId: UUID
    @State private var post: RentPostItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let post {
                RentDetailView(post: post)
            } else {
                SearchDetailErrorView(message: errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let row: SearchRentDetailRow = try await SupabaseManager.shared
                .database("rent_posts_view")
                .select()
                .eq("id", value: postId.uuidString)
                .single()
                .execute()
                .value

            let reaction = await PostReactionService.shared.fetchStates(postIds: [row.id])[row.id]
            post = RentPostItem(
                id: row.id,
                title: row.title,
                price: row.price,
                location: row.location,
                specs: row.specs?.isEmpty == false
                    ? (row.specs ?? "")
                    : "\(max(row.bedrooms ?? 0, 0)) Bed • \(max(Int((row.bathrooms ?? 0).rounded()), 0)) Bath",
                propertyType: {
                    switch row.propertyType {
                    case "room": return .room
                    case "sublease": return .sublease
                    default: return .apartment
                    }
                }(),
                imageUrl: row.images?.first?.url,
                authorId: row.userId,
                authorName: row.userName ?? "Unknown",
                authorAvatar: row.userAvatar,
                distance: row.location,
                timeAgo: {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .abbreviated
                    return formatter.localizedString(for: row.createdAt, relativeTo: Date())
                }(),
                isFavorited: false,
                likeCount: reaction?.likeCount ?? 0,
                isLiked: reaction?.isLiked ?? false,
                highlightType: .normal,
                description: row.description ?? "",
                amenities: row.amenities ?? [],
                availableDate: Date(),
                bedrooms: row.bedrooms ?? 0,
                bathrooms: Int((row.bathrooms ?? 0).rounded())
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchForumDetailLoaderView: View {
    let postId: UUID
    @State private var post: ForumPostItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let post {
                ForumDetailView(post: post)
            } else {
                SearchDetailErrorView(message: errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            post = try await ForumService.shared.fetchPost(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchSecondhandDetailLoaderView: View {
    let postId: UUID
    @State private var item: SecondhandItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let item {
                SecondhandDetailView(item: item)
            } else {
                SearchDetailErrorView(message: errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            item = try await SecondhandService.shared.fetchItem(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchRideDetailLoaderView: View {
    let postId: UUID
    @State private var ride: RideItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let ride {
                RideDetailView(ride: ride)
            } else {
                SearchDetailErrorView(message: errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            ride = try await RideService.shared.fetchRide(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchTeamDetailLoaderView: View {
    let postId: UUID
    @State private var team: TeamItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let team {
                TeamDetailView(team: team)
            } else {
                SearchDetailErrorView(message: errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            team = try await TeamService.shared.fetchTeam(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchDetailErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}

// MARK: - 搜索视图模型
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var recentSearches: [String] = []
    @Published var trendingItems: [UnifiedSearchResult] = []
    @Published var hotByCategory: [SearchCategory: [UnifiedSearchResult]] = [:]
    @Published var categoryCounts: [SearchCategory: Int] = [:]
    @Published var filteredResults: [UnifiedSearchResult] = []
    @Published var isLoading = false
    @Published var isSearching = false

    private var allResults: [UnifiedSearchResult] = []
    private let recentSearchesKey = "search_recent_queries"
    private let supabase = SupabaseManager.shared

    init() {
        loadRecentSearches()
    }

    func loadInitialData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        async let rentResults = fetchRentResults()
        async let marketResults = fetchMarketResults()
        async let rideResults = fetchRideResults()
        async let teamResults = fetchTeamResults()
        async let forumResults = fetchForumResults()

        let rent = await rentResults
        let market = await marketResults
        let rides = await rideResults
        let teams = await teamResults
        let forum = await forumResults

        let mergedResults = rent + market + rides + teams + forum
        allResults = mergedResults.sorted { lhs, rhs in
            if lhs.highlightRank != rhs.highlightRank {
                return lhs.highlightRank < rhs.highlightRank
            }
            if lhs.hotScore != rhs.hotScore {
                return lhs.hotScore > rhs.hotScore
            }
            let lhsDate = lhs.createdAt ?? .distantPast
            let rhsDate = rhs.createdAt ?? .distantPast
            return lhsDate > rhsDate
        }

        categoryCounts = Dictionary(grouping: allResults, by: { $0.category })
            .mapValues { $0.count }

        hotByCategory = Dictionary(uniqueKeysWithValues: SearchCategory.allCases
            .filter { $0 != .all }
            .map { category in
                let top = mergedResults
                    .filter { $0.category == category }
                    .sorted {
                        if $0.highlightRank != $1.highlightRank {
                            return $0.highlightRank < $1.highlightRank
                        }
                        if $0.hotScore != $1.hotScore {
                            return $0.hotScore > $1.hotScore
                        }
                        return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                    }
                return (category, Array(top.prefix(10)))
            })

        trendingItems = Array(allResults.prefix(5))
    }

    func updateSearch(text: String, category: SearchCategory) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            filteredResults = []
            isSearching = false
            return
        }

        isSearching = true

        var results = allResults.filter {
            category == .all || $0.category == category
        }

        let tokens = query.lowercased().split(separator: " ").map(String.init)
        results = results.filter { item in
            let content = item.searchableText.lowercased()
            return tokens.allSatisfy { content.contains($0) }
        }

        filteredResults = results.sorted { lhs, rhs in
            let leftScore = lhs.relevanceScore(for: query)
            let rightScore = rhs.relevanceScore(for: query)

            if leftScore != rightScore {
                return leftScore > rightScore
            }

            let leftDate = lhs.createdAt ?? .distantPast
            let rightDate = rhs.createdAt ?? .distantPast
            return leftDate > rightDate
        }

        isSearching = false
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recentSearches.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        recentSearches.insert(trimmed, at: 0)

        if recentSearches.count > 8 {
            recentSearches = Array(recentSearches.prefix(8))
        }

        persistRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        persistRecentSearches()
    }

    func count(for category: SearchCategory) -> Int {
        categoryCounts[category] ?? 0
    }

    func hotPosts(for category: SearchCategory) -> [UnifiedSearchResult] {
        hotByCategory[category] ?? []
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func persistRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    private func fetchRentResults() async -> [UnifiedSearchResult] {
        do {
            let posts: [SearchRentPost] = try await supabase
                .database("rent_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(80)
                .execute()
                .value

            return posts.map {
                UnifiedSearchResult(
                    id: $0.id,
                    title: $0.title,
                    subtitle: "$\(Int($0.price))/mo · \($0.location)",
                    category: .rent,
                    createdAt: $0.createdAt,
                    searchableText: "\($0.title) \($0.location) rent housing",
                    previewImageURL: $0.images?.first?.url,
                    hotScore: $0.hotScore ?? 0,
                    highlightType: PostHighlightType(rawValue: $0.highlightType),
                    highlightRank: $0.highlightRank ?? 2
                )
            }
        } catch {
            if shouldIgnore(error) { return [] }
            print("❌ 搜索加载 rent 失败: \(error)")
            return []
        }
    }

    private func fetchMarketResults() async -> [UnifiedSearchResult] {
        do {
            let items: [SearchSecondhandPost] = try await supabase
                .database("secondhand_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(80)
                .execute()
                .value

            return items.map {
                UnifiedSearchResult(
                    id: $0.id,
                    title: $0.title,
                    subtitle: "$\(Int($0.price)) · \($0.condition)",
                    category: .market,
                    createdAt: $0.createdAt,
                    searchableText: "\($0.title) \($0.condition) market secondhand \($0.category)",
                    previewImageURL: $0.images?.first?.url,
                    hotScore: $0.hotScore ?? 0,
                    highlightType: PostHighlightType(rawValue: $0.highlightType),
                    highlightRank: $0.highlightRank ?? 2
                )
            }
        } catch {
            if shouldIgnore(error) { return [] }
            print("❌ 搜索加载 market 失败: \(error)")
            return []
        }
    }

    private func fetchRideResults() async -> [UnifiedSearchResult] {
        do {
            let rides: [SearchRidePost] = try await supabase
                .database("ride_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(80)
                .execute()
                .value

            return rides.map {
                let priceLabel: String
                if let pricePerSeat = $0.pricePerSeat, pricePerSeat > 0 {
                    priceLabel = "$\(Int(pricePerSeat))/seat"
                } else {
                    priceLabel = "Flexible"
                }

                return UnifiedSearchResult(
                    id: $0.id,
                    title: "\($0.departureLocation) → \($0.destinationLocation)",
                    subtitle: "\($0.role.capitalized) · \(priceLabel)",
                    category: .carpool,
                    createdAt: $0.createdAt,
                    searchableText: "\($0.departureLocation) \($0.destinationLocation) \($0.role) carpool ride",
                    previewImageURL: nil,
                    hotScore: $0.hotScore ?? 0,
                    highlightType: PostHighlightType(rawValue: $0.highlightType),
                    highlightRank: $0.highlightRank ?? 2
                )
            }
        } catch {
            if shouldIgnore(error) { return [] }
            print("❌ 搜索加载 ride 失败: \(error)")
            return []
        }
    }

    private func fetchTeamResults() async -> [UnifiedSearchResult] {
        do {
            let teams: [SearchTeamPost] = try await supabase
                .database("team_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(80)
                .execute()
                .value

            return teams.map {
                let description = ($0.description ?? "Looking for teammates").trimmingCharacters(in: .whitespacesAndNewlines)
                let subtitle = description.isEmpty ? "Looking for teammates" : description

                return UnifiedSearchResult(
                    id: $0.id,
                    title: $0.title,
                    subtitle: subtitle,
                    category: .groups,
                    createdAt: $0.createdAt,
                    searchableText: "\($0.title) \(subtitle) groups team \(($0.skillsNeeded ?? []).joined(separator: " "))",
                    previewImageURL: $0.images?.first?.url,
                    hotScore: $0.hotScore ?? 0,
                    highlightType: PostHighlightType(rawValue: $0.highlightType),
                    highlightRank: $0.highlightRank ?? 2
                )
            }
        } catch {
            if shouldIgnore(error) { return [] }
            print("❌ 搜索加载 groups 失败: \(error)")
            return []
        }
    }

    private func fetchForumResults() async -> [UnifiedSearchResult] {
        do {
            let posts: [SearchForumPost] = try await supabase
                .database("forum_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(80)
                .execute()
                .value

            return posts.map {
                let description = ($0.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let commentCount = $0.commentCount ?? 0
                let fallback = commentCount > 0 ? "\(commentCount) comments" : "New discussion"
                let subtitle = description.isEmpty ? fallback : description

                return UnifiedSearchResult(
                    id: $0.id,
                    title: $0.title,
                    subtitle: subtitle,
                    category: .forum,
                    createdAt: $0.createdAt,
                    searchableText: "\($0.title) \(subtitle) forum \($0.category)",
                    previewImageURL: $0.images?.first?.url,
                    hotScore: $0.hotScore ?? 0,
                    highlightType: PostHighlightType(rawValue: $0.highlightType),
                    highlightRank: $0.highlightRank ?? 2
                )
            }
        } catch {
            if shouldIgnore(error) { return [] }
            print("❌ 搜索加载 forum 失败: \(error)")
            return []
        }
    }

    private func shouldIgnore(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

// MARK: - 查询数据模型
private struct SearchRentPost: Codable {
    let id: UUID
    let title: String
    let location: String
    let price: Double
    let createdAt: Date
    let hotScore: Double?
    let highlightType: String?
    let highlightRank: Int?
    let images: [SearchImageRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case location
        case price
        case createdAt = "created_at"
        case hotScore = "hot_score"
        case highlightType = "highlight_type"
        case highlightRank = "highlight_rank"
        case images
    }
}

private struct SearchSecondhandPost: Codable {
    let id: UUID
    let title: String
    let category: String
    let condition: String
    let price: Double
    let createdAt: Date
    let hotScore: Double?
    let highlightType: String?
    let highlightRank: Int?
    let images: [SearchImageRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case condition
        case price
        case createdAt = "created_at"
        case hotScore = "hot_score"
        case highlightType = "highlight_type"
        case highlightRank = "highlight_rank"
        case images
    }
}

private struct SearchRidePost: Codable {
    let id: UUID
    let departureLocation: String
    let destinationLocation: String
    let role: String
    let pricePerSeat: Double?
    let createdAt: Date?
    let hotScore: Double?
    let highlightType: String?
    let highlightRank: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case departureLocation = "departure_location"
        case destinationLocation = "destination_location"
        case role
        case pricePerSeat = "price_per_seat"
        case createdAt = "created_at"
        case hotScore = "hot_score"
        case highlightType = "highlight_type"
        case highlightRank = "highlight_rank"
    }
}

private struct SearchTeamPost: Codable {
    let id: UUID
    let title: String
    let description: String?
    let skillsNeeded: [String]?
    let createdAt: Date?
    let hotScore: Double?
    let highlightType: String?
    let highlightRank: Int?
    let images: [SearchImageRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case skillsNeeded = "skills_needed"
        case createdAt = "created_at"
        case hotScore = "hot_score"
        case highlightType = "highlight_type"
        case highlightRank = "highlight_rank"
        case images
    }
}

private struct SearchForumPost: Codable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let commentCount: Int?
    let createdAt: Date?
    let hotScore: Double?
    let highlightType: String?
    let highlightRank: Int?
    let images: [SearchImageRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case hotScore = "hot_score"
        case highlightType = "highlight_type"
        case highlightRank = "highlight_rank"
        case images
    }
}

private struct SearchRentDetailRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let propertyType: String
    let bedrooms: Int?
    let bathrooms: Double?
    let price: Double
    let specs: String?
    let location: String
    let amenities: [String]?
    let createdAt: Date
    let userName: String?
    let userAvatar: String?
    let images: [SearchImageRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case propertyType = "property_type"
        case bedrooms
        case bathrooms
        case price
        case specs
        case location
        case amenities
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case images
    }
}

private struct SearchImageRow: Codable {
    let url: String
}

// MARK: - 搜索分类胶囊
struct SearchCategoryPill: View {
    let category: SearchCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                Text(category.displayName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppColors.selectedBackground : AppColors.cardBackground)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - 热门榜文字行
struct TextHotRankRow: View {
    let rank: Int
    let item: UnifiedSearchResult

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(rank <= 3 ? AppColors.accentStrong : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("#\(item.category.displayName)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(item.category.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - 分类卡片
struct CategoryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text("\(count) posts")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 搜索结果卡片
struct SearchResultCard: View {
    let item: UnifiedSearchResult

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let previewImageURL = item.previewImageURL,
                   let url = URL(string: previewImageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(item.category.color.opacity(0.15))
                                .overlay {
                                    Image(systemName: item.category.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(item.category.color)
                                }
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.category.color.opacity(0.15))
                        .overlay {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(item.category.color)
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.category.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(item.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.category.color.opacity(0.12))
                    .cornerRadius(4)

                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !item.relativeTimeText.isEmpty {
                Text(item.relativeTimeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .postHighlightStyle(item.highlightType, cornerRadius: 14)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    SearchView()
}
