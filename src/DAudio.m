#import "DTheme.h"
#import "MeshL10n.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

// WAV (PCM 16-bit mono) aus Samples bauen
static void le32(NSMutableData*d,uint32_t v){ uint8_t b[4]={v&0xff,(v>>8)&0xff,(v>>16)&0xff,(v>>24)&0xff}; [d appendBytes:b length:4]; }
static void le16(NSMutableData*d,uint16_t v){ uint8_t b[2]={v&0xff,(v>>8)&0xff}; [d appendBytes:b length:2]; }
static NSData* wavFromSamples(int16_t*s,int count,int rate){
    NSMutableData*d=[NSMutableData data]; int dataBytes=count*2;
    [d appendBytes:"RIFF" length:4]; le32(d,36+dataBytes); [d appendBytes:"WAVE" length:4];
    [d appendBytes:"fmt " length:4]; le32(d,16); le16(d,1); le16(d,1);
    le32(d,rate); le32(d,rate*2); le16(d,2); le16(d,16);
    [d appendBytes:"data" length:4]; le32(d,dataBytes); [d appendBytes:s length:dataBytes];
    return d;
}
static NSData* makeTone(double freq,double secs){
    int rate=44100,n=(int)(rate*secs); int16_t*s=malloc(n*2);
    for(int i=0;i<n;i++){ double env=1.0; s[i]=(int16_t)(sin(2*M_PI*freq*i/rate)*28000*env); }
    NSData*d=wavFromSamples(s,n,rate); free(s); return d;
}
static NSData* makeSweep(double f0,double f1,double secs){
    int rate=44100,n=(int)(rate*secs); int16_t*s=malloc(n*2); double phase=0;
    for(int i=0;i<n;i++){ double t=(double)i/n; double f=f0*pow(f1/f0,t); phase+=2*M_PI*f/rate; s[i]=(int16_t)(sin(phase)*28000); }
    NSData*d=wavFromSamples(s,n,rate); free(s); return d;
}

