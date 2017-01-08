import UIKit
/// A Reusable View Controller that will display an image and allow the user to pinch and zoom the image
@objc class LISNRPhotoViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Private vars
    
    @IBOutlet weak fileprivate var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak fileprivate var scrollView: UIScrollView!
    fileprivate var imageView: UIImageView!
    fileprivate var photoObject: LISNRImageContentProtocol?
    fileprivate var photo: UIImage?
    fileprivate var downloadTask: URLSessionDataTask?
    
    // MARK: - Public functions
    
    /**
     Initialize a LISNRImagePhotoViewController with a photo object
     All LISNRImagePhotoViewControllers should use this constructor
     
     - parameter photo: the object to be passed to the controller
     
     - returns: a new ViewController with a valid LISNRImageContentProtocol? photoObject
     */
    public init(photo:LISNRImageContentProtocol!)
    {
        super.init(nibName:"LISNRPhotoViewController", bundle:nil)
        self.photoObject = photo
    }
    
    public init(image: UIImage, title: String?)
    {
        super.init(nibName:"LISNRPhotoViewController", bundle:nil)
        
        if let title = title {
            self.title = title
        }
        
        self.photo = image
        
    }
    
    
    // MARK: UIViewController Functions
    
    /**
     Overrides the viewDidAppear: function of UIViewController
     
     Retrieves the resource the provided photoObject.contentImageUrl()
     and places it into the scroll view with appropriate zoom scales
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollView.minimumZoomScale = 1.0;
        self.scrollView.maximumZoomScale = 6.0;
        self.scrollView.delegate = self;
        
        // Dispaly photo via block
        let displayPhotoBlock = { [unowned self] (image: UIImage) -> Void in
            
            DispatchQueue.main.async(execute: {
                self.imageView = UIImageView(image: image)
                self.imageView.contentMode = UIViewContentMode.scaleAspectFit
                
                // Add the imageView to the scroll view
                self.scrollView .addSubview(self.imageView)
                self.scrollView.contentSize = self.imageView.frame.size
                
                // Set up the correct zoom scales
                let zoomScale = self.calculateZoomScale()
                self.scrollView.minimumZoomScale = zoomScale
                self.scrollView.setZoomScale(zoomScale, animated: false)
                
                // Kill the spinner
                self.activityIndicator.stopAnimating()
            })
        }
        
        if let image = self.photo {
            //VC initialized with UIImage
            displayPhotoBlock(image)
        } else if FileManager.default.fileExists(atPath: self.photoObject!.contentImageUrl().absoluteString) {
            //Local url passed with LISNR Photo Content object
            
            if let imageData = try? Data(contentsOf: URL(fileURLWithPath: (self.photoObject!.contentImageUrl().absoluteString))), let image = UIImage(data: imageData) {
                displayPhotoBlock(image)
            }
        } else {
            //Web url passed with LISNR Photo Content object
            
            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            downloadTask = urlSession.dataTask(with: self.photoObject!.contentImageUrl(), completionHandler: { (data, response, error) in
                if error == nil {
                    if let data = data, let image = UIImage(data: data) {
                        displayPhotoBlock(image)
                    }
                }
            })
            downloadTask?.resume()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        downloadTask?.cancel()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    /**
     Initialize with an NSCoder
     
     Required by subclass of UIViewController
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: UIScrollViewDelegate Functions
    
    /**
     Returns the imageView which is the only subview of UIScrollView.
     
     - parameter scrollView: The scroll view calling the delegeate
     */
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    // MARK: - Private functions
    
    /**
     Finds the minimum zoomscale required to fit the image entirely within the bounds of the view
     
     - returns: Minimum zoom scale factor
     */
    fileprivate func calculateZoomScale() -> CGFloat
    {
        let possibleZoomScales = [ self.view.frame.size.width / self.imageView.frame.size.width,
                                   self.view.frame.size.height / self.imageView.frame.size.height,
                                   1]
        
        return possibleZoomScales.reduce(CGFloat.greatestFiniteMagnitude, {min($0,$1)})
    }
}
