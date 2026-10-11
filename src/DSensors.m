#import "DTheme.h"
#import "MeshL10n.h"
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <sys/mount.h>

// ===== kleine Werte-Zeile =====
static UILabel* valueRow(UIView*parent, CGFloat y, NSString*key){
    CGFloat W=parent.bounds.size.width;
    UILabel*k=[[UILabel alloc] initWithFrame:CGRectMake(14,y,W*0.5,24)]; k.text=key; k.font=[UIFont systemFontOfSize:15]; k.textColor=DMUT; k.backgroundColor=[UIColor clearColor]; [parent addSubview:k];
    UILabel*v=[[UILabel alloc] initWithFrame:CGRectMake(W*0.5-14,y,W*0.5,24)]; v.font=[UIFont boldSystemFontOfSize:15]; v.textColor=DINK; v.textAlignment=NSTextAlignmentRight; v.backgroundColor=[UIColor clearColor]; [parent addSubview:v];
    return v;
}

// ================= Sensoren =================
@interface DLevelView : UIView
@property(nonatomic) CGFloat ax, ay;
@end
@implementation DLevelView
- (void)drawRect:(CGRect)r {
    CGContextRef c=UIGraphicsGetCurrentContext();
    CGFloat w=self.bounds.size.width,h=self.bounds.size.height,cx=w/2,cy=h/2,rad=MIN(w,h)/2-6;
    [DTRACK setStroke]; CGContextSetLineWidth(c,1);
    CGContextStrokeEllipseInRect(c,CGRectMake(cx-rad,cy-rad,rad*2,rad*2));
    CGContextStrokeEllipseInRect(c,CGRectMake(cx-rad*0.33,cy-rad*0.33,rad*0.66,rad*0.66));
    CGContextMoveToPoint(c,cx-rad,cy); CGContextAddLineToPoint(c,cx+rad,cy);
    CGContextMoveToPoint(c,cx,cy-rad); CGContextAddLineToPoint(c,cx,cy+rad); CGContextStrokePath(c);
    CGFloat bx=cx+self.ax*rad, by=cy+self.ay*rad;  // ax,ay in g
    BOOL level=(fabs(self.ax)<0.04 && fabs(self.ay)<0.04);
    [(level?DGRN:DBLU) setFill];
    CGContextFillEllipseInRect(c,CGRectMake(bx-14,by-14,28,28));
}
@end

@interface DSensorController : UIViewController @end
@implementation DSensorController {
    CMMotionManager *_mm; NSTimer *_t;
    DLevelView *_lv; UILabel *_vA,*_vG,*_vTilt,*_vState;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width;
    UIView*card=[[UIView alloc] initWithFrame:CGRectMake(14,14,W-28,210)]; card.backgroundColor=DCARD; card.layer.cornerRadius=14; card.layer.borderWidth=0.5; card.layer.borderColor=DLINE.CGColor; [self.view addSubview:card];
    _lv=[[DLevelView alloc] initWithFrame:CGRectMake(5,5,card.bounds.size.width-10,200)]; _lv.backgroundColor=[UIColor clearColor]; [card addSubview:_lv];

    UIView*card2=[[UIView alloc] initWithFrame:CGRectMake(14,236,W-28,160)]; card2.backgroundColor=DCARD; card2.layer.cornerRadius=14; card2.layer.borderWidth=0.5; card2.layer.borderColor=DLINE.CGColor; [self.view addSubview:card2];
    _vA=valueRow(card2,14,L(@"Acceleration (g)"));
    _vG=valueRow(card2,50,L(@"Rotation rate (°/s)"));
    _vTilt=valueRow(card2,86,L(@"Tilt"));
    _vState=valueRow(card2,122,L(@"Status"));

    _mm=[[CMMotionManager alloc] init];
    _mm.accelerometerUpdateInterval=1.0/30.0; _mm.gyroUpdateInterval=1.0/30.0;
    if(_mm.accelerometerAvailable)[_mm startAccelerometerUpdates];
    if(_mm.gyroAvailable)[_mm startGyroUpdates];
}
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; _t=[NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(tick) userInfo:nil repeats:YES]; }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [_t invalidate]; _t=nil; [_mm stopAccelerometerUpdates]; [_mm stopGyroUpdates]; }
- (void)tick {
    CMAcceleration ac={0,0,0}; CMRotationRate gy={0,0,0};
    BOOL haveA=NO, haveG=NO;
    if(_mm.accelerometerData){ ac=_mm.accelerometerData.acceleration; haveA=YES; }
    if(_mm.gyroData){ gy=_mm.gyroData.rotationRate; haveG=YES; }
    _lv.ax=ac.x; _lv.ay=-ac.y; [_lv setNeedsDisplay];
    _vA.text = haveA?[NSString stringWithFormat:@"%.2f  %.2f  %.2f",ac.x,ac.y,ac.z]:L(@"n/a");
    _vG.text = haveG?[NSString stringWithFormat:@"%.0f  %.0f  %.0f",gy.x*57.3,gy.y*57.3,gy.z*57.3]:L(@"n/a");
    double pitch=atan2(-ac.x, sqrt(ac.y*ac.y+ac.z*ac.z))*57.3;
    double roll =atan2(ac.y, ac.z)*57.3;
    _vTilt.text=[NSString stringWithFormat:@"%.0f° / %.0f°",pitch,roll];
    BOOL level=(fabs(ac.x)<0.04 && fabs(ac.y)<0.04);
    _vState.text= haveA?(level?L(@"level ✓"):L(@"tilted")):L(@"no sensor");
    _vState.textColor= level?DGRN:DMUT;
}
@end

