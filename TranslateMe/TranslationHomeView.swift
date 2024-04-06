//
//  TranslationHomeView.swift
//  TranslateMe
//
//  Created by Bender on 4/4/24.
//

import Foundation
import Firebase
import SwiftUI
import FirebaseFirestore

struct TranslationMeHomeView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var translationHistory: [String] = []
    
    init() {
        fetchTranslationHistory()
    }
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter text to translate", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: translateAndSave) {
                    Text("Translate")
                        .foregroundColor(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }
                
                Text(translatedText)
                    .padding()
                
                Divider()
                
                Text("Translation History")
                    .font(.headline)
                
                List(translationHistory, id: \.self) { historyItem in
                    Text(historyItem)
                }
                
                Button("Clear History", action: clearTranslationHistory)
                    .foregroundColor(.red)
                    .padding()
            }
            .navigationBarTitle("TranslationMe", displayMode: .inline)
        }
    }
    
    func translateAndSave() {
        let sourceLang = "en"
        let targetLang = "es" // Example: Translating from English to Spanish
        let urlString = "https://api.mymemory.translated.net/get?q=\(inputText)&langpair=\(sourceLang)|\(targetLang)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let responseData = jsonResponse?["responseData"] as? [String: Any], let translatedText = responseData["translatedText"] as? String {
                    DispatchQueue.main.async {
                        self.translatedText = translatedText
                        self.updateTranslationHistory(translatedText: translatedText)
                    }
                }
                //To make sure it was translated
                print("Success in translating.")
            } catch {
                print("Error during JSON serialization: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func updateTranslationHistory(translatedText: String) {
        let db = Firestore.firestore()
        var history = translationHistory
        history.append(translatedText)
        self.translationHistory = history
        
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        ref = db.collection("translationHistory").addDocument(data: [
            "text": translatedText, // Store the translation text
            "timestamp": Timestamp(date: Date()) // Optionally store when the translation was added
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
                // Fetch the updated history to reflect the change
                self.fetchTranslationHistory()
            }
        }
        // Here, you'd actually save to Firestore, but we're simplifying for demonstration.
    }
    
    func fetchTranslationHistory() {
        let db = Firestore.firestore()
        
        db.collection("translationHistory").order(by: "timestamp", descending: true).getDocuments { (querySnapshot, err) in
            // Assuming your collection is named "translationHistory"
            db.collection("translationHistory").getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var fetchedTranslations: [String] = []
                    for document in querySnapshot!.documents {
                        // Assuming each document has a "text" field containing the translation
                        if let translation = document.data()["text"] as? String {
                            fetchedTranslations.append(translation)
                        }
                    }
                    DispatchQueue.main.async {
                        // Update your state variable to refresh the view
                        self.translationHistory = fetchedTranslations
                    }
                }
            }
               }
     
    }
    
    func clearTranslationHistory() {
        let db = Firestore.firestore()
        
        db.collection("translationHistory").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else {
                print("No documents to delete")
                return
            }
            for document in documents {
                db.collection("translationHistory").document(document.documentID).delete { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                    } else {
                        print("Document successfully removed!")
                    }
                }
            }
            // Update the UI
            DispatchQueue.main.async {
                self.translationHistory.removeAll()
            }
        }
    }
}
struct TranslationMeHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationMeHomeView()
    }
}


