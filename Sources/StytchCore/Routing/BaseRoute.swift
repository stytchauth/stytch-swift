enum BaseRoute: RouteType {
    case biometrics(BiometricsRoute)
    case magicLinks(MagicLinksRoute)
    case oauth(OAuthRoute)
    case otps(OneTimePasscodesRoute)
    case passkeys(PasskeysRoute)
    case passwords(PasswordsRoute)
    case sessions(SessionsRoute)

    var path: Path {
        switch self {
        case let .biometrics(route):
            return "biometrics".appendingPath(route.path)
        case let .magicLinks(route):
            return "magic_links".appendingPath(route.path)
        case let .oauth(route):
            return "oauth".appendingPath(route.path)
        case let .otps(route):
            return "otps".appendingPath(route.path)
        case let .passkeys(route):
            return "webauthn".appendingPath(route.path)
        case let .passwords(route):
            return "passwords".appendingPath(route.path)
        case let .sessions(route):
            return "sessions".appendingPath(route.path)
        }
    }
}

// A reusable route meant to represent the stage (starting and completing) of a given task corresponding to a parent-route's task.
enum TaskStageRoute: String, RouteType {
    case start
    case complete = ""

    var path: Path { .init(rawValue: rawValue) }
}