//
//  WTLViewController.m
//  TestMergeVideo
//
//  Created by zang qilong on 14/8/25.
//  Copyright (c) 2014年 Worktile. All rights reserved.
//

#import "WTLViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

@interface WTLViewController ()<UIImagePickerControllerDelegate,MPMediaPickerControllerDelegate,UINavigationControllerDelegate>
{
    NSURL *videoURL;
    AVURLAsset *firstAsset;
    AVURLAsset *secondAsset;
    AVMutableVideoComposition *mainComposition;
    AVMutableComposition *mixComposition;
    NSMutableArray * audioMixParams;
    NSURL * audioUrl;
}
@property (nonatomic, strong) UIImagePickerController *picker;
@end

@implementation WTLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)openAudiaLibrary:(id)sender {
    MPMediaPickerController *mpc = [[MPMediaPickerController alloc]initWithMediaTypes:MPMediaTypeMusic];
    mpc.delegate = self;//委托
    mpc.prompt =@"Please select a music";//提示文字
    mpc.allowsPickingMultipleItems=NO;//是否允许一次选择多个
    [self presentViewController:mpc animated:YES completion:nil];
    
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection{
    /*insert your code*/
    for (  MPMediaItem* item in [mediaItemCollection items]) {
        audioUrl = item.assetURL;
    }
    [self dismissModalViewControllerAnimated:YES];

}

- (IBAction)joinAudio:(id)sender {
    
    //申明组合器
    AVMutableComposition *composition = [AVMutableComposition composition];
    //申明音频层管理器
    audioMixParams = [[NSMutableArray alloc] initWithObjects:nil];
    
    //Add Audio Tracks to Composition
    //获取Asset
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"];
    NSURL *assetURL1 = [NSURL fileURLWithPath:path];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL1 options:nil];
    //申明新增结构为音频
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //申明新增层，并进行相关设置(通道，音量等)
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [trackMix setVolume:0.8f atTime:kCMTimeZero];
    
    [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, songAsset.duration)
                   ofTrack:[[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                    atTime:kCMTimeZero
                     error:nil];
    //将当前层保存到音频层管理器中
    [audioMixParams addObject:trackMix];
    
    //============添加选择的音频============
    AVURLAsset * inputAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVMutableCompositionTrack *inputTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableAudioMixInputParameters *inputTrackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:inputTrack];
    [inputTrackMix setVolume:0.8f atTime:kCMTimeZero];
    [inputTrackMix setVolume:0.0f atTime:CMTimeMakeWithSeconds(8.0f, 30)];
    [inputTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                   ofTrack:[[inputAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                    atTime:CMTimeMakeWithSeconds(3.0f, 30)
                     error:nil];
    [audioMixParams addObject:inputTrackMix];
    
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    
    NSLog (@"compatible presets for songAsset: %@",
           [AVAssetExportSession exportPresetsCompatibleWithAsset:composition]);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                      initWithAsset: composition
                                      presetName: AVAssetExportPresetAppleM4A];
    
    exporter.audioMix = audioMix;
    exporter.outputFileType = @"com.apple.m4a-audio";
    
    
    
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:exporter.asset];
    playerItem.audioMix = audioMix;
    //playerItem.videoComposition = exporter.videoComposition;
    
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playItem:) userInfo:@{@"item":player} repeats:NO];
    
}

- (IBAction)openLibrary:(id)sender
{
    _picker = [[UIImagePickerController alloc] init];
    self.picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    self.picker.allowsEditing = YES;
    self.picker.delegate = self;
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)testmultipl:(id)sender {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"rain" ofType:@"mp4"];
    NSLog(@"path is %@",path);
    firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    CMTime total = kCMTimeZero;
    NSMutableArray * layers = [[NSMutableArray alloc] init];
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];

    AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        
//layer并不依赖track的时基
    CMTime  fakeDuration = CMTimeMakeWithSeconds(15.0f, 600);
    
    for (int i = 0 ; i < 2; i ++ ) {
        
//        CMTime st = CMTimeMakeWithSeconds(i * 1.0f * CMTimeGetSeconds(firstAsset.duration), firstAsset.duration.timescale);
        CMTime st = CMTimeMakeWithSeconds(i * 1.0f * CMTimeGetSeconds(fakeDuration), firstAsset.duration.timescale);
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,firstAsset.duration)
                            ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                             atTime:st
                              error:nil];
        [firstTrack scaleTimeRange:CMTimeRangeMake(st, firstAsset.duration) toDuration:fakeDuration];
        [firstlayerInstruction setOpacityRampFromStartOpacity:0.0f toEndOpacity:1.0f timeRange:CMTimeRangeMake(st, CMTimeMakeWithSeconds(1.0f, 30))];
        
        
    }
