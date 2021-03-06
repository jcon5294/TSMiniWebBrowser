//
//  TSMiniWebBrowser.m
//  TSMiniWebBrowserDemo
//
//  Created by Toni Sala Echaurren on 18/01/12.
//  Copyright 2012 Toni Sala. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TSMiniWebBrowser.h"

@interface TSMiniWebBrowser ()
{
    // URL
    NSURL *urlToLoad;
    
    // Layout
    UIWebView *webView;
    UIToolbar *toolBar;
    UINavigationBar *navigationBarModal; // Only used in modal mode
    
    // Toolbar items
    UIActivityIndicatorView *activityIndicator;
    UIBarButtonItem *buttonGoBack;
    UIBarButtonItem *buttonGoForward;
    
    // Customization
    NSString *forcedTitleBarText;
}
@end

@implementation TSMiniWebBrowser

#define kToolBarHeight  44
#define kTabBarHeight   49

enum actionSheetButtonIndex {
	kSafariButtonIndex,
	kChromeButtonIndex,
};

#pragma mark - Setup

- (id)initWithUrl:(NSURL*)url
{
    self = [self init];
    if(self)
    {
        urlToLoad = url;
        
        // Defaults
        self.mode = TSMiniWebBrowserModeNavigation;
        self.showURLStringOnActionSheetTitle = YES;
        self.showPageTitleOnTitleBar = YES;
        self.showReloadButton = YES;
        self.showActionButton = YES;
        self.modalDismissButtonTitle = NSLocalizedString(@"Done", nil);
        forcedTitleBarText = nil;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Main view frame.
    if (self.mode == TSMiniWebBrowserModeTabBar) {
        CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height - kTabBarHeight;
        if (![UIApplication sharedApplication].statusBarHidden) {
            viewHeight -= [UIApplication sharedApplication].statusBarFrame.size.height;
        }
        self.view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    }
    
    // Init tool bar
    [self initToolBar];
    
    // Init web view
    [self initWebView];
    
    // Init title bar if presented modally
    if (self.mode == TSMiniWebBrowserModeModal) {
        [self initTitleBar];
    }
    
    // UI state
    buttonGoBack.enabled = NO;
    buttonGoForward.enabled = NO;
    if (forcedTitleBarText != nil) {
        [self setTitleBarText:forcedTitleBarText];
    }
}

// This method is only used in modal mode
-(void) initTitleBar
{
    UIBarButtonItem *buttonDone = [[UIBarButtonItem alloc] initWithTitle:self.modalDismissButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(dismissController)];
    
    UINavigationItem *titleBar = [[UINavigationItem alloc] initWithTitle:@""];
    titleBar.leftBarButtonItem = buttonDone;
    
    CGFloat width = self.view.frame.size.width;
    navigationBarModal = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    //navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    navigationBarModal.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [navigationBarModal pushNavigationItem:titleBar animated:NO];
    
    [self.view addSubview:navigationBarModal];
}

-(void) initToolBar
{
    if (_showToolBar) {
        CGSize viewSize = self.view.frame.size;
        if (self.mode == TSMiniWebBrowserModeTabBar) {
            toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, -1, viewSize.width, kToolBarHeight)];
        } else {
            toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, viewSize.height-kToolBarHeight, viewSize.width, kToolBarHeight)];
        }
        
        toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:toolBar];
    }
        
    buttonGoBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTouchUp:)];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 30;
    
    buttonGoForward = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardButtonTouchUp:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *buttonReload = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadButtonTouchUp:)];
    
    UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace2.width = 20;
    
    UIBarButtonItem *buttonAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(buttonActionTouchUp:)];
    
    // Activity indicator is a bit special
//    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    activityIndicator.frame = CGRectMake(11, 7, 20, 20);
//    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 43, 33)];
//    [containerView addSubview:activityIndicator];
//    UIBarButtonItem *buttonContainer = [[UIBarButtonItem alloc] initWithCustomView:containerView];
        
    // Add butons to an array
    NSMutableArray *toolBarButtons = [[NSMutableArray alloc] init];
    if (_showBackAndForward) {
        [toolBarButtons addObject:buttonGoBack];
        if (_showToolBar) [toolBarButtons addObject:fixedSpace];
        [toolBarButtons addObject:buttonGoForward];
        if (_showToolBar) [toolBarButtons addObject:flexibleSpace];
    }
