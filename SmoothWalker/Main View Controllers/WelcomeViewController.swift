/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that onboards users to the app.
*/



import UIKit
import HealthKit

class WelcomeViewController: SplashScreenViewController, SplashScreenViewControllerDelegate, UITextFieldDelegate {


    let healthStore = HealthData.healthStore
    var userEmail:String!
    var firstName:String!
    var lastName:String!
    
    /// The HealthKit data types we will request to read.
    let readTypes = Set(HealthData.readDataTypes)
    /// The HealthKit data types we will request to share and have write access.
    let shareTypes = Set(HealthData.shareDataTypes)
    
    var hasRequestedHealthData: Bool = false
    
    // MARK: - View Life Cycle
    let emailTextField =  UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
    let firstNameTextField = UITextField(frame: CGRect(x: 20, y: 150, width: 300, height: 40))
    let lastNameTextField = UITextField(frame: CGRect(x: 20, y: 200, width: 300, height: 40))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = tabBarItem.title
        view.backgroundColor = .systemBackground
        splashScreenDelegate = self
        actionButton.setTitle("Authorize HealthKit Access", for: .normal)
        
       
       emailTextField.placeholder = "Enter email here"
       emailTextField.font = UIFont.systemFont(ofSize: 20)
       emailTextField.borderStyle = UITextField.BorderStyle.roundedRect
       emailTextField.autocorrectionType = UITextAutocorrectionType.no
       emailTextField.keyboardType = UIKeyboardType.default
       emailTextField.returnKeyType = UIReturnKeyType.done
       emailTextField.clearButtonMode = UITextField.ViewMode.whileEditing
       emailTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
       self.view.addSubview(emailTextField)
        
        firstNameTextField.placeholder = "Enter First Name here"
        firstNameTextField.font = UIFont.systemFont(ofSize: 20)
        firstNameTextField.borderStyle = UITextField.BorderStyle.roundedRect
        firstNameTextField.autocorrectionType = UITextAutocorrectionType.no
        firstNameTextField.keyboardType = UIKeyboardType.default
        firstNameTextField.returnKeyType = UIReturnKeyType.done
        firstNameTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        firstNameTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.view.addSubview(firstNameTextField)
        