//    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,firstAsset.duration)
//                            ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                             atTime:kCMTimeZero
//                          error:nil];
//    [firstlayerInstruction setOpacityRampFromStartOpacity:0.0f toEndOpacity:1.0f timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(1.0f, 30))];
//    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,firstAsset.duration)
//                        ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                         atTime:firstAsset.duration
//                          error:nil];
//
//    [firstlayerInstruction setOpacityRampFromStartOpacity:0.0f toEndOpacity:1.0f timeRange:CMTimeRangeMake(firstAsset.duration, CMTimeMakeWithSeconds(1.0f, 30))];
    
    total = CMTimeMakeWithSeconds(3 * 1.0f * CMTimeGetSeconds(firstAsset.duration), firstAsset.duration.timescale);
//    [firstlayerInstruction setOpacity:1.0f atTime:kCMTimeZero];
//    [firstlayerInstruction setOpacity:0.0f atTime:total];
    total = CMTimeMakeWithSeconds(2 * 1.0f * CMTimeGetSeconds(fakeDuration), firstAsset.duration.timescale);
    [layers addObject:firstlayerInstruction];
    
    
    mainInstruction.layerInstructions = [NSArray arrayWithArray:layers];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, total);
    mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
    mainComposition.frameDuration = CMTimeMake(1, 30);
    mainComposition.renderSize = CGSizeMake(640, 480);
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
    playerItem.videoComposition = mainComposition;
    
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playItem:) userInfo:@{@"item":player} repeats:NO];
    
    
}

- (IBAction)mergeVideo:(id)sender
{
    if (YES) {
        
        /* 合成视频套路就是下面几条，跟着走就行了，具体函数意思自行google
         1.不用说，肯定加载。用ASSET
         2.这里不考虑音轨，所以只获取video信息。用track 获取asset里的视频信息，一共两个track,一个track是你自己拍的视频，第二个track是特效视频,因为两个视频需要同时播放，所以起始时间相同，都是timezero,时长自然是你自己拍的视频时长。然后把两个track都放到mixComposition里。
         3.第三步就是最重要的了。instructionLayer,看字面意思也能看个七七八八了。架构图层，就是告诉系统，等下合成视频，视频大小，方向，等等。这个地方就是合成视频的核心。我们只需要更改透明度就行了，把特效track的透明度改一下，让他能显示底下你自己拍的视屏图层就行了。
         4.
        **/
        NSLog(@"First Asset = %@",firstAsset);
        
        // 1
        secondAsset = [AVAsset assetWithURL:videoURL];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"rain" ofType:@"mp4"];
        NSLog(@"path is %@",path);
        //firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        NSLog(@"second Asset = %@",secondAsset);
        NSLog(@"firstAsset==%f,%f",firstAsset.naturalSize.width,firstAsset.naturalSize.height);
        NSLog(@"secondAsset==%f,%f",secondAsset.naturalSize.width,secondAsset.naturalSize.height);
        
        
        //second Video
        
        //secondAsset = [AVAsset assetWithURL:videoTwoURL];
    }
    if (firstAsset&&secondAsset) {
        
        // 2.
        CGSize targetSize = CGSizeMake(640, 480);

        mixComposition = [[AVMutableComposition alloc] init];
        AVMutableCompositionTrack *firstTrack =
        [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                    preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeAdd(firstAsset.duration, CMTimeMakeWithSeconds(5.0f, 600)))
                            ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                             atTime:CMTimeMakeWithSeconds(0.0f, 30)
                              error:nil];
        
        [firstTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) toDuration:CMTimeAdd(firstAsset.duration, CMTimeMakeWithSeconds(5.0f, 600))];
        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        

        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,secondAsset.duration)
                             ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                              atTime:kCMTimeZero
                               error:nil];

        
        //CGAffineTransformMake(a,b,c,d,tx,ty) ad缩放 bc 旋转tx,ty位移

         //3.
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,secondAsset.duration);
        
         //第一个视频的架构层
        
        AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [firstlayerInstruction setOpacity:0 atTime:CMTimeAdd(firstAsset.duration, CMTimeMakeWithSeconds(5.0f, 600))];
        //[firstlayerInstruction setTransform:[self layerTrans:firstAsset withTargetSize:targetSize] atTime:kCMTimeZero];
//        [firstlayerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration)];
         // 第二个视频的架构层
        CGRect test = CGRectMake(0, 0, 300, 300);
        [firstlayerInstruction setCropRectangle:test atTime:kCMTimeZero];//展示整个layer中某一位置和大小的视图
        AVMutableVideoCompositionLayerInstruction *secondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
       [secondlayerInstruction setTransform:[self layerTrans:secondAsset withTargetSize:targetSize] atTime:kCMTimeZero];
