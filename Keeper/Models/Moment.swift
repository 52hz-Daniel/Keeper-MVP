import Foundation

// MARK: - Moment Model
// Captures precious parenting moments to gift back to parents at milestones
// Philosophy: "We keep the family's peace of mind" - and their happiest memories

struct Moment: Identifiable, Codable, Equatable {
    let id: UUID
    let familyId: UUID
    let type: MomentType
    let title: String
    let description: String
    let relatedLogId: UUID?
    let capturedAt: Date
    let milestone: Milestone?
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        type: MomentType,
        title: String,
        description: String,
        relatedLogId: UUID? = nil,
        capturedAt: Date = Date(),
        milestone: Milestone? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.familyId = familyId
        self.type = type
        self.title = title
        self.description = description
        self.relatedLogId = relatedLogId
        self.capturedAt = capturedAt
        self.milestone = milestone
        self.isFavorite = isFavorite
    }
}

// MARK: - Moment Types
enum MomentType: String, Codable, CaseIterable {
    case firstSmile = "first_smile"
    case firstWord = "first_word"
    case firstStep = "first_step"
    case sleepThrough = "sleep_through"
    case firstLaugh = "first_laugh"
    case firstSolid = "first_solid"
    case parentWin = "parent_win"         // "You got 6 hours of sleep!"
    case growthSpurt = "growth_spurt"
    case sweetNote = "sweet_note"         // Captured from voice logs
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .firstSmile: return "First Smile"
        case .firstWord: return "First Word"
        case .firstStep: return "First Steps"
        case .sleepThrough: return "Slept Through!"
        case .firstLaugh: return "First Laugh"
        case .firstSolid: return "First Solids"
        case .parentWin: return "Parent Win 🎉"
        case .growthSpurt: return "Growing Strong"
        case .sweetNote: return "Sweet Moment"
        case .milestone: return "Milestone"
        }
    }
    
    var icon: String {
        switch self {
        case .firstSmile: return "face.smiling"
        case .firstWord: return "text.bubble"
        case .firstStep: return "figure.walk"
        case .sleepThrough: return "moon.stars"
        case .firstLaugh: return "sparkles"
        case .firstSolid: return "fork.knife"
        case .parentWin: return "trophy"
        case .growthSpurt: return "chart.line.uptrend.xyaxis"
        case .sweetNote: return "heart.fill"
        case .milestone: return "star.fill"
        }
    }
    
    var celebrationMessage: String {
        switch self {
        case .firstSmile: return "A moment of pure joy 💛"
        case .firstWord: return "The start of so many conversations"
        case .firstStep: return "The world is now their playground"
        case .sleepThrough: return "You both earned this rest ✨"
        case .firstLaugh: return "The sweetest sound in the world"
        case .firstSolid: return "New adventures in taste!"
        case .parentWin: return "You're doing amazing things"
        case .growthSpurt: return "Getting bigger every day"
        case .sweetNote: return "A moment to treasure"
        case .milestone: return "Another step on the journey"
        }
    }
}

// MARK: - Milestone Model
struct Milestone: Codable, Equatable, Identifiable {
    let id: UUID
    let type: MilestoneType
    let achievedAt: Date
    let childAgeInDays: Int
    
    init(
        id: UUID = UUID(),
        type: MilestoneType,
        achievedAt: Date = Date(),
        childAgeInDays: Int
    ) {
        self.id = id
        self.type = type
        self.achievedAt = achievedAt
        self.childAgeInDays = childAgeInDays
    }
}

enum MilestoneType: String, Codable, CaseIterable {
    case oneWeek = "one_week"
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case nineMonths = "nine_months"
    case oneYear = "one_year"
    case eighteenMonths = "eighteen_months"
    case twoYears = "two_years"
    
    var displayName: String {
        switch self {
        case .oneWeek: return "One Week"
        case .oneMonth: return "One Month"
        case .threeMonths: return "Three Months"
        case .sixMonths: return "Six Months"
        case .nineMonths: return "Nine Months"
        case .oneYear: return "One Year"
        case .eighteenMonths: return "18 Months"
        case .twoYears: return "Two Years"
        }
    }
    
    var daysRequired: Int {
        switch self {
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .nineMonths: return 270
        case .oneYear: return 365
        case .eighteenMonths: return 548
        case .twoYears: return 730
        }
    }
    
    var celebrationTitle: String {
        switch self {
        case .oneWeek: return "Your First Week Together 🌟"
        case .oneMonth: return "One Month of Love 💛"
        case .threeMonths: return "Three Months Strong 💪"
        case .sixMonths: return "Half a Year of Wonder ✨"
        case .nineMonths: return "Nine Magical Months 🌙"
        case .oneYear: return "Happy First Birthday! 🎂"
        case .eighteenMonths: return "18 Months of Adventure 🎈"
        case .twoYears: return "The Wonderful Twos! 🎉"
        }
    }
    
    var giftMessage: String {
        switch self {
        case .oneWeek:
            return "You survived the first week! Here are some of your first moments together."
        case .oneMonth:
            return "One whole month! Here's a collection of the moments that made it special."
        case .threeMonths:
            return "Look how far you've come. Here's a look back at the first 90 days."
        case .sixMonths:
            return "Half a year of memories. Here are the moments you kept with Keeper."
        case .nineMonths:
            return "Nine months outside, just like nine months inside. Here's your journey."
        case .oneYear:
            return "A whole year of firsts! Here's your memory book from year one."
        case .eighteenMonths:
            return "From baby to toddler! Here are the moments that defined the journey."
        case .twoYears:
            return "Two years of love, laughter, and growth. Your story continues."
        }
    }
}

// MARK: - Memory Gift
// A collection of moments presented at milestones
struct MemoryGift: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let milestone: Milestone
    let moments: [Moment]
    let generatedAt: Date
    var hasBeenViewed: Bool
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        milestone: Milestone,
        moments: [Moment],
        generatedAt: Date = Date(),
        hasBeenViewed: Bool = false
    ) {
        self.id = id
        self.familyId = familyId
        self.milestone = milestone
        self.moments = moments
        self.generatedAt = generatedAt
        self.hasBeenViewed = hasBeenViewed
    }
}

