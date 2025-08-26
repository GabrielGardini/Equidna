import CloudKit

struct User {
    let id: CKRecord.ID
    var fullName: String
    let userID: String
    var predefinedMessages: [String]
    var profilePhoto: CKAsset?
    var inviteCode: String
    var friends: [CKRecord.Reference]
    var streak: Int
    var userRef: CKRecord.Reference?

    init(id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
         fullName: String,
         userID: String,
         profilePhoto: CKAsset? = nil,
         inviteCode: String,
         friends: [CKRecord.Reference] = [],
         streak: Int = 0,
         predefinedMessages: [String] = [],
         userRef: CKRecord.Reference? = nil) {
        self.id = id
        self.fullName = fullName
        self.userID = userID
        self.predefinedMessages = predefinedMessages
        self.profilePhoto = profilePhoto
        self.inviteCode = inviteCode
        self.friends = friends
        self.streak = streak
        self.userRef = userRef
    }

    init?(record: CKRecord) {
        guard let fullName = record["fullName"] as? String,
              let userID = record["userID"] as? String,
              let inviteCode = record["inviteCode"] as? String,
              let streak = record["streak"] as? Int else { return nil }

        self.id = record.recordID
        self.fullName = fullName
        self.userID = userID
        self.profilePhoto = record["profilePhoto"] as? CKAsset
        self.inviteCode = inviteCode
        self.friends = record["friends"] as? [CKRecord.Reference] ?? []
        self.streak = streak
        self.predefinedMessages = record["predefinedMessages"] as? [String] ?? []
        self.userRef = record["userRef"] as? CKRecord.Reference
    }

    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "User", recordID: id)
        record["fullName"] = fullName as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["inviteCode"] = inviteCode as CKRecordValue
        record["streak"] = streak as CKRecordValue
        if let profilePhoto { record["profilePhoto"] = profilePhoto }
        if let userRef { record["userRef"] = userRef as CKRecordValue }
        if !friends.isEmpty { record["friends"] = friends as CKRecordValue }
        if !predefinedMessages.isEmpty { record["predefinedMessages"] = predefinedMessages as CKRecordValue }
        return record
    }
}