//        [secondlayerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(600, 600))];
        
        
       
        
        // 这个地方你把数组顺序倒一下，视频上下位置也跟着变了。
        mainInstruction.layerInstructions = [NSArray arrayWithObjects:firstlayerInstruction,secondlayerInstruction, nil];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration);
        
        mainComposition = [AVMutableVideoComposition videoComposition];
        mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
        mainComposition.frameDuration = CMTimeMake(1, 30);
        mainComposition.renderSize = CGSizeMake(640, 480);
        
        //  导出路径
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"mergeVideo.mov"]];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:myPathDocs error:NULL];
        
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        
//        NSLog(@"URL:-  %@", [url description]);
        
        //导出
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        
        exporter.outputURL = url;
        
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        exporter.shouldOptimizeForNetworkUse = YES;
        
        exporter.videoComposition = mainComposition;
        
        NSLog(@"%.0f",mixComposition.duration.value/mixComposition.duration.timescale + 0.0f);
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:exporter.asset];
        playerItem.videoComposition = exporter.videoComposition;
        
        
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        
        playerLayer.frame = self.view.layer.bounds;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.view.layer addSublayer:playerLayer];
        
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playItem:) userInfo:@{@"item":player} repeats:NO];
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self exportDidFinish:exporter];
                
            });
        }];
        
    }else {
        
     
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错!" message:@"选择视频"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    

}

- (void)playItem:(NSTimer*)timer
{
    AVPlayer * player =  (AVPlayer *)[timer.userInfo objectForKey:@"item"];
    [player play];
}


-(CGAffineTransform) layerTrans : (AVAsset *)testAsset  withTargetSize:(CGSize) tsize
{

    CGSize inputSize = testAsset.naturalSize;
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (inputSize.height > inputSize.width) {
        float scale  = MAX(tsize.width/inputSize.height , tsize.height/inputSize.width);
        transform = CGAffineTransformScale(transform, scale, scale);
        transform = CGAffineTransformRotate(transform,  M_PI / 2.0);
        CGSize newSzie = CGSizeMake(inputSize.height * scale, inputSize.width * scale);
        transform = CGAffineTransformTranslate(transform, (- newSzie.width + tsize.width)/2, (- newSzie.height + tsize.height)/2);
    } else {
        float scale  = MAX(tsize.width/inputSize.width , tsize.height/inputSize.height);
        transform = CGAffineTransformScale(transform, scale, scale);
        CGSize newSzie = CGSizeMake(inputSize.width * scale, inputSize.height * scale);
        transform = CGAffineTransformTranslate(transform, (- newSzie.width + tsize.width)/2, (- newSzie.height + tsize.height)/2);
    }
    return transform;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) exportAudio
{
    
    
    
    
    //申明组合器
    AVMutableComposition *composition = [AVMutableComposition composition];
    //申明音频层管理器
    audioMixParams = [[NSMutableArray alloc] initWithObjects:nil];
    
    //Add Audio Tracks to Composition
    //获取Asset
    NSString *path = [[NSBundle mainBundle] pathForResource:@"recordedFile" ofType:@"caf"];
    NSURL *assetURL1 = [NSURL fileURLWithPath:path];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL1 options:nil];
    //申明新增结构为音频
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //申明新增层，并进行相关设置(通道，音量等)
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [trackMix setVolume:0.8f atTime:kCMTimeZero];

    [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, songAsset.duration)
                   ofTrack:[[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                    atTime:kCMTimeZero
                     error:nil];
    //将当前层保存到音频层管理器中
    [audioMixParams addObject:trackMix];
    

    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    

    NSLog (@"compatible presets for songAsset: %@",
           [AVAssetExportSession exportPresetsCompatibleWithAsset:composition]);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                      initWithAsset: composition
                                      presetName: AVAssetExportPresetAppleM4A];
    
    exporter.audioMix = audioMix;
    exporter.outputFileType = @"com.apple.m4a-audio";
    
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:exporter.asset];
    playerItem.audioMix = audioMix;
    //playerItem.videoComposition = exporter.videoComposition;
    
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playItem:) userInfo:@{@"item":player} repeats:NO];
    
    
    //输出合成音频
//    NSString *fileName = @"someFilename";
//    NSString *exportFile = [NSHomeDirectory() stringByAppendingFormat: @"/%@.m4a", fileName];
//
//    if ([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {
//        [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
//    }
//    NSURL *exportURL = [NSURL fileURLWithPath:exportFile];
//    exporter.outputURL = exportURL;
//    
//    // do the export
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        int exportStatus = exporter.status;
//        switch (exportStatus) {
//            case AVAssetExportSessionStatusFailed:{
//                NSError *exportError = exporter.error;
//                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
//                break;
//            }
//                
//            case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted"); break;
//            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
//            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
//            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
//            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
//            default:  NSLog (@"didn't get export status"); break;
//        }
//    }];
}
-(void)exportDidFinish:(AVAssetExportSession*)session {
    
    NSLog(@"exportDidFinish");
    
    NSLog(@"session = %d",(int)session.status);
    if (session.status == AVAssetExportSessionStatusCompleted) {
        
        NSURL *outputURL = session.outputURL;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])  {
            
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"存档失败"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                        message:@"存档成功"
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }];
            
        }
        
    }else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"存档失败"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}



@end