//        [toolBarButtons addObject:buttonContainer];
    if (self.showReloadButton) {
        [toolBarButtons addObject:buttonReload];
    }
    if (self.showActionButton) {
        if (_showToolBar) [toolBarButtons addObject:fixedSpace2];
        [toolBarButtons addObject:buttonAction];
    }
    
    if (_showToolBar) {
        // Set buttons to tool bar
        [toolBar setItems:toolBarButtons animated:YES];

    } else if (self.mode == TSMiniWebBrowserModeNavigation) {
        [self.navigationItem setRightBarButtonItems:toolBarButtons];
    }
}

-(void) initWebView
{
    CGSize viewSize = self.view.frame.size;
    if (self.mode == TSMiniWebBrowserModeModal) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight, viewSize.width, viewSize.height-kToolBarHeight*2)];
    } else if(self.mode == TSMiniWebBrowserModeNavigation) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, viewSize.width, viewSize.height-(_showToolBar*kToolBarHeight))];
    } else if(self.mode == TSMiniWebBrowserModeTabBar) {
        self.view.backgroundColor = [UIColor redColor];
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight-1, viewSize.width, viewSize.height-kToolBarHeight+1)];
    }
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:webView];
    
    webView.scalesPageToFit = YES;
    
    webView.delegate = self;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGFloat topInset = self.navigationController.navigationBar.frame.size.height
                         + [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGFloat bottomInset = self.tabBarController.tabBar.frame.size.height;
        UIEdgeInsets insets = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);
        webView.scrollView.contentInset = insets;
        webView.scrollView.scrollIndicatorInsets = insets;
    }
    
    // Load the URL in the webView
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:urlToLoad];
    [webView loadRequest:requestObj];
}

-(void)setTitleBarText:(NSString*)pageTitle
{
    if (self.mode == TSMiniWebBrowserModeModal) {
        navigationBarModal.topItem.title = pageTitle;
        
    } else if(self.mode == TSMiniWebBrowserModeNavigation) {
        if(pageTitle) [[self navigationItem] setTitle:pageTitle];
    }
}

- (void)setFixedTitleBarText:(NSString*)newTitleBarText
{
    forcedTitleBarText = newTitleBarText;
    self.showPageTitleOnTitleBar = NO;
}

- (void) viewWillAppear:(BOOL)animated
{
	for (id subview in self.view.subviews)
	{
		if ([subview isKindOfClass: [UIWebView class]])
		{
			UIWebView *sv = subview;
			[sv.scrollView setScrollsToTop:NO];
		}
	}
	
	[webView.scrollView setScrollsToTop:YES];
}