// ================= CPU & RAM =================
static double gPU=0,gPT=0;
static float cpuLoad(void){
    host_cpu_load_info_data_t info; mach_msg_type_number_t cnt=HOST_CPU_LOAD_INFO_COUNT;
    if(host_statistics(mach_host_self(),HOST_CPU_LOAD_INFO,(host_info_t)&info,&cnt)!=KERN_SUCCESS) return -1;
    double used=info.cpu_ticks[CPU_STATE_USER]+info.cpu_ticks[CPU_STATE_SYSTEM]+info.cpu_ticks[CPU_STATE_NICE];
    double total=used+info.cpu_ticks[CPU_STATE_IDLE];
    double du=used-gPU, dt=total-gPT; gPU=used; gPT=total;
    if(dt<=0) return 0; return (float)(du/dt*100.0);
}
static void ramStat(double*usedMB,double*totalMB){
    int64_t total=0; size_t len=sizeof(total); sysctlbyname("hw.memsize",&total,&len,NULL,0);
    vm_statistics_data_t vm; mach_msg_type_number_t cnt=HOST_VM_INFO_COUNT;
    vm_size_t page=4096; host_page_size(mach_host_self(),&page);
    double freeB=0;
    if(host_statistics(mach_host_self(),HOST_VM_INFO,(host_info_t)&vm,&cnt)==KERN_SUCCESS)
        freeB=(double)(vm.free_count+vm.inactive_count)*page;
    *totalMB=total/1048576.0; *usedMB=(total-freeB)/1048576.0;
}

@interface DSysController : UIViewController @end
@implementation DSysController {
    NSTimer *_t; UILabel *_vCPU,*_vRAM,*_vBench; UIView *_cpuBar,*_ramBar; CGFloat _barW;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width;
    UIView*card=[[UIView alloc] initWithFrame:CGRectMake(14,14,W-28,200)]; card.backgroundColor=DCARD; card.layer.cornerRadius=14; card.layer.borderWidth=0.5; card.layer.borderColor=DLINE.CGColor; [self.view addSubview:card];
    _barW=card.bounds.size.width-28;
    _vCPU=valueRow(card,14,L(@"CPU load"));
    UIView*cbg=[[UIView alloc] initWithFrame:CGRectMake(14,42,_barW,8)]; cbg.backgroundColor=DTRACK; cbg.layer.cornerRadius=4; [card addSubview:cbg];
    _cpuBar=[[UIView alloc] initWithFrame:CGRectMake(14,42,0,8)]; _cpuBar.backgroundColor=DBLU; _cpuBar.layer.cornerRadius=4; [card addSubview:_cpuBar];
    _vRAM=valueRow(card,66,L(@"RAM"));
    UIView*rbg=[[UIView alloc] initWithFrame:CGRectMake(14,94,_barW,8)]; rbg.backgroundColor=DTRACK; rbg.layer.cornerRadius=4; [card addSubview:rbg];
    _ramBar=[[UIView alloc] initWithFrame:CGRectMake(14,94,0,8)]; _ramBar.backgroundColor=DGRN; _ramBar.layer.cornerRadius=4; [card addSubview:_ramBar];
    _vBench=valueRow(card,120,L(@"Benchmark")); _vBench.text=@"—";

    UIButton*bb=[UIButton buttonWithType:UIButtonTypeCustom]; bb.frame=CGRectMake(14,158,_barW,34); bb.backgroundColor=DBLU; bb.layer.cornerRadius=17;
    [bb setTitle:L(@"Start benchmark") forState:UIControlStateNormal]; [bb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; bb.titleLabel.font=[UIFont boldSystemFontOfSize:15];
    [bb addTarget:self action:@selector(bench) forControlEvents:UIControlEventTouchUpInside]; [card addSubview:bb];
    cpuLoad(); // prime
}
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; _t=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES]; [self tick]; }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [_t invalidate]; _t=nil; }
- (void)tick {
    float cpu=cpuLoad(); if(cpu<0)cpu=0; if(cpu>100)cpu=100;
    _vCPU.text=[NSString stringWithFormat:@"%.0f %%",cpu];
    _cpuBar.frame=CGRectMake(14,42,_barW*cpu/100.0,8);
    double used,total; ramStat(&used,&total);
    _vRAM.text=[NSString stringWithFormat:@"%.0f / %.0f MB",used,total];
    _ramBar.frame=CGRectMake(14,94,_barW*(total>0?used/total:0),8);
}
- (void)bench {
    _vBench.text=L(@"running…");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.05*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        NSDate*s=[NSDate date]; volatile double x=1.1;
        for(int k=0;k<8000000;k++){ x=sqrt(fabs(x*1.0001)+1.0)+sin(x)+cos(x*0.5); }
        double dt=-[s timeIntervalSinceNow];
        _vBench.text=LF(@"%.2f s  (↓ = faster)",dt);
    });
}
@end

