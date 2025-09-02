import Foundation
import CloudKit
import SwiftUI

// MARK: - Tipos / Modelos

public enum MediaType: String { case photo, video, audio, text }

public struct Friend: Identifiable, Hashable {
    public let id: CKRecord.ID
    public let name: String
    public var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
    public init(id: CKRecord.ID, name: String) { self.id = id; self.name = name }
}

public struct HistoryItem: Identifiable, Hashable {
    public let id: CKRecord.ID
    public let friend: Friend           // a “outra ponta”
    public let type: MediaType
    public let date: Date
    public let asset: CKAsset?
    public init(id: CKRecord.ID, friend: Friend, type: MediaType, date: Date, asset: CKAsset?) {
        self.id = id; self.friend = friend; self.type = type; self.date = date; self.asset = asset
    }
}

// MARK: - Filtro

public enum HistoryFilter: Equatable {
    case all
    case byFriend(CKRecord.ID)
    case meOnly                         // somente enviadas por mim
}

// MARK: - ViewModel

public final class HistoryViewModel: ObservableObject {
    private let db = CKContainer.default().publicCloudDatabase

    // IDs para identificar "eu"
    private(set) var meUserID: CKRecord.ID?
    private(set) var meSystemRecordID: CKRecord.ID?   // opcional (não usado nas queries de Media)

    // UI
    @Published public var friends: [Friend] = []
    @Published public var items: [HistoryItem] = []
    @Published public var unread: Set<CKRecord.ID> = []           // apenas RECEBIDAS não vistas
    @Published public var isLoading = false
    @Published public var error: String?
    @Published public var filter: HistoryFilter = .all             // << NOVO

    public init() { print("[HistoryVM] init") }
    deinit { print("[HistoryVM] deinit") }

    // Lista local (já vem pré-filtrada pelas queries, mas deixo aqui por segurança)
    public var filteredItems: [HistoryItem] { items }

    // MARK: - API

    public func load(meUserID: CKRecord.ID, meSystemRecordID: CKRecord.ID? = nil) {
        self.meUserID = meUserID
        self.meSystemRecordID = meSystemRecordID
        print("[HistoryVM] load meUserID=\(meUserID.recordName), meSystemRecordID=\(meSystemRecordID?.recordName ?? "nil")")
        fetchPhotos()
    }

    public func setFilter(_ new: HistoryFilter) {
        print("[HistoryVM] setFilter -> \(new)")
        self.filter = new
        fetchPhotos()
    }

    public func refresh() {
        print("[HistoryVM] refresh() filter=\(filter)")
        fetchPhotos()
    }

    public func markSeen(mediaID: CKRecord.ID) {
        // só faz sentido para RECEBIDAS; não atrapalha se chamada em enviadas
        guard let me = meUserID ?? meSystemRecordID else {
            print("[HistoryVM] markSeen abortado: nenhum ID do eu")
            return
        }
        print("[HistoryVM] markSeen(mediaID: \(mediaID.recordName)) para me=\(me.recordName)")
        let meRef = CKRecord.Reference(recordID: me, action: .none)
        let mediaRef = CKRecord.Reference(recordID: mediaID, action: .none)

        let p = NSPredicate(format: "User == %@ AND Media == %@", meRef, mediaRef)
        let q = CKQuery(recordType: "MediaStatus", predicate: p)
        db.perform(q, inZoneWith: nil) { [weak self] results, err in
            if let err = err { print("[HistoryVM] markSeen query erro:", err.localizedDescription) }
            if let rec = results?.first {
                rec["status"] = "seen" as CKRecordValue
                rec["seenAt"] = Date() as CKRecordValue
                self?.db.save(rec) { _, e in
                    if let e = e { print("[HistoryVM] markSeen save existente erro:", e.localizedDescription) }
                }
            } else {
                let rec = CKRecord(recordType: "MediaStatus")
                rec["User"] = meRef
                rec["Media"] = mediaRef
                rec["status"] = "seen" as CKRecordValue
                rec["seenAt"] = Date() as CKRecordValue
                self?.db.save(rec) { _, e in
                    if let e = e { print("[HistoryVM] markSeen save novo erro:", e.localizedDescription) }
                }
            }
            DispatchQueue.main.async { self?.unread.remove(mediaID) }
        }
    }