// ================= Ton / Lautsprecher =================
@interface DToneController : UIViewController @end
@implementation DToneController {
    AVAudioPlayer *_pl; UILabel *_now;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width;
    @try { [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
           [[AVAudioSession sharedInstance] setActive:YES error:nil]; } @catch(__unused id e){}

    UILabel*info=[[UILabel alloc] initWithFrame:CGRectMake(16,14,W-32,40)]; info.numberOfLines=2; info.font=[UIFont systemFontOfSize:13]; info.textColor=DMUT; info.textAlignment=NSTextAlignmentCenter; info.backgroundColor=[UIColor clearColor];
    info.text=L(@"Plays test tones through the speaker. All clean & without crackle = ok."); [self.view addSubview:info];

    _now=[[UILabel alloc] initWithFrame:CGRectMake(0,64,W,40)]; _now.font=[UIFont boldSystemFontOfSize:30]; _now.textColor=DINK; _now.textAlignment=NSTextAlignmentCenter; _now.backgroundColor=[UIColor clearColor]; _now.text=@"—"; [self.view addSubview:_now];

    NSArray*freqs=@[@100,@440,@1000,@5000,@10000];
    NSArray*labs =@[@"100 Hz",@"440 Hz",@"1 kHz",@"5 kHz",@"10 kHz"];
    CGFloat y=120,bw=(W-28-10)/2.0;
    for(int i=0;i<(int)freqs.count;i++){
        UIButton*b=[UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat bx=14+(i%2)*(bw+10), by=y+(i/2)*54;
        b.frame=CGRectMake(bx,by,bw,46); b.backgroundColor=DCARD; b.layer.cornerRadius=12; b.layer.borderWidth=0.5; b.layer.borderColor=DLINE.CGColor;
        [b setTitle:labs[i] forState:UIControlStateNormal]; [b setTitleColor:DINK forState:UIControlStateNormal]; b.titleLabel.font=[UIFont boldSystemFontOfSize:16];
        b.tag=[freqs[i] intValue]; [b addTarget:self action:@selector(tone:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:b];
    }
    UIButton*sw=[UIButton buttonWithType:UIButtonTypeCustom]; sw.frame=CGRectMake(14,y+3*54,W-28,46); sw.backgroundColor=DBLU; sw.layer.cornerRadius=12;
    [sw setTitle:L(@"Sweep 20 Hz → 15 kHz") forState:UIControlStateNormal]; [sw setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; sw.titleLabel.font=[UIFont boldSystemFontOfSize:16];
    [sw addTarget:self action:@selector(sweep) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:sw];

    UIButton*st=[UIButton buttonWithType:UIButtonTypeCustom]; st.frame=CGRectMake(14,y+3*54+58,W-28,42); st.backgroundColor=DTRACK; st.layer.cornerRadius=12;
    [st setTitle:L(@"Stop") forState:UIControlStateNormal]; [st setTitleColor:DINK forState:UIControlStateNormal]; st.titleLabel.font=[UIFont boldSystemFontOfSize:15];
    [st addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:st];
}
- (void)playData:(NSData *)d loop:(BOOL)loop label:(NSString *)l {
    [_pl stop]; _pl=[[AVAudioPlayer alloc] initWithData:d error:nil];
    _pl.numberOfLoops= loop?-1:0; [_pl prepareToPlay]; [_pl play]; _now.text=l;
}
- (void)tone:(UIButton *)b { double f=b.tag; [self playData:makeTone(f,1.0) loop:YES label:[b titleForState:UIControlStateNormal]]; }
- (void)sweep { [self playData:makeSweep(20,15000,4.0) loop:NO label:L(@"Sweep")]; }
- (void)stop { [_pl stop]; _pl=nil; _now.text=@"—"; }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self stop]; }
@end

// ================= Mikrofon =================
@interface DMicController : UIViewController @end
@implementation DMicController {
    AVAudioRecorder *_rec; NSTimer *_t; UIView *_bar; CGFloat _barW; UILabel *_db,*_peak; float _peakHold;
    AVAudioPlayer *_play;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=DBG;
    CGFloat W=self.view.bounds.size.width;
    UILabel*info=[[UILabel alloc] initWithFrame:CGRectMake(16,14,W-32,40)]; info.numberOfLines=2; info.font=[UIFont systemFontOfSize:13]; info.textColor=DMUT; info.textAlignment=NSTextAlignmentCenter; info.backgroundColor=[UIColor clearColor];
    info.text=L(@"Speak or tap — the level must move. No reaction = microphone problem."); [self.view addSubview:info];

    _db=[[UILabel alloc] initWithFrame:CGRectMake(0,66,W,44)]; _db.font=[UIFont boldSystemFontOfSize:34]; _db.textColor=DINK; _db.textAlignment=NSTextAlignmentCenter; _db.backgroundColor=[UIColor clearColor]; _db.text=@"— dB"; [self.view addSubview:_db];

    CGFloat cy=130; _barW=W-40;
    UIView*bg=[[UIView alloc] initWithFrame:CGRectMake(20,cy,_barW,22)]; bg.backgroundColor=DTRACK; bg.layer.cornerRadius=11; [self.view addSubview:bg];
    _bar=[[UIView alloc] initWithFrame:CGRectMake(20,cy,0,22)]; _bar.backgroundColor=DGRN; _bar.layer.cornerRadius=11; [self.view addSubview:_bar];
    _peak=[[UILabel alloc] initWithFrame:CGRectMake(20,cy+30,_barW,18)]; _peak.font=[UIFont systemFontOfSize:12]; _peak.textColor=DMUT; _peak.textAlignment=NSTextAlignmentCenter; _peak.backgroundColor=[UIColor clearColor]; [self.view addSubview:_peak];

    @try {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } @catch(__unused id e){}
    NSDictionary*set=@{AVFormatIDKey:@(kAudioFormatAppleIMA4), AVSampleRateKey:@44100.0, AVNumberOfChannelsKey:@1, AVEncoderAudioQualityKey:@(AVAudioQualityMedium)};
    NSURL*url=[NSURL fileURLWithPath:@"/var/mobile/Media/.diagmic.caf"];
    _rec=[[AVAudioRecorder alloc] initWithURL:url settings:set error:nil];
    _rec.meteringEnabled=YES;
}
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a];
    _peakHold=-160; [_rec record];
    _t=[NSTimer scheduledTimerWithTimeInterval:1.0/15.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [_t invalidate]; _t=nil; [_rec stop]; [_play stop]; }
- (void)tick {
    [_rec updateMeters];
    float db=[_rec averagePowerForChannel:0];        // -160..0
    if(db>_peakHold)_peakHold=db;
    float norm=(db+60)/60.0; if(norm<0)norm=0; if(norm>1)norm=1;   // -60..0 dB -> 0..1
    _bar.frame=CGRectMake(20,130,_barW*norm,22);
    _bar.backgroundColor = (norm>0.85)?DRED:(norm>0.5?DYEL:DGRN);
    _db.text=[NSString stringWithFormat:@"%.0f dB",db];
    _peak.text=LF(@"Peak: %.0f dB",_peakHold);
}
@end
