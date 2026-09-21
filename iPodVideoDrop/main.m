#import <Cocoa/Cocoa.h>

@interface DropView : NSView
@property(nonatomic, copy) void (^handler)(NSArray<NSURL *> *urls);
@property(nonatomic) BOOL highlighted;
@end

@interface AppController : NSObject <NSApplicationDelegate>
@property(nonatomic,strong) NSWindow *window;
@property(nonatomic,strong) NSTextField *deviceLabel;
@property(nonatomic,strong) NSTextField *pathField;
@property(nonatomic,strong) NSTextField *statusLabel;
@property(nonatomic,strong) NSProgressIndicator *progress;
@property(nonatomic,strong) DropView *drop;
@property(nonatomic) BOOL converting;
@end

@implementation DropView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
        self.wantsLayer=YES;
    }
    return self;
}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    (void)sender;
    self.highlighted=YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
}
- (void)draggingExited:(id<NSDraggingInfo>)sender {
    (void)sender;
    self.highlighted=NO;
    [self setNeedsDisplay:YES];
}
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    self.highlighted=NO;
    [self setNeedsDisplay:YES];
    NSArray<NSURL*> *urls=[sender.draggingPasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey:@YES}];
    if(urls.count && self.handler) self.handler(urls);
    return urls.count>0;
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect r=NSInsetRect(self.bounds,1,1);
    NSBezierPath *p=[NSBezierPath bezierPathWithRoundedRect:r xRadius:22 yRadius:22];
    NSColor *fill=self.highlighted ? [NSColor colorWithCalibratedRed:0.92 green:0.96 blue:1 alpha:1] : [NSColor colorWithCalibratedWhite:0.985 alpha:1];
    [fill setFill];
    [p fill];
    [[NSColor colorWithCalibratedRed:0.95 green:0.72 blue:0.08 alpha:1] setStroke];
    p.lineWidth=self.highlighted?2:1;
    [p stroke];
    NSDictionary *a=@{NSFontAttributeName:[NSFont systemFontOfSize:25 weight:NSFontWeightSemibold],NSForegroundColorAttributeName:NSColor.labelColor};
    NSDictionary *b=@{NSFontAttributeName:[NSFont systemFontOfSize:14],NSForegroundColorAttributeName:NSColor.secondaryLabelColor};
    NSString *t=@"Drop videos here";
    NSString *s=@"Conversion starts automatically · iPod nano 7 Movie format";
    NSSize ta=[t sizeWithAttributes:a], tb=[s sizeWithAttributes:b];
    [t drawAtPoint:NSMakePoint(NSMidX(self.bounds)-ta.width/2,NSMidY(self.bounds)+10) withAttributes:a];
    [s drawAtPoint:NSMakePoint(NSMidX(self.bounds)-tb.width/2,NSMidY(self.bounds)-20) withAttributes:b];
}
@end

@implementation AppController
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    (void)n;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self buildMenu];
    [self buildUI];
    [self checkTools];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)s { (void)s; return YES; }

- (void)buildMenu {
    NSMenu *main=[[NSMenu alloc]initWithTitle:@"Main Menu"];
    NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:@"iPod Video Drop" action:nil keyEquivalent:@""];
    NSMenu *menu=[[NSMenu alloc]initWithTitle:@"iPod Video Drop"];
    [menu addItemWithTitle:@"About iPod Video Drop" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit=[[NSMenuItem alloc]initWithTitle:@"Quit iPod Video Drop" action:@selector(terminate:) keyEquivalent:@"q"];
    quit.keyEquivalentModifierMask=NSEventModifierFlagCommand;
    [menu addItem:quit];
    item.submenu=menu;
    [main addItem:item];
    [NSApp setMainMenu:main];
}