        lastNameTextField.placeholder = "Enter Last Name here"
        lastNameTextField.font = UIFont.systemFont(ofSize: 20)
        lastNameTextField.borderStyle = UITextField.BorderStyle.roundedRect
        lastNameTextField.autocorrectionType = UITextAutocorrectionType.no
        lastNameTextField.keyboardType = UIKeyboardType.default
        lastNameTextField.returnKeyType = UIReturnKeyType.done
        lastNameTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        lastNameTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.view.addSubview(lastNameTextField)
        
    
        let myFirstButton = UIButton()
        myFirstButton.setTitle("SAVE", for: .normal)
        myFirstButton.setTitleColor(.blue, for: .normal)
        myFirstButton.frame = CGRect(x: 15, y: 250, width: 300, height: 40)
        myFirstButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        self.view.addSubview(myFirstButton)
        
        
        getHealthAuthorizationRequestStatus()
    }
    
    @objc func pressed() {
        print("Pressed")
        userEmail = emailTextField.text!
        firstName = firstNameTextField.text!
        lastName = lastNameTextField.text!
       // print(userEmail)
        // Call api
       // let data =  ServerResponse(from: Decoder.self as! Decoder).weeklyReport
        //print(type(of: data))
        //apiCall(firstName: firstName, lastName: lastName, email: userEmail, HealthData: <#T##[String : AnyHashable]#>)
        let pathName = "MockServerResponse"
        let file = Bundle.main.url(forResource: pathName, withExtension: "json")
        let data = try? Data(contentsOf: file!)
        let decoder = JSONDecoder()
        let serverResponse = try? decoder.decode(ServerResponse.self, from: data!)
        var healthData: [HealthDataTypeValue] = []
        WeeklyQuantitySampleTableViewController.sendAPI(firstName: firstName, lastName: lastName, email: userEmail)
        
   
        

    }
    func getHealthAuthorizationRequestStatus() {
        print("Checking HealthKit authorization status...")
        
        if !HKHealthStore.isHealthDataAvailable() {
            presentHealthDataNotAvailableError()
            
            return
        }
        
        healthStore.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { (authorizationRequestStatus, error) in
            
            var status: String = ""
            if let error = error {
                status = "HealthKit Authorization Error: \(error.localizedDescription)"
            } else {
                switch authorizationRequestStatus {
                case .shouldRequest:
                    self.hasRequestedHealthData = false
                    
                    status = "The application has not yet requested authorization for all of the specified data types."
                case .unknown:
                    status = "The authorization request status could not be determined because an error occurred."
                case .unnecessary:
                    self.hasRequestedHealthData = true
                    
                    status = "The application has already requested authorization for the specified data types. "
                    status += self.createAuthorizationStatusDescription(for: self.shareTypes)
                default:
                    break
                }
            }
            
            print(status)
            
            // Results come back on a background thread. Dispatch UI updates to the main thread.
            DispatchQueue.main.async {
                self.descriptionLabel.text = status
            }
        }
    }
    
    // MARK: - SplashScreenViewController Delegate
    
    func didSelectActionButton() {
        requestHealthAuthorization()
    }
    
    
    func apiCall(firstName:String, lastName: String, email:String, HealthData:[String:AnyHashable]){
            guard let url = URL(string: "https://magicmirrorhealth-developer-edition.na163.force.com/services/apexrest/postHealth?firstname=\(firstName)&lastname=\(lastName)&email=\(email)")else{
                return
            }
       
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String:AnyHashable] = HealthData//TODO ADD HEALTH DATA
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        
        let task = URLSession.shared.dataTask(with: request){data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do{
                let responce = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("success")
            }catch{
                print(error)
            }
        }
        task.resume()
        }
    
    
    func requestHealthAuthorization() {
        print("Requesting HealthKit authorization...")
        
        if !HKHealthStore.isHealthDataAvailable() {
            presentHealthDataNotAvailableError()
            
            return
        }
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            var status: String = ""
            
            if let error = error {
                status = "HealthKit Authorization Error: \(error.localizedDescription)"
            } else {
                if success {
                    if self.hasRequestedHealthData {
                        status = "You've already requested access to health data. "
                    } else {
                        status = "HealthKit authorization request was successful! "
                    }
                    
                    status += self.createAuthorizationStatusDescription(for: self.shareTypes)
                    
                    self.hasRequestedHealthData = true
                } else {
                    status = "HealthKit authorization did not complete successfully."
                }
            }
            
            print(status)
            
            // Results come back on a background thread. Dispatch UI updates to the main thread.
            DispatchQueue.main.async {
                self.descriptionLabel.text = status
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func createAuthorizationStatusDescription(for types: Set<HKObjectType>) -> String {
        var dictionary = [HKAuthorizationStatus: Int]()
        
        for type in types {
            let status = healthStore.authorizationStatus(for: type)
            
            if let existingValue = dictionary[status] {
                dictionary[status] = existingValue + 1
            } else {
                dictionary[status] = 1
            }
        }
        
        var descriptionArray: [String] = []
        
        if let numberOfAuthorizedTypes = dictionary[.sharingAuthorized] {
            let format = NSLocalizedString("AUTHORIZED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfAuthorizedTypes])
            
            descriptionArray.append(formattedString)
        }
        if let numberOfDeniedTypes = dictionary[.sharingDenied] {
            let format = NSLocalizedString("DENIED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfDeniedTypes])
            
            descriptionArray.append(formattedString)
        }
        if let numberOfUndeterminedTypes = dictionary[.notDetermined] {
            let format = NSLocalizedString("UNDETERMINED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfUndeterminedTypes])
            
            descriptionArray.append(formattedString)
        }
        
        // Format the sentence for grammar if there are multiple clauses.
        if let lastDescription = descriptionArray.last, descriptionArray.count > 1 {
            descriptionArray[descriptionArray.count - 1] = "and \(lastDescription)"
        }
        
        let description = "Sharing is " + descriptionArray.joined(separator: ", ") + "."
        
        return description
    }
    
    private func presentHealthDataNotAvailableError() {
        let title = "Health Data Unavailable"
        let message = "Aw, shucks! We are unable to access health data on this device. Make sure you are using device with HealthKit capabilities."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        
        alertController.addAction(action)
        
        present(alertController, animated: true)
    }
}