// ================= Speicher =================
@interface DStorageController : UIViewController @end
@implementation DStorageController {
    UILabel *_vFree,*_vUsed,*_vTotal,*_vWrite,*_vRead; UIView *_bar; CGFloat _barW;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width;
    UIView*card=[[UIView alloc] initWithFrame:CGRectMake(14,14,W-28,210)]; card.backgroundColor=DCARD; card.layer.cornerRadius=14; card.layer.borderWidth=0.5; card.layer.borderColor=DLINE.CGColor; [self.view addSubview:card];
    _barW=card.bounds.size.width-28;
    UIView*bg=[[UIView alloc] initWithFrame:CGRectMake(14,16,_barW,12)]; bg.backgroundColor=DTRACK; bg.layer.cornerRadius=6; [card addSubview:bg];
    _bar=[[UIView alloc] initWithFrame:CGRectMake(14,16,0,12)]; _bar.backgroundColor=DBLU; _bar.layer.cornerRadius=6; [card addSubview:_bar];
    _vUsed=valueRow(card,40,L(@"Used"));
    _vFree=valueRow(card,74,L(@"Free"));
    _vTotal=valueRow(card,108,L(@"Total"));
    _vWrite=valueRow(card,142,L(@"Write")); _vWrite.text=@"—";
    _vRead=valueRow(card,170,L(@"Read")); _vRead.text=@"—";

    UIButton*bb=[UIButton buttonWithType:UIButtonTypeCustom]; bb.frame=CGRectMake(14,236,_barW,38); bb.backgroundColor=DBLU; bb.layer.cornerRadius=19;
    [bb setTitle:L(@"Speed test (16 MB)") forState:UIControlStateNormal]; [bb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; bb.titleLabel.font=[UIFont boldSystemFontOfSize:15];
    [bb addTarget:self action:@selector(speed) forControlEvents:UIControlEventTouchUpInside];
    bb.frame=CGRectMake(14,236,W-28,38); [self.view addSubview:bb];
    [self refresh];
}
- (void)refresh {
    struct statfs st;
    if(statfs("/var/mobile",&st)!=0){ if(statfs("/",&st)!=0){ _vTotal.text=L(@"n/a"); return; } }
    double total=(double)st.f_blocks*st.f_bsize, freeB=(double)st.f_bavail*st.f_bsize, used=total-freeB;
    _vTotal.text=[NSString stringWithFormat:@"%.1f GB",total/1e9];
    _vFree.text =[NSString stringWithFormat:@"%.1f GB",freeB/1e9];
    _vUsed.text =[NSString stringWithFormat:@"%.1f GB",used/1e9];
    _bar.frame=CGRectMake(14,16,_barW*(total>0?used/total:0),12);
}
- (void)speed {
    _vWrite.text=L(@"running…"); _vRead.text=@"…";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        const int MB=16; size_t n=MB*1024*1024; char*buf=malloc(n);
        if(!buf){ dispatch_async(dispatch_get_main_queue(),^{ _vWrite.text=L(@"Error"); }); return; }
        memset(buf,0xA5,n);
        NSString*path=@"/var/mobile/Media/.diagspeed";
        double wMBs=0,rMBs=0;
        NSDate*t0=[NSDate date];
        FILE*f=fopen(path.UTF8String,"wb");
        if(f){ fwrite(buf,1,n,f); fflush(f); fsync(fileno(f)); fclose(f); wMBs=MB/(-[t0 timeIntervalSinceNow]); }
        NSDate*t1=[NSDate date];
        f=fopen(path.UTF8String,"rb");
        if(f){ while(fread(buf,1,1024*1024,f)>0){} fclose(f); rMBs=MB/(-[t1 timeIntervalSinceNow]); }
        unlink(path.UTF8String); free(buf);
        dispatch_async(dispatch_get_main_queue(),^{
            _vWrite.text = wMBs>0?[NSString stringWithFormat:@"%.1f MB/s",wMBs]:L(@"Error");
            _vRead.text  = rMBs>0?[NSString stringWithFormat:@"%.1f MB/s",rMBs]:L(@"Error");
        });
    });
}
@end
