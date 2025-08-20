import CloudKit

struct MediaStatus {
    let id: CKRecord.ID
    var media: CKRecord.Reference
    var user: CKRecord.Reference
    var status: String
    var seenAt: Date?
    
    init(id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
         media: CKRecord.Reference,
         user: CKRecord.Reference,
         status: String,
         seenAt: Date? = nil) {
        self.id = id
        self.media = media
        self.user = user
        self.status = status
        self.seenAt = seenAt
    }
    
    init?(record: CKRecord) {
        guard let media = record["Media"] as? CKRecord.Reference,
              let user = record["User"] as? CKRecord.Reference,
              let status = record["status"] as? String else {
            return nil
        }
        
        self.id = record.recordID
        self.media = media
        self.user = user
        self.status = status
        self.seenAt = record["seenAt"] as? Date
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "MediaStatus", recordID: id)
        record["Media"] = media
        record["User"] = user
        record["status"] = status as CKRecordValue
        record["seenAt"] = seenAt as CKRecordValue?
        return record
    }
}
