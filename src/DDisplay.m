#import "DTheme.h"
#import "MeshL10n.h"
#import <QuartzCore/QuartzCore.h>

// ================= Display / Pixel =================
@interface DDisplayController : UIViewController @end
@implementation DDisplayController {
    NSArray *_cols; NSArray *_names; int _i;
    UILabel *_lbl; UIView *_fill;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _cols=@[[UIColor redColor],[UIColor greenColor],[UIColor blueColor],[UIColor whiteColor],[UIColor blackColor],DC(128,128,128)];
    _names=@[L(@"Red"),L(@"Green"),L(@"Blue"),L(@"White"),L(@"Black"),L(@"Gray")];
    _i=0;
    _fill=[[UIView alloc] initWithFrame:self.view.bounds]; _fill.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; [self.view addSubview:_fill];
    _lbl=[[UILabel alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height-70,self.view.bounds.size.width,24)];
    _lbl.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    _lbl.textAlignment=NSTextAlignmentCenter; _lbl.font=[UIFont boldSystemFontOfSize:15]; _lbl.backgroundColor=[UIColor clearColor]; [self.view addSubview:_lbl];

    UIButton*back=[UIButton buttonWithType:UIButtonTypeCustom]; back.frame=CGRectMake(10,24,96,34);
    back.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.5]; back.layer.cornerRadius=17;
    [back setTitle:L(@"✕ Back") forState:UIControlStateNormal]; [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    back.titleLabel.font=[UIFont boldSystemFontOfSize:14];
    [back addTarget:self action:@selector(leave) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:back];

    UITapGestureRecognizer*tg=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(next)];
    [self.view addGestureRecognizer:tg];
    [self show];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self.navigationController setNavigationBarHidden:YES animated:a]; }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self.navigationController setNavigationBarHidden:NO animated:a]; }
- (BOOL)prefersStatusBarHidden { return YES; }
- (void)show {
    _fill.backgroundColor=_cols[_i];
    BOOL dark=(_i==4)||(_i==2);
    _lbl.textColor=dark?[UIColor whiteColor]:[UIColor blackColor];
    _lbl.text=LF(@"%@  (%d/%d) — tap to cycle", _names[_i], _i+1, (int)_cols.count);
}
- (void)next { _i=(_i+1)%_cols.count; [self show]; }
- (void)leave { [self.navigationController popViewControllerAnimated:YES]; }
@end

// ================= Touch =================
@interface DTouchView : UIView
@property(nonatomic,strong) NSMutableSet *live;   // aktuelle Berührungspunkte (NSValue CGPoint)
- (void)reset;
@end
@implementation DTouchView {
    int _cols, _rowsN; CGFloat _cw, _chh;
    char *_hit;   // Raster getroffen?
}
- (id)initWithFrame:(CGRect)f {
    if((self=[super initWithFrame:f])){
        self.backgroundColor=DCARD; self.multipleTouchEnabled=YES;
        _live=[NSMutableSet set];
        _cols=10; _rowsN=0; // lazy
    }
    return self;
}
- (void)layoutSubviews { [super layoutSubviews];
    _cw=self.bounds.size.width/_cols; _rowsN=(int)ceil(self.bounds.size.height/_cw); _chh=self.bounds.size.height/_rowsN;
    if(_hit){ free(_hit); } _hit=calloc(_cols*_rowsN,1);
}
- (void)reset { if(_hit) memset(_hit,0,_cols*_rowsN); [_live removeAllObjects]; [self setNeedsDisplay]; }
- (void)mark:(NSSet *)touches {
    [_live removeAllObjects];
    for(UITouch*t in touches){ if(t.phase==UITouchPhaseEnded||t.phase==UITouchPhaseCancelled) continue;
        CGPoint p=[t locationInView:self]; [_live addObject:[NSValue valueWithCGPoint:p]];
        int cx=(int)(p.x/_cw), cy=(int)(p.y/_chh);
        if(cx>=0&&cx<_cols&&cy>=0&&cy<_rowsN) _hit[cy*_cols+cx]=1;
    }
    [self setNeedsDisplay];
}
- (void)touchesBegan:(NSSet *)t withEvent:(UIEvent *)e { [self mark:[e allTouches]]; }
- (void)touchesMoved:(NSSet *)t withEvent:(UIEvent *)e { [self mark:[e allTouches]]; }
- (void)touchesEnded:(NSSet *)t withEvent:(UIEvent *)e { [_live removeAllObjects]; [self setNeedsDisplay]; }
- (void)touchesCancelled:(NSSet *)t withEvent:(UIEvent *)e { [_live removeAllObjects]; [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)r {
    CGContextRef c=UIGraphicsGetCurrentContext();
    for(int y=0;y<_rowsN;y++) for(int x=0;x<_cols;x++){
        CGRect cell=CGRectMake(x*_cw,y*_chh,_cw,_chh);
        if(_hit[y*_cols+x]){ [DC(52,199,89) setFill]; CGContextFillRect(c,CGRectInset(cell,0.5,0.5)); }
    }
    [DTRACK setStroke]; CGContextSetLineWidth(c,0.5);
    for(int x=0;x<=_cols;x++){ CGContextMoveToPoint(c,x*_cw,0); CGContextAddLineToPoint(c,x*_cw,self.bounds.size.height); }
    for(int y=0;y<=_rowsN;y++){ CGContextMoveToPoint(c,0,y*_chh); CGContextAddLineToPoint(c,self.bounds.size.width,y*_chh); }
    CGContextStrokePath(c);
    [DBLU setFill];
    for(NSValue*v in _live){ CGPoint p=[v CGPointValue]; CGContextFillEllipseInRect(c,CGRectMake(p.x-22,p.y-22,44,44)); }
}
- (void)dealloc { if(_hit) free(_hit); }
@end

@interface DTouchController : UIViewController @end
@implementation DTouchController {
    DTouchView *_tv; UILabel *_hint;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height;
    _hint=[[UILabel alloc] initWithFrame:CGRectMake(12,8,W-24,34)];
    _hint.numberOfLines=2; _hint.font=[UIFont systemFontOfSize:12]; _hint.textColor=DMUT; _hint.textAlignment=NSTextAlignmentCenter; _hint.backgroundColor=[UIColor clearColor];
    _hint.text=L(@"Swipe across the whole screen — gray cells = dead zones. Multiple fingers are shown.");
    [self.view addSubview:_hint];
    _tv=[[DTouchView alloc] initWithFrame:CGRectMake(10,48,W-20,H-48-58)]; _tv.layer.cornerRadius=12; _tv.clipsToBounds=YES; _tv.layer.borderWidth=0.5; _tv.layer.borderColor=DLINE.CGColor; [self.view addSubview:_tv];
    UIButton*rb=[UIButton buttonWithType:UIButtonTypeCustom]; rb.frame=CGRectMake(W/2-70,H-50,140,38);
    rb.backgroundColor=DBLU; rb.layer.cornerRadius=19; [rb setTitle:L(@"Reset") forState:UIControlStateNormal];
    [rb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; rb.titleLabel.font=[UIFont boldSystemFontOfSize:15];
    [rb addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:rb];
}
- (void)reset { [_tv reset]; }
@end
