#import <UIKit/UIKit.h>
// Hell & klar, Akzent Blau
static inline UIColor* DC(int r,int g,int b){ return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }
#define DBG    DC(242,242,247)
#define DCARD  [UIColor whiteColor]
#define DTRACK DC(229,229,234)
#define DLINE  DC(209,209,214)
#define DINK   DC(0,0,0)
#define DMUT   DC(142,142,147)
#define DBLU   DC(0,122,255)
#define DGRN   DC(52,199,89)
#define DYEL   DC(255,149,0)
#define DRED   DC(255,59,48)
