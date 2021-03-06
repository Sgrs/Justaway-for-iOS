#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIMainViewController.h"
#import "JFITabViewController.h"
#import "JFIHomeViewController.h"
#import "JFINotificationsViewController.h"
#import "JFIMessagesViewController.h"
#import "JFIAccountViewController.h"
#import "JFITab.h"
#import "JFIStatusActionSheet.h"

@interface JFIMainViewController ()

@property (nonatomic) int currentPage;
@property (nonatomic) int defaultEditorBottomConstraint;
@property (nonatomic) NSString *inReplyToStatusId;
@property (nonatomic) UIImage *image;

@end

@implementation JFIMainViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"[JFIMainViewController] viewDidLoad");
    
    self.viewControllers = NSMutableArray.new;
    self.views = NSMutableArray.new;
    
    self.editorTextView.delegate = self;
    self.editorView.hidden = YES;
    
    self.defaultEditorBottomConstraint = self.editorBottomConstraint.constant;
    
    // タブを作る
    CGSize s = self.scrollWrapperView.frame.size;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width * 3, s.height)];
    
    NSArray *tabs = @[[[JFITab alloc] initWithType:TabTypeHome],
                      [[JFITab alloc] initWithType:TabTypeNotifications],
                      [[JFITab alloc] initWithType:TabTypeMessages]];
    
    int count = 0;
    for (JFITab *tab in tabs) {
        JFITabViewController *viewController = [tab loadViewConroller];
        viewController.view.frame = CGRectMake(0, 0, s.width, s.height);
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(s.width * count, 0, s.width, s.height)];
        [view addSubview:viewController.view];
        [self.contentView addSubview:view];
        [self.viewControllers addObject:viewController];
        [self.views addObject:view];
        count++;
    }
    
    [self.scrollView addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.frame.size;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // Streamingの接続状況に応じて
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectStreamingHandler:)
                                                 name:JFIStreamingConnectNotification
                                               object:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disconnectStreamingHandler:)
                                                 name:JFIStreamingDisconnectNotification
                                               object:delegate];
    
    // キーボードの開閉に応じて
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // 引用
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editorHandler:)
                                                 name:JFIEditorNotification
                                               object:delegate];
    
    // ステータス用のコンテキストメニュー表示
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openStatusHandler:)
                                                 name:JFIOpenStatusNotification
                                               object:delegate];
    
    // 背景をタップしたら、キーボードを隠す
    /*
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.editorTextView
                                                                                        action:@selector(resignFirstResponder)];
    [self.view addGestureRecognizer:gestureRecognizer];
     */
    
    // 投稿ボタンをロングタップでクイックツイートモード
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(toggleEditorAction:)];
    [self.postButton addGestureRecognizer:longPressGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // とりあえず回転無効化しているので不要
    return;
    
    NSLog(@"[JFIMainViewController] viewDidLayoutSubviews");
    NSLog(@"[JFIMainViewController] scrollWrapperView width:%f height:%f", self.scrollWrapperView.frame.size.width, self.scrollWrapperView.frame.size.height);
    NSLog(@"[JFIMainViewController] scrollView width:%f height:%f", self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    
    // 回転への対応
    CGSize s = self.scrollWrapperView.frame.size;
    NSInteger index = 0;
    for (UIView *view in self.views) {
        view.frame = CGRectMake(s.width * index, 0, s.width, s.height);
        index++;
    }
    self.scrollView.contentSize = CGSizeMake(s.width * index, s.height);
    self.contentView.frame = CGRectMake(0, 0, s.width * index, s.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    int page = (offset.x + 160) / 320;
    
    if (self.currentPage != page) {
        self.currentPage = page;
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    CGRect frame = textView.frame;
    CGFloat height = [[textView text] isEqualToString:@""] || textView.contentSize.height < 34 ? 34 : textView.contentSize.height;
    frame.size.height = height;
    textView.frame = frame;
    
    // これがないと下にめり込む
    self.editorHeightConstraint.constant = height;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    if (originalImage) {
        self.image = originalImage;
        self.imageButton.active = YES;
        [self.editorTextView becomeFirstResponder];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBAction

- (IBAction)streamingAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if ([delegate.accounts count] == 0) {
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        JFIEntity *tweet = [[JFIEntity alloc] initDummy];
        [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveStatusNotification
                                                            object:delegate
                                                          userInfo:@{@"tweet": tweet}];
    }
    if (delegate.onlineStreaming) {
        [delegate stopStreaming];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"connect"
                              message:@"ストリーミングを開始します"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        [delegate startStreaming];
    }
}

- (IBAction)changePageAction:(id)sender
{
    if (self.currentPage == [sender tag]) {
        JFITabViewController *viewController = (JFITabViewController *) self.viewControllers[self.currentPage];
        [viewController scrollToTop];
    } else {
        [UIView animateWithDuration:.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * [sender tag], 0) animated:NO];
                         } completion:nil];
    }
}

- (IBAction)accountAction:(id)sender
{
    NSLog(@"[JFIMainViewController] accountAction");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIAccount" bundle:nil];
    JFIAccountViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIAccountViewController"];
    [self presentViewController:accountViewController animated:YES completion:nil];
}

- (IBAction)postAction:(id)sender
{
    if (self.editorView.hidden) {
        self.editorView.hidden = NO;
        self.editorView.alpha = 0;
        [self.editorTextView becomeFirstResponder];
    } else {
        [self resetEditor];
        [self.view endEditing:YES];
        self.editorView.hidden = YES;
    }
}

- (void)toggleEditorAction:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.editorView.hidden = !self.editorView.hidden;
            break;
        case UIGestureRecognizerStateEnded:
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (IBAction)closeAction:(id)sender
{
    [self closeEditor];
}

- (IBAction)imageAction:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePickerController = UIImagePickerController.new;
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imagePickerController setDelegate:self];
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (IBAction)tweetAction:(id)sender
{
    NSLog(@"[JFIMainViewController] tweetAction");
    
    // TODO: 入力チェック
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // TODO: マルチアカウント対応
    STTwitterAPI *twitter = [delegate getTwitter];
    
    if (self.image) {
        NSData *data = UIImageJPEGRepresentation(self.image, 0.8f);
        [twitter postStatusUpdate:[self.editorTextView text]
                   mediaDataArray:@[data]
                possiblySensitive:nil
                inReplyToStatusID:self.inReplyToStatusId
                         latitude:nil
                        longitude:nil
                          placeID:nil
               displayCoordinates:nil
              uploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
                  // TODO: ProgressBar
              }
                     successBlock:^(NSDictionary *status) {
                         [self closeEditor];
                     }
                       errorBlock:^(NSError *error) {
                           ;
                       }
         ];
        return;
    }
    
    [twitter postStatusUpdate:[self.editorTextView text]
            inReplyToStatusID:self.inReplyToStatusId
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     [self closeEditor];
                 } errorBlock:^(NSError *error) {
                     NSLog(@"[JFIMainViewController] tweetAction error:%@", [error localizedDescription]);
                     [[[UIAlertView alloc]
                       initWithTitle:@"disconnect"
                       message:[error localizedDescription]
                       delegate:nil
                       cancelButtonTitle:nil
                       otherButtonTitles:@"OK", nil
                       ] show];
                 }];
}

