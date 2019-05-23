## Image-Resizing-in-iOS
[NSHipster原文](https://nshipster.com/image-resizing/)
### iOS中5种图片缩放方法
#### UIImage的属性 contentMode
在我们进行下一步之前，首先思考下为什么需要调整图片尺寸。毕竟`UIImageView`的property`contentMode`会根据具体场景自动调整。在绝大多数情况下，`.scaleAspectFit`,`.scaleAspectFill`或者`.scaleToFill`能满足需求。

```Swift
imageView.contentMode = .scaleAspectFit
imageView.image = image
```
所以，哪些场景调整图片尺寸才有意义呢？
当原图尺寸明显的大于需要展示的`UIImageView`的尺寸。

示例图片 [NASA地球](https://visibleearth.nasa.gov/)

这张全图的尺寸12000px * 12000px，大小为20MB。一般人可能会觉得在今天的硬件条件下，这样的大小(20MB)不算什么，其实这只是被压缩后的尺寸。在显示图片之前，`UIImageView`需要先把**JPEG**解码成位图(`bitmap`)。如果你试着去加载这张全尺寸的图，手机的内存后瞬间暴涨之几百MB，同时对用户也没有任何好处。(手机屏幕的像素尺寸也没这么大)

只需设置`image`的propety来稍微调整下尺寸，就能使内存的消耗降低一个数量级。

                                            Memory Usage (MB)
```Swift                        
Without         Downsampling	                   220.2
With            Downsampling	                   23.7
```
这个技术叫做*降低采样率*(downsampling)，在这种情形下可以明显的提升性能。[session from WWDC](https://developer.apple.com/videos/play/wwdc2018/219/)中介绍了更多关于`downsampling`和`graphics`的实践。

现在很少有app会加载这种大图，但是设计师很可能会给到这种大尺寸图片。(比如，一张带有颜色通道的PNG图片就有3MB)考虑到这种情况，这里有几种缩放图片尺寸的方法

在例子中演示的图片在都存储在本地。

这里的`size`指的是实际的物理尺寸，并不是像素尺寸。缩放之前，需要先计算等效的像素尺寸。

```Swift
let scaleFactor = UIScreen.main.scale // 屏幕scale
let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor) // 转换成 CGAffineTransform
let size = imageView.bounds.size.applying(scale) // 转换成对应的CGSize
```

给异步加载图片设置一个渐入的转场特效
```Swift
DispatchQueue.global(qos: .userInitiated).async {
    let image = resizedImage(at: url, for: self.imageView.bounds.size)
    
    DispatchQueue.main.sync {
        UIView.transition(with: self.imageView,
                      duration: 1.0, 
                       options: [.curveEaseOut, .transitionCrossDissolve],
                     animation: {
                        self.imageView.image = image
                     })
    }
}
```

#### 第一种.使用UIGraphicsImageRenderer绘制
这是在`UIKit framework`中能找到缩放图片的最高层级的API。使用`UIGraphicsImageRenderer`的`context`来绘制缩放的图片

```Swift
func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
    guard let image = UIImage(contentsOfFile: url.path) else {
        return nil
    }
    
    let renderer = UIGraphicsImageRenderer(size: size)
    return render.image { (context) in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}
```
`UIGraphicsImageRenderer`是在iOS10之后推出的为了替换之前的旧API`UIGraphicsBeginImageContextWithOptions / UIGraphicsEndImageContext`。通过给定一个`CGSize`来初始化`UIGraphicsImageRenderer`。`image`提供了一个接受闭包作为参数的方法，在闭包内返回`UIGraphicsImageRendererContext`的参数，原始图片根据给定的尺寸调整尺寸。闭包执行结束返回缩放过的图片。

#### 第二种.使用Core Graphics Context 绘制
Core Graphics/Quartz 2D提供了低层级API进行更深入的定制。
使用`CGImage`，临时的位图上下文来绘制缩放的图片。

```Swift
func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
    guard let imageSource = CGImageSourceCreateWith(url as NSURL, nil),
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
        return nil
    }
    
    let context = CGContext(data: nil,
                           width: Int(size.width),
                          height: Int(size.height), 
                bitsPerComponent: image.bitsPerComponent, 
                     bytesPerRow: image.bytesPerRow, 
                           space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: image.bitmapInfo.rawValue)
    context?.interpolationQuality = .high
    context.draw(image, in: CGRect(origin: .zero, size: size))
    
    guard let scaleImage = context?makeImage() else { return nil }
    
    return UIImage(cgImage: scaleImage)
}
```
`CGContext`的初始化需要穿几个参数，包括所需的维度，每个颜色空间占用的内存量。在上面例子中，这些参数来自一个`CGImage`对象。下一步，设置`interpolationQuality`属性为`.high`，确保图片的高保真。`draw(_:in:)`根据指定的尺寸和位置来绘制图片，按照特定边界和合适的尺寸裁剪出图片。最后，`nakeImage()`捕获`context`上下文渲染出一个`CGImage`对象。(再转换为UIImage对象)

#### 第三种.Creating a Thumbnail with Image I/O
Image I/O 在处理图片上是个非常强大的framework。(尽管很少使用它)不同于Core Graphics，Image I/O可以读写各种不同的图片格式，包括照片metadata，并执行常见的图像处理操作。它(Image I/O)提供了apple 平台上最快的图片编码和解码操作，通过缓存机制，甚至能增量加载图片。

其中最重要的`CGImageSourceCreateThumbnailAtIndex`可以根据不同参数组合成了非常简洁的API，等效于 Core Graphics

```Swift
func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
        let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
    else {
        return nil
    }

    return UIImage(cgImage: image)
}
```
给定一个`CGImageSource`对象同时设置参数，`CGImageSourceCreateThumbnailAtIndex(_:_:_:)`方法生成一张缩略图。`kCGImageSourceThumbnailMaxPixelSize`选项根据原图的宽高比设置最大显示尺寸。设置`kCGImageSourceCreateThumbnailFromImageIfAbsent`或`kCGImageSourceCreateThumbnailFromImageAlways`，`Image I/O`会自动缓存缩放的对象来为后续操作。

#### 第四种.Lanczos Resampling with Core Image
Core Image内置了基于[Lanczos resampling](https://baike.baidu.com/item/Lanczos%E7%AE%97%E6%B3%95/9849921)算法同名`CILanczosScaleTransform`过滤器。尽管可以说它比UIKit提供的API更高层级，但是烦人的`key-value`操作使它并没有被广泛使用。

下面的代码可以看出有关`key-value`的操作

创建、配置过滤器，渲染输出图片的流程和Core Image的流程差不多:
```Swift
import UIKit
import CoreImage

let sharedContext = CIContext(options: [.useSoftwareRenderer : false])

// Technique #4
func resizedImage(at url: URL, scale: CGFloat, aspectRatio: CGFloat) -> UIImage? {
    guard let image = CIImage(contentsOf: url) else {
        return nil
    }

    let filter = CIFilter(name: "CILanczosScaleTransform")
    filter?.setValue(image, forKey: kCIInputImageKey)
    filter?.setValue(scale, forKey: kCIInputScaleKey)
    filter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

    guard let outputCIImage = filter?.outputImage,
        let outputCGImage = sharedContext.createCGImage(outputCIImage,
                                                        from: outputCIImage.extent)
    else {
        return nil
    }

    return UIImage(cgImage: outputCGImage)
}
```
Core Image中的过滤器叫做`CILanczosScaleTransform`，接受一个图片参数`inputImage`，变换scale`inputScale`，宽高比`inputAspectRatio`，每个都很容易理解。

有趣的是，这里使用`CIContext`生成`UIImage`(通过CGImageRef中转表示)，因为`UIImage(CGImage:)`经常出错，创建一个`CIContext`对象是非常耗费性能的操作，所以缓存context对象为了重复缩放。

`CIContext`可以设置使用硬件还是软件来渲染。Bool型的`.useSoftwareRenderer`参数设置渲染类型。

#### 第五种.Image Scaling with vImage
最后，是历史悠久的加速框架`Accelerate framework`，更具体的说是`vImage`图像处理子框架。vImage附带了一组用于缩放图像缓冲区的不同函数。这些底层api在低功耗还能高性能，但需要自己管理`buffers`(更不用说编写更多代码了):

```Swift
import UIKit
import Accelerate.vImage

// Technique #5
func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
    // Decode the source image
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
        let imageWidth = properties[kCGImagePropertyPixelWidth] as? vImagePixelCount,
        let imageHeight = properties[kCGImagePropertyPixelHeight] as? vImagePixelCount
    else {
        return nil
    }

    // Define the image format
    var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                      bitsPerPixel: 32,
                                      colorSpace: nil,
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                      version: 0,
                                      decode: nil,
                                      renderingIntent: .defaultIntent)

    var error: vImage_Error

    // Create and initialize the source buffer
    var sourceBuffer = vImage_Buffer()
    defer { sourceBuffer.data.deallocate() }
    error = vImageBuffer_InitWithCGImage(&sourceBuffer,
                                         &format,
                                         nil,
                                         image,
                                         vImage_Flags(kvImageNoFlags))
    guard error == kvImageNoError else { return nil }

    // Create and initialize the destination buffer
    var destinationBuffer = vImage_Buffer()
    error = vImageBuffer_Init(&destinationBuffer,
                              vImagePixelCount(size.height),
                              vImagePixelCount(size.width),
                              format.bitsPerPixel,
                              vImage_Flags(kvImageNoFlags))
    guard error == kvImageNoError else { return nil }

    // Scale the image
    error = vImageScale_ARGB8888(&sourceBuffer,
                                 &destinationBuffer,
                                 nil,
                                 vImage_Flags(kvImageHighQualityResampling))
    guard error == kvImageNoError else { return nil }

    // Create a CGImage from the destination buffer
    guard let resizedImage =
        vImageCreateCGImageFromBuffer(&destinationBuffer,
                                      &format,
                                      nil,
                                      nil,
                                      vImage_Flags(kvImageNoAllocate),
                                      &error)?.takeRetainedValue(),
        error == kvImageNoError
    else {
        return nil
    }

    return UIImage(cgImage: resizedImage)
}
```
这里使用的加速api显然比目前讨论的任何其他调整大小的方法的层级都要低得多。但是，跳过那些看起来不友好的类型和函数名，会发现这种方法相当直接。
- 首先，根据输入image创建一个soucre buffer
- 然后创建目标buffer来持有缩放图
- 再次，把soucre buffer中image data缩放至目标buffer
- 最后，根据目标buffer的iamge data 创建出image

#### 性能测试
iPhone 7 running iOS 12.2   

|   | 时间(s) | 内存占用(M) | CPU占用(%)  |
| :-- | :-: | :-: | :-: |
| Core Graphics | 0.13 | 14.x-24-14.x | 0-30-0 |
| ImageIO | 0.13 | 14.x-25-15.x | 0-30-0 |
| UIKit | 0.31 | 14.x-40-14.x | 0-40-0 |
| CoreImage | 2.21 | 14.x-5xx-14.x | 0-100-0 |
| vImage | 1.67 | 14.x—6xx-14.x | 0-162-0 |

> [Image Resizing Techniques - Mattt](https://nshipster.com/image-resizing/)
> [iOS平台图片编解码入门教程（vImage篇）- 小猪](https://dreampiggy.com/2017/11/12/iOS%E5%B9%B3%E5%8F%B0%E5%9B%BE%E7%89%87%E7%BC%96%E8%A7%A3%E7%A0%81%E5%85%A5%E9%97%A8%E6%95%99%E7%A8%8B%EF%BC%88vImage%E7%AF%87%EF%BC%89/)
> [OTLargeImageReader](https://github.com/OpenFibers/OTLargeImageReader)
> 

