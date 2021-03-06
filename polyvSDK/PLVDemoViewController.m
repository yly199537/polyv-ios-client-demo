//
//  PLVDemoViewController.m
//  PLV-ios-client-demo
//
//  Copyright (c) 2013 Polyv Inc. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "PLVKit.h"
#import "PLVDemoViewController.h"
#define PLVRemoteURLDefaultsKey @"PLVRemoteURL"

@interface PLVDemoViewController ()
    @property (strong, nonatomic) ALAssetsLibrary* assetsLibrary;
@end

@implementation PLVDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    [self.imageOverlay setHidden:YES];
    [self.progressBar setProgress:.0];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{PLVRemoteURLDefaultsKey: @"http://v.polyv.net:1080/files/"}];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //NSString* text = [NSString stringWithFormat:NSLocalizedString(@"for upload to:\n%@",nil), [self endpoint]];
    //[self.urlTextView setText:text];
}
- (IBAction)closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - IBAction Methods
- (IBAction)chooseFile:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    //imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,      nil];

    
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerDelegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.urlTextView setText:nil];
    [self.imageView setImage:nil];
    [self.progressBar setProgress:.0];
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 NSString* type = [info valueForKey:UIImagePickerControllerMediaType];
                                 CFStringRef typeDescription = (UTTypeCopyDescription((__bridge CFStringRef)(type)));
                                 NSString* text = [NSString stringWithFormat:NSLocalizedString(@"Uploading %@…", nil), typeDescription];
                                 CFRelease(typeDescription);
                                 [self.statusLabel setText:text];
                                 [self.imageOverlay setHidden:NO];
                                 [self.chooseFileButton setEnabled:NO];
                                 [self uploadVideoFromAsset:info];
                             }];
}

- (void)uploadVideoFromAsset:(NSDictionary*)info
{
    NSURL *assetUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSString *fingerprint = [assetUrl absoluteString];

    [[self assetsLibrary] assetForURL:assetUrl
                          resultBlock:^(ALAsset* asset) {
                              self.imageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
                              self.imageView.alpha = .5;
                              PLVAssetData* uploadData = [[PLVAssetData alloc] initWithAsset:asset];
                              //PLVResumableUpload *upload = [[PLVResumableUpload alloc] initWithURL:[self endpoint] data:uploadData fingerprint:fingerprint writeToken:@"Y07Q4yopIVXN83n-MPoIlirBKmrMPJu0"];
                              
                              PLVResumableUpload *upload = [[PLVResumableUpload alloc] initWithURL:[self endpoint] data:uploadData fingerprint:fingerprint];
                              NSString * surl = [assetUrl absoluteString];
                              NSString * ext = [surl substringFromIndex:[surl rangeOfString:@"ext="].location + 4];
                              NSMutableDictionary* extraInfo = [[NSMutableDictionary alloc]init];
                              [extraInfo setValue:ext forKey:@"ext"];
                              [extraInfo setValue:@"polyvsdk" forKey:@"title"];
                              [extraInfo setValue:@"polyvsdk upload demo video" forKey:@"desc"];
                              [upload setExtraInfo:extraInfo];
                              upload.progressBlock = [self progressBlock];
                              upload.resultBlock = [self resultBlock];
                              upload.failureBlock = [self failureBlock];
                              [upload start];
                          }
                         failureBlock:^(NSError* error) {
                             NSLog(@"Unable to load asset due to: %@", error);
                         }];
}

- (void(^)(NSInteger bytesWritten, NSInteger bytesTotal))progressBlock
{
    return ^(NSInteger bytesWritten, NSInteger bytesTotal) {
        float progress = (float)bytesWritten / (float)bytesTotal;
        if (isnan(progress)) {
            progress = .0;
        }
        [self.progressBar setProgress:progress];
    };
}

- (void(^)(NSError* error))failureBlock
{
    return ^(NSError* error) {
        NSLog(@"Failed to upload file due to: %@", error);
        [self.chooseFileButton setEnabled:YES];
        NSString* text = self.urlTextView.text;
        text = [text stringByAppendingFormat:@"\n%@", [error localizedDescription]];
        [self.urlTextView setText:text];
        [self.statusLabel setText:NSLocalizedString(@"Failed!", nil)];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                   message:[error localizedDescription]
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
    };
}

- (void(^)(NSData* serverResponse))resultBlock
{
    return ^(NSData* serverResponse) {
        
        [self.chooseFileButton setEnabled:YES];
        [self.imageOverlay setHidden:YES];
        self.imageView.alpha = 1;
        NSString* serverResponseTxt= [[NSString alloc] initWithData:serverResponse encoding:NSUTF8StringEncoding];
        
        NSString* text = [NSString stringWithFormat:NSLocalizedString(@"serverResponseTxt:\n%@",nil), serverResponseTxt];
        [self.urlTextView setText:text];
        
        NSLog(@"%@",serverResponseTxt);

        
       
        
        
        
        
    };
}

- (NSString*)endpoint
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PLVRemoteURLDefaultsKey];
}

@end
