//
//  ViewController.swift
//  SaveImages
//
//  Created by Joe E. on 11/11/15.
//  Copyright © 2015 Joe E. All rights reserved.
//

import UIKit

private let IMAGE_CELL = "ImageCell"
private let IMAGE_PNG = "image.png"
private let IMAGE_PNG_ROUTE = "/image.png"

private let BUCKET = "joe-photos"

class ViewController: UIViewController {
    
    var savedImages: [String] = []

    @IBOutlet weak var imageCollectionView: UICollectionView!

    @IBAction func pressedCapture(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        presentViewController(imagePicker, animated: true) { () -> Void in
            imagePicker.delegate = self
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageCollectionView.dataSource = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

}
extension ViewController : UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        defer { picker.dismissViewControllerAnimated(true, completion: nil) }
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        let s3manager = AFAmazonS3Manager(accessKeyID: accessID, secret: secretKey)
        s3manager.requestSerializer.bucket = BUCKET
        s3manager.requestSerializer.region = AFAmazonS3USStandardRegion
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        let filepath = paths[0] + IMAGE_PNG_ROUTE
        
        UIImagePNGRepresentation(image)?.writeToFile(filepath, atomically: true)
        
        let date = Int(NSDate().timeIntervalSince1970)
        
        s3manager.putObjectWithFile(filepath, destinationPath: ("image_\(date).png"), parameters: nil, progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
            let percent = Double(totalBytesWritten / totalBytesExpectedToWrite)
            
            print("loaded \(percent)")
            
            }, success: { (response) -> Void in
                print(response)
                if let urlResponse = response as? AFAmazonS3ResponseObject {
                    print(urlResponse.URL)
                    if let url = urlResponse.URL?.absoluteString {

                        self.savedImages.append(url)
                        self.imageCollectionView.reloadData()
                    }
                }
                
            }) { (error) -> Void in
                print(error)
                
        }
        
    }
    
}
extension ViewController: UINavigationControllerDelegate {
    
}

extension ViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedImages.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(IMAGE_CELL, forIndexPath: indexPath)
        
        for v in cell.contentView.subviews {
            v.removeFromSuperview()
            
        }
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        let imageURLString = savedImages[indexPath.item]
        
        dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            let data = NSData(contentsOfURL: NSURL(string: imageURLString)!)

            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    imageView.image = UIImage(data: data!)
                
                
            })
            
        }
        
        cell.contentView.addSubview(imageView)
        
        return cell
    }
    
}

extension ViewController : UICollectionViewDelegate {
    
    
}