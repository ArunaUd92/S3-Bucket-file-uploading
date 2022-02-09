/*
 * Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import AWSS3

class UploadViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    
    @objc var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    @objc var progressBlock: AWSS3TransferUtilityProgressBlock?
    
    @objc let imagePickerController = UIImagePickerController()
    var videoURL:URL?
    
    @objc lazy var transferUtility = {
        AWSS3TransferUtility.default()
    }()
    
   // Pool Id us-east-1_WZQtWgUGR
   // Pool ARN arn:aws:cognito-idp:us-east-1:696532097594:userpool/us-east-1_WZQtWgUGR
    
  //  app client id - 2e2uctcq9aqdcl0fb7eds27mqr
 //  app client id Secret -  1ht0ob7cdv7oaklj1kc90crliv747md3fgv1hec68dcv65acpsdt
    
    let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast1
    let CognitoIdentityUserPoolId = "us-east-1:0c2b0d43-ec7f-4eec-b2bb-b0dfb6f4e84b"
    let CognitoIdentityUserPoolAppClientId = "2e2uctcq9aqdcl0fb7eds27mqr"
    let CognitoIdentityUserPoolAppClientSecret = "1ht0ob7cdv7oaklj1kc90crliv747md3fgv1hec68dcv65acpsdt"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //getFileRetrieved()
        
        self.progressView.progress = 0.0;
        self.statusLabel.text = "Ready"
        self.imagePickerController.delegate = self
        
        self.progressBlock = {(task, progress) in
            print("Progress: \(progress.fractionCompleted * 100)")
            DispatchQueue.main.async(execute: {
                if (self.progressView.progress < Float(progress.fractionCompleted)) {
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            })
        }
        
        self.completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    print("Failed with error: \(error)")
                    self.statusLabel.text = "Failed"
                }
                else if(self.progressView.progress != 1.0) {
                    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                }
                else{
                    self.statusLabel.text = "Success"
                }
            })
        }
    }
    
    @IBAction func selectAndUpload(_ sender: UIButton) {
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = ["public.movie"]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func uploadImage(with data: Data) {
        
//        let access = "AKIAUO5UV3YLNXK4BFH2"
//        let secret = "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"
//        let credentials = AWSStaticCredentialsProvider(accessKey: access, secretKey: secret)
//        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentials)
//        
//        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
//        let cognitoRegion = CognitoIdentityUserPoolRegion
//        let cognitoIdentityPoolId = CognitoIdentityUserPoolId
//        let tokens = ["cognito-idp.us-east-1.amazonaws.com/us-east-1_WZQtWgUGR" : ""]
//       // let tokens = ["" : ""]
//        let customIdentityProvider = CustomIdentityProvider(tokens: tokens)
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: cognitoRegion,
//                                                                identityPoolId: cognitoIdentityPoolId,
//                                                                identityProviderManager: customIdentityProvider)
//        let configuration = AWSServiceConfiguration(region: cognitoRegion,
//                                                    credentialsProvider: credentialsProvider)
//
//        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock
        
        DispatchQueue.main.async(execute: {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        })
        
       // let videoName = UUID().uuidString + "test1.mp4"
        
        let transferUtility11 = AWSS3TransferUtility.default()
        transferUtility11.uploadData(
            data,
            bucket: "ios-bucket-test", //
            key: S3UploadKeyName, //S3UploadKeyName
            contentType: "video/mp4",
            expression: expression,
            completionHandler: completionHandler).continueWith { (task) -> AnyObject? in
                if let error = task.error {
                    print("Error: \(error)")
                    
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Failed"
                    }
                }
                
                if let _ = task.result {
                    
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Uploading..."
                        print("Upload Starting!")
                        print("Uploading...\(task.result?.status.rawValue.description ?? "N/A")")
                    }
                    
                    // Do something with uploadTask.
                }
                
                return nil;
            }
    }
    
    private func getFileRetrieved(){
        let listObjectsRequest = AWSS3ListObjectsV2Request()
        listObjectsRequest?.bucket = "ios-bucket-test"
        //listObjectsRequest?.prefix = prefix. //If you want to have a prefix
        //listObjectsRequest?.delimiter = delimiter //If you want to have a delimiter
        AWSS3.default().listObjectsV2(listObjectsRequest!) { (output, error) in
          if let error = error{
             print(error)
          }
          if let output = output{
             print(output)
          }
        }
    }
}

extension UploadViewController: UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        if "public.movie" == info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? String {
            let videoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as! URL
            let data = try! Data(contentsOf: videoURL)
            self.uploadImage(with: data)
        }
        
        
        dismiss(animated: true, completion: nil)
    }
}


fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}


fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}


final class CustomIdentityProvider: NSObject, AWSIdentityProviderManager {
    var tokens: [String : String]?
    
    init(tokens: [String : String]?) {
        self.tokens = tokens
    }
    
    /**
     Each entry in logins represents a single login with an identity provider.
     The key is the domain of the login provider (e.g. 'graph.facebook.com')
     and the value is the OAuth/OpenId Connect token that results from an authentication with that login provider.
     */
    func logins() -> AWSTask<NSDictionary> {
        let logins: NSDictionary = NSDictionary(dictionary: tokens ?? [:])
        return AWSTask(result: logins)
    }
}


//class AWSImageDownloader {
//
//    init(AccessKey accessKey:String, SecretKey secretKey:String, andRegion region:AWSRegionType = .USEast1) {
//
//        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
//        guard let configuration = AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider) else {
//            debugPrint("Failed to configure")
//            return
//        }
//
//        AWSServiceManager.default().defaultServiceConfiguration = configuration
//    }
//
//    func downloadImage(Name imageName:String, fromBucket bucketName:String, onDownload successCallback:@escaping AWSImageDownloadSuccess, andOnError errorCallback:@escaping AWSImageDownloadError){
//
//        let transferManager     = AWSS3.default()
//        let getImageRequest     = AWSS3GetObjectRequest()
//        getImageRequest?.bucket = bucketName
//        getImageRequest?.key    = imageName
//        transferManager.getObject(getImageRequest!).continueWith(executor: AWSExecutor.mainThread()) { (anandt) -> Void in
//            if anandt.error == nil {
//                if let imageData = anandt.result?.body as? Data, let image = UIImage(data: imageData) {
//
//                    successCallback(image)
//                } else {
//                    errorCallback("Download failed")
//                }
//            } else {
//
//                let error = "Error \(anandt.error?.localizedDescription ?? "unknown by dev")"
//                errorCallback(error)
//            }
//        }
//    }
//}
