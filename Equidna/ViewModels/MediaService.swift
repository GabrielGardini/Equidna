//
//  MediaService.swift
//  EquidnaApp
//
//  Created by Camille Fernandes Luppi on 01/09/25.
//
import CloudKit
import Foundation

class MediaService {
    private let database = CKContainer.default().publicCloudDatabase

    // Salva um objeto Media
    func save(media: Media) async throws -> CKRecord {
        let record = media.toRecord()
        return try await database.save(record)
    }

    // Salva um objeto MediaStatus
    func save(status: MediaStatus) async throws -> CKRecord {
        let record = status.toRecord()
        return try await database.save(record)
    }


    func fetchHistory(for userRef: CKRecord.Reference) async throws -> [Media] {
        let sentPredicate = NSPredicate(format: "sender == %@", userRef)
        let receivedPredicate = NSPredicate(format: "%@ IN receiver", userRef)
            
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [sentPredicate, receivedPredicate])
            
        let query = CKQuery(recordType: "Media", predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
        let (results, _) = try await database.records(matching: query)
            
        let mediaItems = results.compactMap { (_, result) -> Media? in
                guard let record = try? result.get() else { return nil }
                return Media(record: record)
        }
            
        return mediaItems
    }
}