#pragma mark - private methods

- (void)resetEditor
{
    self.image = nil;
    self.imageButton.active = NO;
    self.inReplyToStatusId = nil;
    [self.editorTextView setText:@""];
    [self textViewDidChange:self.editorTextView];
}

- (void)closeEditor
{
    self.image = nil;
    self.imageButton.active = NO;
    self.inReplyToStatusId = nil;
    [self.editorTextView setText:@""];
    [self textViewDidChange:self.editorTextView];
    
    if ([self.editorTextView isFirstResponder]) {
        // ちょっと薄くしてフォーカス外した後そのまま消してもらえるようアピール
        self.editorView.alpha = 0.99;
        [self.editorTextView resignFirstResponder];
    } else {
        // キーボードを表示していないモードではアニメーションせず隠す
        self.editorView.hidden = YES;
    }
}

#pragma mark - NSNotificationCenter handler

- (void)editorHandler:(NSNotification *)notification
{
    if (self.editorView.hidden) {
        self.editorView.hidden = NO;
    }
    NSDictionary *userInfo = [notification userInfo];
    [self.editorTextView setText:[userInfo objectForKey:@"text"]];
    [self.editorTextView becomeFirstResponder];
    if ([userInfo objectForKey:@"range_location"] != nil) {
        NSRange range = NSMakeRange([[userInfo objectForKey:@"range_location"] intValue],
                                    [[userInfo objectForKey:@"range_length"] intValue]);
        self.editorTextView.selectedRange = range;
    }
    self.inReplyToStatusId = [userInfo objectForKey:@"in_reply_to_status_id"];
}

- (void)openStatusHandler:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if ([userInfo objectForKey:@"entity"] != nil) {
        [[[JFIStatusActionSheet alloc] initWithEntity:[userInfo objectForKey:@"entity"]] showInView:self.view];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            self.editorBottomConstraint.constant = keyboardRect.size.width;
            break;
            
        default:
            self.editorBottomConstraint.constant = keyboardRect.size.height;
            break;
    }
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        if (self.editorView.alpha == 0) {
            self.editorView.alpha = 1.0;
        }
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    self.editorBottomConstraint.constant = self.defaultEditorBottomConstraint;
    
    if (self.editorView.alpha < 1) {
        // 薄くなってる時はそのまま消す
        [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
            self.editorView.alpha = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished){
            self.editorView.hidden = YES;
        }];
    } else {
        // 画像選択などでフォーカスが外れた時は下げるだけ
        [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
    }
}

- (void)connectStreamingHandler:(NSNotification *)center
{
    NSLog(@"[JFIMainViewController] connectStreamingHandler");
    [self.streamingButton setTitle:@"( ◠‿◠ )" forState:UIControlStateNormal];
}

- (void)disconnectStreamingHandler:(NSNotification *)center
{
    NSLog(@"[JFIMainViewController] disconnectStreamingHandler");
    [self.streamingButton setTitle:@"(◞‸◟)" forState:UIControlStateNormal];
}

@end
