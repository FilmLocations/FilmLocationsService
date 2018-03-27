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

HeliumLogger.use(.verbose)

// Create new router
let router = Router()
let cors = CORS(options: Options())
router.all(middleware: cors)

let database = try Database(env.get("MONGODB_CONNECTION_STRING") ?? "mongodb://localhost:27017/filmlocations")


// Check server connection
router.get("/") { request, response, next in
    
    if database.server.isConnected {
        response.send("Connected")
    } else {
        response.send("Not connected")
    }

    next()
}

router.get("/support") { request, response, next in
    defer { next() }

    let html = """
        <!DOCTYPE html>
        <html>
        <body style="background-color:#00BCD4FF;">

        <center>
        <p>For questions and support, <a href=\"mailto:jessica.thrasher@gmail.com\">email us!</a></p>
        </center>

        </body>
        </html>
        """
    
    response.send(html)
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
        Log.error("No locations found")
        response.status(.OK).send("No locations found")
        return
    }
    
    let sort: Sort = ["year": .descending,
                      "popularity": .descending]
    
    var locationJSONs:JSONArray = []
    
    for document in try locations.find(sortedBy: sort) {
        locationJSONs.append(document.makeExtendedJSON(typeSafe: true))
    }
    
    response.status(.OK).send(locationJSONs.serializedString())
}

// Liking
router.get("locations/:locationId/likes") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    
    let likes = database["likes"]
    
    let count = try likes.find("locationId" == ObjectId(locationId)).count()
    
    response.status(.OK).send(count.serializedString())
}

router.get("locations/:locationId/like/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let likes = database["likes"]
    
    guard (try likes.findOne("locationId" == ObjectId(locationId) && "userId" == userId) != nil) else {
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
    
    guard (try likes.findOne("locationId" == ObjectId(locationId) && "userId" == userId) == nil) else {
        response.status(.OK).send("Like already exists")
        return
    }
    
    do {
        try likes.insert(["locationId": ObjectId(locationId), "userId": userId, "date": Date()] as Document)
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
        try likes.remove(["locationId": ObjectId(locationId), "userId": userId])
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
    
    let count = try visits.find("locationId" == ObjectId(locationId)).count()
    
    response.status(.OK).send(count.serializedString())
}

router.get("locations/:locationId/visit/:userId") { request, response, next in
    defer { next() }
    
    guard let locationId = request.parameters["locationId"] else { return }
    guard let userId = request.parameters["userId"] else { return }
    
    let visits = database["visits"]
    
    guard (try visits.findOne("locationId" == ObjectId(locationId) && "userId" == userId) != nil) else {
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
    
    guard (try visits.findOne("locationId" == ObjectId(locationId) && "userId" == userId) == nil) else {
        response.status(.OK).send("Visit already exists")
        return
    }
    
    do {
        try visits.insert(["locationId": ObjectId(locationId), "userId": userId, "date": Date()] as Document)
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
        try visits.remove(["locationId": ObjectId(locationId), "userId": userId])
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}

// Images
router.post("/images", middleware: BodyParser())
router.post("/images") { request, response, next in
    defer { next() }
    
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .json(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    guard let locationId = try? ObjectId(body["locationId"].stringValue) else {
        try response.status(.badRequest).end()
        return
    }

    let image: Document = ["name" : body["name"].stringValue,
                 "locationId" : locationId,
                 "placeId" : body["placeId"].stringValue,
                 "userId": body["userId"].stringValue,
                 "description": body["description"].stringValue,
                 "date": Date()]
    
    let images = database["images"]
    
    do {
        try images.insert(image)
    } catch {
        response.status(.internalServerError)
    }
    
    response.status(.OK)
}

// Query by userId or locationId currently
router.get("/images") { request, response, next in
    defer { next() }
    
    let images = database["images"]
    var imageJSONs: JSONArray = []
    var query: Query? = nil
    
    if let userId = request.queryParameters["userId"] {
        query = "userId" == userId
    } else if let locationId = request.queryParameters["locationId"] {
        guard let objectId = try? ObjectId(locationId) else {
            try response.status(.badRequest).end()
            return
        }
        query = "locationId" == ObjectId(objectId)
    } else {
        try response.status(.badRequest).end()
    }
    
    for document in try images.find(query) {
        imageJSONs.append(document.makeExtendedJSON(typeSafe: true))
    }
    
    response.status(.OK).send(imageJSONs.serializedString())
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
