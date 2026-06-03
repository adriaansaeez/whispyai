enum DictationState: Equatable {
    case idle
    case listening
    case transcribing
    case rewriting
    case inserting
    case completed
    case failed(WhispyError)
}