- (void)loadURL:(NSURL*)url
{
    [webView loadRequest: [NSURLRequest requestWithURL: url]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] hasPrefix:@"sms:"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
	
	else
	{
		if ([[request.URL absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
			[[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
			[[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"]) {
			[[UIApplication sharedApplication] openURL:request.URL];
			return NO;
		}
		
		else
		{
            if (self.domainLockList == nil || [self.domainLockList isEqualToString:@""])
            {
				if (navigationType == UIWebViewNavigationTypeLinkClicked)
				{
					self.currentURL = request.URL.absoluteString;
				}
                
                return YES;
            }
            
            else
            {
                NSArray *domainList = [self.domainLockList componentsSeparatedByString:@","];
                BOOL sendToSafari = YES;
                
                for (int x = 0; x < domainList.count; x++)
                {
                    if ([[request.URL absoluteString] hasPrefix:(NSString *)[domainList objectAtIndex:x]] == YES)
                    {
                        sendToSafari = NO;
                    }
                }
				
                if (sendToSafari == YES)
                {
                    [[UIApplication sharedApplication] openURL:[request URL]];
                    
                    return NO;
                }
                
                else
                {
					if (navigationType == UIWebViewNavigationTypeLinkClicked)
					{
						self.currentURL = request.URL.absoluteString;
					}
                    
                    return YES;
                }
            }
		}
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self toggleBackForwardButtons];
    
    [self showActivityIndicators];
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView
{
    // Show page title on title bar?
    if (self.showPageTitleOnTitleBar) {
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [self setTitleBarText:pageTitle];
    }
    
    [self hideActivityIndicators];
    
    [self toggleBackForwardButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideActivityIndicators];
    
    // To avoid getting an error alert when you click on a link
    // before a request has finished loading.
    if ([error code] == NSURLErrorCancelled) {
        return;
    }
	
    // Show error alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not load page", nil)
                                                    message:error.localizedDescription
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
	[alert show];
}

#pragma mark - Activity Indicators

-(void)showActivityIndicators
{
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)hideActivityIndicators
{
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Action Sheet

- (void)showActionSheet
{
    NSString *urlString = @"";
    if (self.showURLStringOnActionSheetTitle) {
        NSURL* url = [webView.request URL];
        urlString = [url absoluteString];
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = urlString;
    actionSheet.delegate = self;
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        // Chrome is installed, add the option to open in chrome.
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
    }
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (self.mode == TSMiniWebBrowserModeTabBar) {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    //else if (mode == TSMiniWebBrowserModeNavigation && [self.navigationController respondsToSelector:@selector(tabBarController)]) {
    else if (self.mode == TSMiniWebBrowserModeNavigation && self.navigationController.tabBarController != nil) {
        [actionSheet showFromTabBar:self.navigationController.tabBarController.tabBar];
    }
    else {
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet cancelButtonIndex]) return;
    
    NSURL *theURL = [webView.request URL];
    if (theURL == nil || [theURL isEqual:[NSURL URLWithString:@""]]) {
        theURL = urlToLoad;
    }
    
    if (buttonIndex == kSafariButtonIndex) {
        [[UIApplication sharedApplication] openURL:theURL];
    }
    else if (buttonIndex == kChromeButtonIndex) {
        NSString *scheme = theURL.scheme;
        
        // Replace the URL Scheme with the Chrome equivalent.
        NSString *chromeScheme = nil;
        if ([scheme isEqualToString:@"http"]) {
            chromeScheme = @"googlechrome";
        } else if ([scheme isEqualToString:@"https"]) {
            chromeScheme = @"googlechromes";
        }
        
        // Proceed only if a valid Google Chrome URI Scheme is available.
        if (chromeScheme) {
            NSString *absoluteString = [theURL absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
            NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
            
            // Open the URL with Chrome.
            [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
}

#pragma mark - Actions

- (void)backButtonTouchUp:(id)sender
{
    [webView goBack];
    
    [self toggleBackForwardButtons];
}

- (void)forwardButtonTouchUp:(id)sender
{
    [webView goForward];
    
    [self toggleBackForwardButtons];
}

- (void)reloadButtonTouchUp:(id)sender
{
    [webView reload];
    
    [self toggleBackForwardButtons];
}

- (void)buttonActionTouchUp:(id)sender
{
    [self showActionSheet];
}

-(void) toggleBackForwardButtons
{
    buttonGoBack.enabled = webView.canGoBack;
    buttonGoForward.enabled = webView.canGoForward;
}

#pragma mark - Interface Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/* Fix for landscape + zooming webview bug.
 * If you experience perfomance problems on old devices ratation, comment out this method.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat ratioAspect = webView.bounds.size.width/webView.bounds.size.height;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            // Going to Portrait mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale/ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale/ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale/ratioAspect) animated:YES];
                }
            }
            break;
        default:
            // Going to Landscape mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale *ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale *ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale*ratioAspect) animated:YES];
                }
            }
            break;
    }
}

#pragma mark - Teardown

-(void) dismissController
{
    if ( webView.loading ) {
        [webView stopLoading];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Notify the delegate
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(tsMiniWebBrowserDidDismiss)]) {
        [self.delegate tsMiniWebBrowserDidDismiss];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stop loading
    [webView stopLoading];
}

//Added in the dealloc method to remove the webview delegate, because if you use this in a navigation controller
//TSMiniWebBrowser can get deallocated while the page is still loading and the web view will call its delegate-- resulting in a crash
-(void)dealloc
{
    [webView setDelegate:nil];
}

@end
