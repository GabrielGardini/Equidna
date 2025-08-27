import CloudKit

struct Friendship {
    let id: CKRecord.ID
    let userA: CKRecord.Reference
    let userB: CKRecord.Reference
    let createdAt: Date

    init(id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
         userA: CKRecord.Reference,
         userB: CKRecord.Reference,
         createdAt: Date = Date()) {
        self.id = id
        self.userA = userA
        self.userB = userB
        self.createdAt = createdAt
    }

    init?(record: CKRecord) {
        guard let a = record["userA"] as? CKRecord.Reference,
              let b = record["userB"] as? CKRecord.Reference else { return nil }
        self.id = record.recordID
        self.userA = a
        self.userB = b
        self.createdAt = (record["createdAt"] as? Date) ?? Date.distantPast
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "Friendship", recordID: id)
        rec["userA"] = userA as CKRecordValue
        rec["userB"] = userB as CKRecordValue
        rec["createdAt"] = createdAt as CKRecordValue
        return rec
    }

    // MARK: - Helpers

    /// Gera um recordName determinístico a partir de dois CKRecord.ID de `User`,
    /// ordenando os dois nomes para que (A,B) e (B,A) gerem o mesmo ID.
    static func deterministicRecordName(for a: CKRecord.ID, and b: CKRecord.ID) -> String {
        let n1 = a.recordName
        let n2 = b.recordName
        let (lo, hi) = n1 < n2 ? (n1, n2) : (n2, n1)
        return "FRI-\(lo)-\(hi)"
    }
}