- (void)buildUI {
    CGFloat w=700,h=560;
    self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,w,h)
                                           styleMask:(NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable)
                                             backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"iPod Video Drop";
    self.window.minSize=NSMakeSize(620,500);
    NSView *c=self.window.contentView;

    self.deviceLabel=[NSTextField labelWithString:@"●  iPod nano 7 Movie Converter"];
    self.deviceLabel.frame=NSMakeRect(32,h-58,w-64,26);
    self.deviceLabel.font=[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold];
    self.deviceLabel.textColor=NSColor.secondaryLabelColor;
    [c addSubview:self.deviceLabel];

    NSTextField *send=[NSTextField labelWithString:@"Output"];
    send.frame=NSMakeRect(32,h-105,70,28);
    send.font=[NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
    [c addSubview:send];

    self.pathField=[NSTextField textFieldWithString:@"Same folder as original · _iPod.m4v"];
    self.pathField.frame=NSMakeRect(105,h-108,w-225,34);
    self.pathField.editable=NO;
    self.pathField.textColor=NSColor.secondaryLabelColor;
    [c addSubview:self.pathField];

    NSButton *info=[NSButton buttonWithTitle:@"Movie" target:self action:@selector(showInfo:)];
    info.frame=NSMakeRect(w-110,h-109,82,36);
    [c addSubview:info];

    self.drop=[[DropView alloc]initWithFrame:NSMakeRect(32,125,w-64,h-250)];
    __weak AppController *weak=self;
    self.drop.handler=^(NSArray<NSURL*> *u){ [weak convertURLs:u]; };
    [c addSubview:self.drop];

    self.progress=[[NSProgressIndicator alloc]initWithFrame:NSMakeRect(72,84,w-144,8)];
    self.progress.indeterminate=NO;
    self.progress.minValue=0;
    self.progress.maxValue=1;
    self.progress.doubleValue=0;
    self.progress.style=NSProgressIndicatorStyleBar;
    [c addSubview:self.progress];

    self.statusLabel=[NSTextField labelWithString:@"Ready · drop video files"];
    self.statusLabel.frame=NSMakeRect(32,48,w-64,26);
    self.statusLabel.alignment=NSTextAlignmentCenter;
    self.statusLabel.font=[NSFont systemFontOfSize:13];
    self.statusLabel.textColor=NSColor.secondaryLabelColor;
    self.statusLabel.lineBreakMode=NSLineBreakByTruncatingMiddle;
    [c addSubview:self.statusLabel];

    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)showInfo:(id)sender {
    (void)sender;
    NSAlert *a=[NSAlert new];
    a.messageText=@"Movie metadata";
    a.informativeText=@"Output is .m4v with H.264 + AAC. AtomicParsley writes stik=value=9, which is Movie metadata.";
    [a runModal];
}

- (NSString *)tool:(NSString *)name {
    NSArray *p=@[[@"/opt/homebrew/bin/" stringByAppendingString:name],[@"/usr/local/bin/" stringByAppendingString:name],[@"/usr/bin/" stringByAppendingString:name]];
    for(NSString *x in p) if([[NSFileManager defaultManager] isExecutableFileAtPath:x]) return x;
    return nil;
}

- (void)checkTools {
    NSString *ff=[self tool:@"ffmpeg"], *ap=[self tool:@"AtomicParsley"];
    if(ff && ap){
        self.deviceLabel.stringValue=@"●  Ready · FFmpeg + Movie metadata";
        self.deviceLabel.textColor=NSColor.systemGreenColor;
        return;
    }
    self.deviceLabel.stringValue=@"●  Installing required tools…";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        BOOL ok=[self installTools];
        dispatch_async(dispatch_get_main_queue(),^{
            if(ok){
                self.deviceLabel.stringValue=@"●  Ready · FFmpeg + Movie metadata";
                self.deviceLabel.textColor=NSColor.systemGreenColor;
                self.statusLabel.stringValue=@"Ready · drop video files";
            } else {
                self.deviceLabel.stringValue=@"●  FFmpeg / AtomicParsley missing";
                self.deviceLabel.textColor=NSColor.systemRedColor;
                self.statusLabel.stringValue=@"Install Homebrew, then relaunch";
            }
        });
    });
}

- (BOOL)installTools {
    NSString *brew=[self tool:@"brew"];
    if(!brew) return NO;
    NSTask *t=[NSTask new];
    t.executableURL=[NSURL fileURLWithPath:brew];
    t.arguments=@[@"install",@"ffmpeg",@"atomicparsley"];
    NSError *e=nil;
    if(![t launchAndReturnError:&e]) return NO;
    [t waitUntilExit];
    return t.terminationStatus==0;
}

