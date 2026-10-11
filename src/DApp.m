#import "DTheme.h"
#import "MeshL10n.h"

@interface DDisplayController : UIViewController @end
@interface DTouchController   : UIViewController @end
@interface DSensorController  : UIViewController @end
@interface DSysController     : UIViewController @end
@interface DStorageController : UIViewController @end
@interface DToneController    : UIViewController @end
@interface DMicController     : UIViewController @end

@interface DMenuController : UIViewController @end
@implementation DMenuController {
    UIScrollView *_sc;
    NSArray *_items;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor=DBG;
    self.title=L(@"Diagnostics");
    _sc=[[UIScrollView alloc] initWithFrame:self.view.bounds];
    _sc.alwaysBounceVertical=YES; [self.view addSubview:_sc];

    _items=@[@[L(@"Display / Pixel"), L(@"Find dead & stuck pixels"), @"DDisplayController"],
             @[L(@"Touch"),            L(@"Dead zones & multitouch"),  @"DTouchController"],
             @[L(@"Sensors"),          L(@"Orientation, gyro, level"), @"DSensorController"],
             @[L(@"CPU & RAM"),        L(@"Load & benchmark"),         @"DSysController"],
             @[L(@"Storage"),          L(@"Free/used & write speed"),  @"DStorageController"],
             @[L(@"Sound / Speaker"),  L(@"Frequencies & sweep"),      @"DToneController"],
             @[L(@"Microphone"),       L(@"Live level & recording"),   @"DMicController"]];

    CGFloat W=self.view.bounds.size.width, y=14, rh=66;
    for(int i=0;i<(int)_items.count;i++){
        NSArray*it=_items[i];
        UIButton*card=[UIButton buttonWithType:UIButtonTypeCustom];
        card.frame=CGRectMake(14,y,W-28,rh); card.backgroundColor=DCARD;
        card.layer.cornerRadius=14; card.layer.borderWidth=0.5; card.layer.borderColor=DLINE.CGColor;
        card.tag=i; [card addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        UILabel*t=[[UILabel alloc] initWithFrame:CGRectMake(16,12,W-80,22)];
        t.text=it[0]; t.font=[UIFont boldSystemFontOfSize:17]; t.textColor=DINK; t.backgroundColor=[UIColor clearColor]; [card addSubview:t];
        UILabel*s=[[UILabel alloc] initWithFrame:CGRectMake(16,36,W-80,18)];
        s.text=it[1]; s.font=[UIFont systemFontOfSize:13]; s.textColor=DMUT; s.backgroundColor=[UIColor clearColor]; [card addSubview:s];
        UILabel*ch=[[UILabel alloc] initWithFrame:CGRectMake(W-28-40,0,30,rh)];
        ch.text=@"›"; ch.font=[UIFont systemFontOfSize:26]; ch.textColor=DLINE; ch.textAlignment=NSTextAlignmentCenter; ch.backgroundColor=[UIColor clearColor]; [card addSubview:ch];
        [_sc addSubview:card]; y+=rh+12;
    }
    _sc.contentSize=CGSizeMake(W,y+8);
}
- (void)tap:(UIButton *)b {
    NSString*cls=_items[b.tag][2];
    UIViewController*vc=[[NSClassFromString(cls) alloc] init];
    vc.title=_items[b.tag][0];
    if(vc) [self.navigationController pushViewController:vc animated:YES];
}
@end

@interface DAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation DAppDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
    self.window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UINavigationController*nav=[[UINavigationController alloc] initWithRootViewController:[[DMenuController alloc] init]];
    nav.navigationBar.tintColor=DBLU;   // blaue Leiste -> Zurück-Button sichtbar
    nav.navigationBar.titleTextAttributes=@{ UITextAttributeTextColor:[UIColor whiteColor] };
    self.window.rootViewController=nav;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
