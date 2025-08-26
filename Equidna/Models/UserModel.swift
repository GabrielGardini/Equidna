import CloudKit

struct User {
    let id: CKRecord.ID                 // ID do seu record "Users"
    var fullName: String
    let userID: String                  // pode manter como cache/visualização
    var predefinedMessages: [String]
    var profilePhoto: CKAsset?
    var inviteCode: String
    var friends: [CKRecord.Reference]
    var streak: Int
    var userRef: CKRecord.Reference?    // <- referência ao User Record (sistema)

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

        if let photo = profilePhoto { record["profilePhoto"] = photo }
        if let ref = userRef { record["userRef"] = ref as CKRecordValue }

        if !friends.isEmpty {
            record["friends"] = friends as CKRecordValue        // [CKRecord.Reference]
        }
        if !predefinedMessages.isEmpty {
            record["predefinedMessages"] = predefinedMessages as CKRecordValue  // [String]
        }
        return record
    }
}