    // MARK: - CloudKit

    private func fetchPhotos() {
        isLoading = true; error = nil
        let group = DispatchGroup()
        var allRecords: [CKRecord] = []

        guard let me = meUserID else {
            print("[HistoryVM] fetchPhotos abortado: meUserID == nil")
            isLoading = false
            return
        }

        // RECEBIDAS
        func queryReceived(friendFilter: CKRecord.ID?) {
            let meRef = CKRecord.Reference(recordID: me, action: .none)
            let type = "photo"
            let predicate: NSPredicate
            if let fID = friendFilter {
                let fRef = CKRecord.Reference(recordID: fID, action: .none)
                predicate = NSPredicate(format: "type == %@ AND ANY receiver == %@ AND sender == %@", type, meRef, fRef)
                print("[HistoryVM] fetch RECEBIDAS (friend \(fID.recordName))")
            } else {
                predicate = NSPredicate(format: "type == %@ AND ANY receiver == %@", type, meRef)
                print("[HistoryVM] fetch RECEBIDAS (todas)")
            }
            let q = CKQuery(recordType: "Media", predicate: predicate)
            q.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            group.enter()
            let op = CKQueryOperation(query: q)
            op.resultsLimit = 100
            op.recordMatchedBlock = { _, res in if case .success(let rec) = res { allRecords.append(rec) } }
            op.queryResultBlock = { _ in group.leave() }
            db.add(op)
        }

        // ENVIADAS
        func querySent(friendFilter: CKRecord.ID?) {
            let meRef = CKRecord.Reference(recordID: me, action: .none)
            let type = "photo"
            let predicate: NSPredicate
            if let fID = friendFilter {
                let fRef = CKRecord.Reference(recordID: fID, action: .none)
                predicate = NSPredicate(format: "type == %@ AND sender == %@ AND ANY receiver == %@", type, meRef, fRef)
                print("[HistoryVM] fetch ENVIADAS (friend \(fID.recordName))")
            } else {
                predicate = NSPredicate(format: "type == %@ AND sender == %@", type, meRef)
                print("[HistoryVM] fetch ENVIADAS (todas)")
            }
            let q = CKQuery(recordType: "Media", predicate: predicate)
            q.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            group.enter()
            let op = CKQueryOperation(query: q)
            op.resultsLimit = 100
            op.recordMatchedBlock = { _, res in if case .success(let rec) = res { allRecords.append(rec) } }
            op.queryResultBlock = { _ in group.leave() }
            db.add(op)
        }

        switch filter {
        case .all:
            queryReceived(friendFilter: nil)
            querySent(friendFilter: nil)
        case .byFriend(let fid):
            queryReceived(friendFilter: fid)
            querySent(friendFilter: fid)
        case .meOnly:
            querySent(friendFilter: nil)        // apenas enviadas
        }

        group.notify(queue: .main) {
            // únicos + ordenação
            let unique = Dictionary(grouping: allRecords, by: { $0.recordID }).compactMap { $0.value.first }
            func recDate(_ r: CKRecord) -> Date { r.creationDate ?? (r["createdAt"] as? Date) ?? r.modificationDate ?? .distantPast }
            let sorted = unique.sorted { recDate($0) > recDate($1) }
            self.buildOutput(from: sorted)
        }
    }

