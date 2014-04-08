#import "ViewController.h"

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

static float const kTileScale = 1.0;
static int const kPadding     = 2;
static int const kNumTiles    = 7;

@implementation ViewController
{
	BigTile* _bigTile;
    SmallTile* _draggedTile;
    NSMutableArray* _grid;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _grid = [[NSMutableArray alloc] init];
    for (int i = 0; i < 15; i++) {
        NSMutableArray *row = [[NSMutableArray alloc] init];
        for (int j = 0; j < 15; j++) {
            [row addObject:[NSNull null]];
        }
        [_grid addObject:row];
    }
    
    for (int i = 0; i < kNumTiles; i++) {
        SmallTile *tile = [[[NSBundle mainBundle] loadNibNamed:@"SmallTile"
                                                         owner:self
                                                       options:nil] firstObject];
        [self.view addSubview:tile];
    }
    
    [self adjustZoom];
    [self adjustTiles];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self adjustZoom];
    [self adjustTiles];
}

- (void) adjustZoom
{
    float scale = _scrollView.frame.size.width / kBoardWidth;
    _scrollView.minimumZoomScale = scale;
    _scrollView.maximumZoomScale = 2.0 * scale;
    
    CGPoint center = CGPointMake(kBoardWidth / 2.0, kBoardHeight / 2.0);
    [self zoomTo:center];
}

- (void) removeTiles
{
    for (UIView *subView in _contentView.subviews) {
        if (![subView isKindOfClass:[SmallTile class]])
            continue;
        
        SmallTile* tile = (SmallTile*)subView;
        [tile removeFromSuperview];
        [self.view addSubview:tile];
    }
}

- (void) adjustTiles
{
    //CGAffineTransform leftWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(-15.0));
    //CGAffineTransform rightWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(15.0));
    
    int i = 0;
    for (UIView *subView in self.view.subviews) {
        if (![subView isKindOfClass:[SmallTile class]])
            continue;
        
        SmallTile* tile = (SmallTile*)subView;
        tile.frame = CGRectMake(kPadding + kSmallTileWidth * kTileScale * i++,
                                self.view.bounds.size.height - kSmallTileHeight * kTileScale - kPadding,
                                kSmallTileWidth,
                                kSmallTileHeight);
        
        CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [anim setToValue:[NSNumber numberWithFloat:1.0f]];
        [anim setFromValue:[NSNumber numberWithDouble:1.2f]];
        //[anim setDuration:0.1];
        //[anim setRepeatCount:2];
        //[anim setAutoreverses:YES];
        [tile.layer addAnimation:anim forKey:@"wooble"];
        
        /*
        tile.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView beginAnimations:@"wobble" context:nil];
        //[UIView setAnimationDuration:0.25];
        [UIView setAnimationRepeatCount:3];
        tile.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
         */
        //NSLog(@"tile: %@", tile);
    }
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
    return _contentView;
}

- (IBAction) scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer
{
    if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint point = [recognizer locationInView:_contentView];
        [self zoomTo:point];
    }
    
    [self adjustTiles];
}

- (IBAction) mainViewDoubleTapped:(UITapGestureRecognizer*)recognizer
{
    [self removeTiles];
    [self adjustTiles];
}

- (void) zoomTo:(CGPoint)point
{
    CGFloat scale = _scrollView.maximumZoomScale;
    CGSize size = _scrollView.bounds.size;
    
    CGFloat w = size.width / scale;
    CGFloat h = size.height / scale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);
    
    CGRect rect = CGRectMake(x, y, w, h);
    
    [_scrollView zoomToRect:rect animated:YES];
}

- (SmallTile*) findTileAtPoint:(CGPoint)point withEvent:(UIEvent*)event
{
    // iterate through the children of main view and content view
    NSArray* children = [self.view.subviews arrayByAddingObjectsFromArray:_contentView.subviews];
    
    for (UIView* child in children) {
        CGPoint localPoint = [child convertPoint:point fromView:self.view];
        
        if ([child isKindOfClass:[SmallTile class]] &&
            [child pointInside:localPoint withEvent:event]) {
            return (SmallTile*)child;
        }
    }
    
    return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    _draggedTile = [self findTileAtPoint:point withEvent:event];
    if (!_draggedTile)
        return;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, _draggedTile);
    _draggedTile.alpha = 0;
    
    _bigTile = [_draggedTile cloneTile];
    _bigTile.center = [self.view convertPoint:_draggedTile.center
                                     fromView:_draggedTile.superview];
    [self.view addSubview:_bigTile];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    // nothing is being dragged
    if (!_draggedTile || !_bigTile)
        return;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, _draggedTile);
    
    UITouch* touch   = [touches anyObject];
    CGPoint point    = [touch locationInView:self.view];
    CGPoint previous = [touch previousLocationInView:self.view];
    
    _draggedTile.frame = CGRectOffset(_draggedTile.frame,
                              (point.x - previous.x),
                              (point.y - previous.y));

    _bigTile.center = [self.view convertPoint:_draggedTile.center
                                     fromView:_draggedTile.superview];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTileReleased:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTileReleased:touches withEvent:event];
}

- (void) handleTileReleased:(NSSet*)touches withEvent:(UIEvent*)event
{
    // nothing is being dragged
    if (!_draggedTile || !_bigTile)
        return;
    
    UITouch* touch = [touches anyObject];
	CGPoint point  = [touch locationInView:self.view];
	CGPoint pointInContent = [touch locationInView:_contentView];
    CGPoint pointTransformed = CGPointApplyAffineTransform(pointInContent, _contentView.transform);
	
    if (_draggedTile.superview != _contentView &&
        // is the tile over the scoll view?
        CGRectContainsPoint(_scrollView.frame, point) &&
        // is the tile still over the game board - when it is zoomed out?
        CGRectContainsPoint(_contentView.frame, pointTransformed)) {
		
        // put the tile at the game board
		[_draggedTile removeFromSuperview];
        [_contentView addSubview:_draggedTile];
        
    } else if(!CGRectContainsPoint(_scrollView.frame, point) ||
              !CGRectContainsPoint(_contentView.frame, pointTransformed)) {
        
        // put the tile back to the stack
        [_draggedTile removeFromSuperview];
        [self.view addSubview:_draggedTile];
        [self adjustTiles];
	}
    
    if (_draggedTile.superview == _contentView) {
        _draggedTile.center = pointInContent;
        [_draggedTile snapToGrid];
        _grid[_draggedTile.col][_draggedTile.row] = _draggedTile;
        
        //NSLog(@"_grid=%@", _grid);
        
        if (_scrollView.zoomScale == _scrollView.minimumZoomScale) {
            [self zoomTo:_draggedTile.center];
        }
    }
    
	[_bigTile removeFromSuperview];
	_bigTile = nil;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, _draggedTile);
	_draggedTile.alpha = 1;
    _draggedTile = nil;
}


@end
