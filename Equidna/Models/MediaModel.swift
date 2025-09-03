import CloudKit

struct Media {
    let id: CKRecord.ID
    var type: String
    var file: CKAsset?
    var createdAt: Date              // continua na struct para UI
    var sender: CKRecord.Reference
    var receiver: [CKRecord.Reference]

    init(id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
         type: String,
         file: CKAsset? = nil,
         createdAt: Date = Date(),
         sender: CKRecord.Reference,
         receiver: [CKRecord.Reference] = []) {
        self.id = id
        self.type = type
        self.file = file
        self.createdAt = createdAt
        self.sender = sender
        self.receiver = receiver
    }

    init?(record: CKRecord) {
        guard
            let type = record["type"] as? String,
            let sender = record["sender"] as? CKRecord.Reference
        else { return nil }

        self.id = record.recordID
        self.type = type
        self.file = record["file"] as? CKAsset
        self.createdAt = record["createdAt"] as? Date              // se você eventualmente criar o campo
            ?? record.creationDate                                  // ✅ usa system field
            ?? Date()
        self.sender = sender
        self.receiver = record["receiver"] as? [CKRecord.Reference] ?? []
    }

    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Media", recordID: id)
        record["type"] = type as CKRecordValue
        record["file"] = file
        // ❌ NÃO escreva `createdAt` se não tiver o campo no schema
        record["sender"] = sender
        record["receiver"] = receiver as CKRecordValue
        return record
    }
}