- (BOOL)run:(NSString *)exe args:(NSArray<NSString*> *)args output:(NSString **)output {
    NSTask *t=[NSTask new];
    t.executableURL=[NSURL fileURLWithPath:exe];
    t.arguments=args;
    NSPipe *p=[NSPipe pipe];
    t.standardOutput=p;
    t.standardError=p;
    NSError *e=nil;
    if(![t launchAndReturnError:&e]){
        if(output) *output=e.localizedDescription ?: @"Could not start tool";
        return NO;
    }
    NSData *data=[[p fileHandleForReading] readDataToEndOfFile];
    [t waitUntilExit];
    NSString *text=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(!text) text=[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if(output) *output=text ?: @"";
    return t.terminationStatus==0;
}

- (NSString *)usefulError:(NSString *)text {
    if(text.length==0) return @"No diagnostic output";
    NSArray<NSString*> *lines=[text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    NSMutableArray<NSString*> *nonempty=[NSMutableArray array];
    for(NSString *line in lines){
        NSString *trim=[line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if(trim.length>0 && ![trim hasPrefix:@"ffmpeg version"] && ![trim hasPrefix:@"built with"] && ![trim hasPrefix:@"configuration:"] && ![trim hasPrefix:@"libav"]) [nonempty addObject:trim];
    }
    if(nonempty.count==0) return @"Unknown conversion error";
    NSUInteger start=nonempty.count>2 ? nonempty.count-2 : 0;
    return [[nonempty subarrayWithRange:NSMakeRange(start, nonempty.count-start)] componentsJoinedByString:@" · "];
}

- (BOOL)isVerticalVideo:(NSString *)input {
    NSString *ffprobe=[self tool:@"ffprobe"];
    if(!ffprobe) return NO;

    NSString *probeOutput=nil;
    BOOL ok=[self run:ffprobe
                 args:@[@"-v",@"error",
                        @"-select_streams",@"v:0",
                        @"-show_entries",@"stream=width,height:stream_side_data=rotation:stream_tags=rotate",
                        @"-of",@"default=nw=1", input]
               output:&probeOutput];
    if(!ok) return NO;

    // Phone clips are usually stored landscape with a 90° rotation flag; FFmpeg
    // applies that rotation while decoding, so judge by the displayed size.
    NSInteger width=0, height=0, rotation=0;
    for(NSString *line in [probeOutput componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]){
        if([line hasPrefix:@"width="]) width=[line substringFromIndex:6].integerValue;
        else if([line hasPrefix:@"height="]) height=[line substringFromIndex:7].integerValue;
        else if([line hasPrefix:@"rotation="]) rotation=[line substringFromIndex:9].integerValue;
        else if([line hasPrefix:@"TAG:rotate="] && rotation==0) rotation=[line substringFromIndex:11].integerValue;
    }
    if(labs(rotation)%180==90){ NSInteger t=width; width=height; height=t; }
    return width>0 && height>width;
}

- (NSArray<NSString*> *)ffmpegArgsForInput:(NSString *)input output:(NSString *)output {
    BOOL vertical=[self isVerticalVideo:input];

    // Portrait video: rotate 90° counter-clockwise (to the left),
    // then scale to the iPod-compatible frame.
    NSString *filter = vertical
        ? @"transpose=2,scale=640:480:force_original_aspect_ratio=decrease:force_divisible_by=2"
        : @"scale=640:480:force_original_aspect_ratio=decrease:force_divisible_by=2";

    return @[
        @"-hide_banner", @"-loglevel", @"error", @"-nostdin", @"-y",
        @"-i", input,
        @"-map", @"0:v:0", @"-map", @"0:a:0?", @"-sn", @"-dn",
        @"-map_metadata", @"-1", @"-map_chapters", @"-1",
        @"-vf", filter,
        @"-r", @"30", @"-fps_mode", @"cfr",
        @"-c:v", @"libx264", @"-preset", @"medium", @"-crf", @"21",
        @"-profile:v", @"baseline", @"-level:v", @"3.0", @"-pix_fmt", @"yuv420p",
        @"-c:a", @"aac", @"-aac_pns", @"0", @"-b:a", @"160k", @"-ac", @"2", @"-ar", @"44100",
        @"-movflags", @"+faststart", @"-f", @"ipod", output
    ];
}

- (BOOL)writeMovieMetadata:(NSString *)path error:(NSString **)errorText {
    NSString *ap=[self tool:@"AtomicParsley"];
    NSString *out=nil;
    BOOL ok=[self run:ap args:@[path,@"--metaEnema",@"--stik",@"value=9",@"--overWrite"] output:&out];
    if(ok) return YES;
    NSString *firstError=[self usefulError:out];
    ok=[self run:ap args:@[path,@"--metaEnema",@"--stik",@"Movie",@"--overWrite"] output:&out];
    if(ok) return YES;
    if(errorText) *errorText=[NSString stringWithFormat:@"AtomicParsley: %@", firstError];
    return NO;
}

- (void)convertURLs:(NSArray<NSURL*> *)urls {
    if(self.converting || urls.count==0) return;
    if(![self tool:@"ffmpeg"] || ![self tool:@"AtomicParsley"]){
        self.statusLabel.stringValue=@"Required tools are still unavailable";
        return;
    }
    self.converting=YES;
    self.progress.doubleValue=0;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        NSUInteger done=0, total=urls.count, failed=0;
        NSString *firstFailure=nil;
        NSFileManager *fm=NSFileManager.defaultManager;

        for(NSURL *u in urls){
            if(!u.isFileURL) continue;
            dispatch_async(dispatch_get_main_queue(),^{
                self.statusLabel.stringValue=[NSString stringWithFormat:@"Converting %@…",u.lastPathComponent];
            });

            NSString *base=[[u URLByDeletingPathExtension] path];
            NSString *out=[base stringByAppendingString:@"_iPod.m4v"];
            NSString *tmp=[base stringByAppendingString:@"_iPod.tmp.m4v"];
            [fm removeItemAtPath:tmp error:nil];

            NSString *diagnostic=nil;
            BOOL ok=[self run:[self tool:@"ffmpeg"] args:[self ffmpegArgsForInput:u.path output:tmp] output:&diagnostic];
            if(ok){
                NSString *metaError=nil;
                ok=[self writeMovieMetadata:tmp error:&metaError];
                if(!ok) diagnostic=metaError;
            }
            if(ok){
                // Replace an earlier _iPod.m4v only once the new one is complete.
                NSError *moveError=nil;
                [fm removeItemAtPath:out error:nil];
                ok=[fm moveItemAtPath:tmp toPath:out error:&moveError];
                if(!ok) diagnostic=moveError.localizedDescription;
            }
            if(!ok){
                failed++;
                [fm removeItemAtPath:tmp error:nil];
                if(!firstFailure){
                    NSString *reason=[self usefulError:diagnostic ?: @""];
                    firstFailure=[NSString stringWithFormat:@"%@ — %@",u.lastPathComponent,reason];
                }
            }
            done++;
            dispatch_async(dispatch_get_main_queue(),^{
                self.progress.doubleValue=(double)done/(double)total;
            });
        }

        dispatch_async(dispatch_get_main_queue(),^{
            self.converting=NO;
            if(failed==0){
                self.progress.doubleValue=1;
                self.statusLabel.stringValue=[NSString stringWithFormat:@"Done · %lu file%@ → .m4v · Movie (stik=9)",(unsigned long)done,done==1?@"":@"s"];
                self.statusLabel.textColor=NSColor.systemGreenColor;
            } else {
                self.statusLabel.stringValue=[NSString stringWithFormat:@"%lu failed · %@",(unsigned long)failed,firstFailure ?: @"See source format"];
                self.statusLabel.textColor=NSColor.systemRedColor;
            }
        });
    });
}
@end

int main(int argc,const char *argv[]) {
    @autoreleasepool {
        NSApplication *app=[NSApplication sharedApplication];
        AppController *delegate=[AppController new];
        app.delegate=delegate;
        return NSApplicationMain(argc,argv);
    }
}
