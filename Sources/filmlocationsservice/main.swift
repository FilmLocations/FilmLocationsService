import Foundation
import Kitura
import KituraCORS
import MongoKitten
import Cheetah
import ExtendedJSON
import HeliumLogger
import LoggerAPI
import DotEnv

let env = DotEnv(withFile: ".env")

HeliumLogger.use()

let logger = HeliumLogger(.verbose)
Log.logger = logger

// Create new router
let router = Router()
let cors = CORS(options: Options())
router.all(middleware: cors)

let database = try Database(env.get("MONGODB_CONNECTION_STRING")!)

// Check server connection
router.get("/") { request, response, next in
    
    if database.server.isConnected {
        response.send("Connected")
    } else {
        response.send("Not connected")
    }

    next()
}

router.get("/test") { request, response, next in
    defer { next() }
    
    if database.server.isConnected {
        print("we're connected")
    }
    
    let dbs = try? database.server.getDatabases()
    
    if let dbs = dbs {
        for item in dbs {
            print("db \(item)")
        }
    }
    
    let cursor = try? database.listCollections()
    
    if let cursor = cursor {
        for item in cursor {
            print ("Item \(item)")
        }
    }
    
    response.send("Testing path")
}

// Currently takes no parameters - returns all locations available
router.get("/locations") { request, response, next in
    defer { next() }
    
    let locations = database["locations"]
    
    guard try locations.findOne() != nil else {
        print("not found")
        response.status(.OK).send("No locations")
        return
    }
    
    var locationJSONs:JSONArray = []
    
    for document in try locations.find() {
        locationJSONs.append(document.makeExtendedJSON(typeSafe: true))
    }
    
    //let string = location.makeExtendedJSON(typeSafe: true).serializedString()
    response.status(.OK).send(locationJSONs.serializedString())
}

// Liking
router.get("locations/:locationId/likes") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    
    let likes = database["likes"]
    
    let count = try likes.find("locationId" == locationId).count()
    
    response.status(.OK).send(count.serializedString())
}

router.get("locations/:locationId/like/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let likes = database["likes"]
    
    guard (try likes.findOne("locationId" == locationId && "userId" == userId) != nil) else {
        response.status(.OK).send("false")
        return
    }
    
    response.status(.OK).send("true")
}

router.post("locations/:locationId/like/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let likes = database["likes"]
    
    do {
        try likes.insert(["locationId": locationId, "userId": userId] as Document)
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}

router.delete("locations/:locationId/like/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let likes = database["likes"]
    
    do {
        try likes.remove(["locationId": locationId, "userId": userId])
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}

// Users
router.get("users/:userId/likes") { request, response, next in
    defer { next() }
    
    guard let userId = request.parameters["userId"] else { return }

    let likes = database["likes"]
    
    let count = try likes.find("userId" == userId).count()
    
    response.status(.OK).send(count.serializedString())
}

router.get("users/:userId/visits") { request, response, next in
    defer { next() }
    
    guard let userId = request.parameters["userId"] else { return }

    let visits = database["visits"]
    
    let count = try visits.find("userId" == userId).count()
    
    response.status(.OK).send(count.serializedString())
}

// Visiting
router.get("locations/:locationId/visits") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    
    let visits = database["visits"]
    
    let count = try visits.find("locationId" == locationId).count()
    
    response.status(.OK).send(count.serializedString())
}

router.get("locations/:locationId/visit/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let visits = database["visits"]
    
    guard (try visits.findOne("locationId" == locationId && "userId" == userId) != nil) else {
        response.status(.OK).send("false")
        return
    }
    
    response.status(.OK).send("true")
}

router.post("locations/:locationId/visit/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let visits = database["visits"]
    
    do {
        try visits.insert(["locationId": locationId, "userId": userId] as Document)
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}

router.delete("locations/:locationId/visit/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let visits = database["visits"]
    
    do {
        try visits.remove(["locationId": locationId, "userId": userId])
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}


// Resolve the port that we want the server to listen on.
let port: Int
let defaultPort = 8088
if let requestedPort = ProcessInfo.processInfo.environment["PORT"] {
    port = Int(requestedPort) ?? defaultPort
} else {
    port = defaultPort
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: port, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
