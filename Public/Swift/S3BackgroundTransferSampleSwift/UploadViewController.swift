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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock
       // expression.setValue("public-read", forRequestHeader: "x-amz-acl")
        expression.setValue("public-read-write", forRequestHeader: "x-amz-acl")   //4
        expression.setValue("public-read-write", forRequestParameter: "x-amz-acl")
        
        DispatchQueue.main.async(execute: {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        })
        
      //  let videoName = UUID().uuidString + "test1.mp4"
        
        let transferUtility11 = AWSS3TransferUtility.default()
        transferUtility11.uploadData(
            data,
            bucket: "keeneye-cvm-trip-store-dev-qa-stage", //ios-bucket-test
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
