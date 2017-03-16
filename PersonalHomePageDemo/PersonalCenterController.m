//
//  PersonalCenterController.m
//  PersonalHomePageDemo
//
//  Created by Kegem Huang on 2017/3/15.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "PersonalCenterController.h"
#import "PersonalCenterTableView.h"
#import "ContentViewCell.h"
#import "HFStretchableTableHeaderView.h"
#import "YUSegment.h"

@interface PersonalCenterController ()<UITableViewDelegate, UITableViewDataSource>
//tableView
@property (strong, nonatomic) IBOutlet PersonalCenterTableView *tableView;
//下拉头部放大控件
@property (strong, nonatomic) HFStretchableTableHeaderView* stretchableTableHeaderView;
//分段控制器
@property (strong, nonatomic) YUSegment *segment;
//YES代表能滑动
@property (nonatomic, assign) BOOL canScroll;
//pageViewController
@property (strong, nonatomic) ContentViewCell *contentCell;
//导航栏的背景view
@property (strong, nonatomic) UIImageView *barImageView;

@end

//得到屏幕width
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@implementation PersonalCenterController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.canScroll = YES;
    self.title = @"";
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.barImageView = self.navigationController.navigationBar.subviews.firstObject;
    self.barImageView.alpha = 0;
    
    //通知的处理，本来也不需要这么多通知，只是写一个简单的demo，所以...根据项目实际情况进行优化吧 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPageViewCtrlChange:) name:@"CenterPageViewScroll" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOtherScrollToTop:) name:@"kLeaveTopNtf" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onScrollBottomView:) name:@"PageViewGestureState" object:nil];
    self.tableView.showsVerticalScrollIndicator = NO;
    [ContentViewCell regisCellForTableView:self.tableView];
    
    //分段控制器 YUSegment
    self.segment = [[YUSegment alloc] initWithTitles:@[@"left",@"middle",@"right"]];
    self.segment.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    self.segment.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [self.segment addTarget:self action:@selector(onSegmentChange) forControlEvents:UIControlEventValueChanged];
    
    //tableView headerview
    UIImage *image = [UIImage imageNamed:@"pc_bg"];
    NSLog(@"image.height = %f",image.size.height);
    UIImageView *headerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, image.size.height)];
    headerView.image = image;
    headerView.contentMode = UIViewContentModeScaleAspectFill;

    //下拉放大
    _stretchableTableHeaderView = [HFStretchableTableHeaderView new];
    [_stretchableTableHeaderView stretchHeaderForTableView:self.tableView withView:headerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///通知的处理
//pageViewController页面变动时的通知
- (void)onPageViewCtrlChange:(NSNotification *)ntf {
    //更改YUSegment选中目标
    self.segment.selectedIndex = [ntf.object integerValue];
}

//子控制器到顶部了 主控制器可以滑动
- (void)onOtherScrollToTop:(NSNotification *)ntf {
    self.canScroll = YES;
    self.contentCell.canScroll = NO;
}

//当滑动下面的PageView时，当前要禁止滑动
- (void)onScrollBottomView:(NSNotification *)ntf {
    if ([ntf.object isEqualToString:@"ended"]) {
        //bottomView停止滑动了  当前页可以滑动
        self.tableView.scrollEnabled = YES;
    } else {
        //bottomView滑动了 当前页就禁止滑动
        self.tableView.scrollEnabled = NO;
    }
}

//监听segment的变化
- (void)onSegmentChange {
    //改变pageView的页码
    self.contentCell.selectIndex = self.segment.selectedIndex;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //要减去导航栏 状态栏 以及 sectionheader的高度
    return self.view.frame.size.height-44-64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //sectionheader的高度，这是要放分段控件的
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.segment;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.contentCell) {
        self.contentCell = [ContentViewCell dequeueCellForTableView:tableView];
        self.contentCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentCell setPageView];
    }
//    ContentViewCell *cell = [ContentViewCell dequeueCellForTableView:tableView];
    
    return self.contentCell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //下拉放大 必须实现
    [_stretchableTableHeaderView scrollViewDidScroll:scrollView];
    
    //计算导航栏的透明度
    UIImage *image = [UIImage imageNamed:@"pc_bg"];
    CGFloat minAlphaOffset = 0;
    CGFloat maxAlphaOffset = image.size.height-64;
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat alpha = (offset - minAlphaOffset) / (maxAlphaOffset - minAlphaOffset);
    _barImageView.alpha = alpha;

    //根据导航栏透明度设置title
    if (alpha > 0.5) {
        self.title = @"name";
    } else {
        self.title = @"";
    }

    //子控制器和主控制器之间的滑动状态切换
    CGFloat tabOffsetY = [_tableView rectForSection:0].origin.y-64;
    if (scrollView.contentOffset.y >= tabOffsetY) {
        scrollView.contentOffset = CGPointMake(0, tabOffsetY);
        if (_canScroll) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kScrollToTopNtf" object:@1];
            _canScroll = NO;
            self.contentCell.canScroll = YES;
        }
    } else {
        if (!_canScroll) {
            scrollView.contentOffset = CGPointMake(0, tabOffsetY);
        }
    }
}

//下拉放大必须实现
- (void)viewDidLayoutSubviews {
    [_stretchableTableHeaderView resizeView];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
