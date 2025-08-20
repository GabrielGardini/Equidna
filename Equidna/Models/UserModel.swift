import CloudKit

struct User {
    let id: CKRecord.ID
    var fullName: String
    var profilePhoto: CKAsset?
    var inviteCode: String
    var friends: [CKRecord.Reference]
    var streak: Int
    
    init(id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
         fullName: String,
         profilePhoto: CKAsset? = nil,
         inviteCode: String,
         friends: [CKRecord.Reference] = [],
         streak: Int = 0) {
        self.id = id
        self.fullName = fullName
        self.profilePhoto = profilePhoto
        self.inviteCode = inviteCode
        self.friends = friends
        self.streak = streak
    }
    
    init?(record: CKRecord) {
        guard let fullName = record["fullName"] as? String,
              let inviteCode = record["inviteCode"] as? String,
              let streak = record["streak"] as? Int else {
            return nil
        }
        
        self.id = record.recordID
        self.fullName = fullName
        self.profilePhoto = record["profilePhoto"] as? CKAsset
        self.inviteCode = inviteCode
        self.friends = record["friends"] as? [CKRecord.Reference] ?? []
        self.streak = streak
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "User", recordID: id)
        record["fullName"] = fullName as CKRecordValue
        record["profilePhoto"] = profilePhoto
        record["inviteCode"] = inviteCode as CKRecordValue
        record["friends"] = friends as CKRecordValue
        record["streak"] = streak as CKRecordValue
        return record
    }
}
