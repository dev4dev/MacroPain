import Example
import ComposableArchitecture

// MARK: - Error: Property wrapper cannot be applied to a computed property
//@Reducer
//struct ChildFeature {
//
//}
//
//@Reducer
//struct Feature {
//    @ObservableState
//    struct State {
//        @SomePropertyWrapper
//        var childState: ChildFeature.State?
//    }
//
//    enum Action {
//        case childStaet(ChildFeature.Action)
//    }
//}

// MARK: - Error: Invalid redeclaration of '_childState'
//@Reducer
//struct ChildFeature {
//
//}
//
//@Reducer
//struct Feature {
//    @ObservableState
//    struct State {
//        @Test
//        var childState: ChildFeature.State?
//    }
//
//    enum Action {
//        case childStaet(ChildFeature.Action)
//    }
//}

// MARK: - Error: Expansion of macro 'ObservationStateIgnored()' produced an unexpected 'init' accessor
//@Reducer
//struct ChildFeature {
//
//}
//
//@Reducer
//struct Feature {
//    @ObservableState
//    struct State {
//        @ObservationStateIgnored
//        @Test
//        var childState: ChildFeature.State?
//    }
//
//    enum Action {
//        case childStaet(ChildFeature.Action)
//    }
//}

// MARK: - Nice
@Reducer
struct ChildFeature {

}

@Reducer
struct Feature {
    @ObservableState(ignore: "Test")
    struct State {
        @Test
        var childState: ChildFeature.State?
    }

    enum Action {
        case childStaet(ChildFeature.Action)
    }
}