    private func buildOutput(from records: [CKRecord]) {
        print("[HistoryVM] buildOutput(records: \(records.count))")

        // a outra ponta (friendID) para cada record
        let myID = meUserID
        let friendIDs: [CKRecord.ID] = records.compactMap { rec in
            let senderID = (rec["sender"] as? CKRecord.Reference)?.recordID
            let receivers = (rec["receiver"] as? [CKRecord.Reference])?.map { $0.recordID } ?? []
            if let me = myID, senderID == me {
                return receivers.first     // eu enviei -> amigo = primeiro receiver
            } else {
                return senderID            // eu recebi -> amigo = sender
            }
        }
        let uniqueFriendIDs = Array(Set(friendIDs))

        fetchUsers(ids: uniqueFriendIDs) { [weak self] users in
            guard let self else { return }

            let built: [HistoryItem] = records.compactMap { rec in
                guard let typeStr = rec["type"] as? String else { return nil }
                let senderID = (rec["sender"] as? CKRecord.Reference)?.recordID
                let receivers = (rec["receiver"] as? [CKRecord.Reference])?.map { $0.recordID } ?? []

                let friendID: CKRecord.ID? = {
                    if let me = myID, senderID == me { return receivers.first }
                    else { return senderID }
                }()
                guard let fid = friendID else { return nil }

                let friend = users[fid] ?? Friend(id: fid, name: "Amigo")
                let mediaType = MediaType(rawValue: typeStr) ?? .photo
                let date = rec.creationDate ?? (rec["createdAt"] as? Date) ?? rec.modificationDate ?? Date()

                return HistoryItem(
                    id: rec.recordID,
                    friend: friend,
                    type: mediaType,
                    date: date,
                    asset: rec["file"] as? CKAsset
                )
            }

            self.items = built
            self.friends = users.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            // “Não lidos” só para RECEBIDAS (ignore quando for meOnly)
            if case .meOnly = self.filter {
                self.unread = []
            } else if let me = self.meUserID {
                let receivedIDs: [CKRecord.ID] = records.compactMap { rec in
                    let receivers = (rec["receiver"] as? [CKRecord.Reference])?.map { $0.recordID } ?? []
                    return receivers.contains(me) ? rec.recordID : nil
                }
                self.fetchStatuses(for: receivedIDs)
            } else {
                self.unread = []
            }

            self.isLoading = false
        }
    }

    private func fetchUsers(ids: [CKRecord.ID], completion: @escaping ([CKRecord.ID: Friend]) -> Void) {
        guard !ids.isEmpty else { completion([:]); return }
        let op = CKFetchRecordsOperation(recordIDs: ids)
        var out: [CKRecord.ID: Friend] = [:]
        op.perRecordResultBlock = { id, res in
            if case .success(let rec) = res, rec.recordType == "User" {
                let name = rec["fullName"] as? String ?? "Amigo"
                out[id] = Friend(id: id, name: name)
            }
        }
        op.fetchRecordsResultBlock = { _ in DispatchQueue.main.async { completion(out) } }
        db.add(op)
    }

    private func fetchStatuses(for mediaIDs: [CKRecord.ID]) {
        guard let me = meUserID, !mediaIDs.isEmpty else { self.unread = []; return }
        let meRef = CKRecord.Reference(recordID: me, action: .none)
        let refs = mediaIDs.map { CKRecord.Reference(recordID: $0, action: .none) }
        let p = NSPredicate(format: "User == %@ AND Media IN %@", meRef, refs)
        let q = CKQuery(recordType: "MediaStatus", predicate: p)

        var seen = Set<CKRecord.ID>()
        let op = CKQueryOperation(query: q)
        op.recordMatchedBlock = { _, res in
            if case .success(let rec) = res,
               (rec["status"] as? String)?.lowercased() == "seen",
               let m = rec["Media"] as? CKRecord.Reference {
                seen.insert(m.recordID)
            }
        }
        op.queryResultBlock = { [weak self] _ in
            let unreadSet = Set(mediaIDs).subtracting(seen)
            DispatchQueue.main.async { self?.unread = unreadSet }
        }
        db.add(op)
    }
}
