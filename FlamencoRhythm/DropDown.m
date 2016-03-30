//
//  DropDown.m
//  iCloud
//
//  Created by intelliswift on 31/03/15.
//  Copyright (c) 2015 intelliswift. All rights reserved.
//

#import "DropDown.h"
#import "CustomCell.h"
#import "DBManager.h"
#import "Constants.h"

@implementation DropDown
//@synthesize rhythmArray;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect rect = frame;
        rect.origin.y = 0;
        rect.size.height = 457;
//        rect.size.height = rect.size.height - 80;
        tableViewBackground = [[UIImageView alloc]initWithFrame:CGRectMake(0, 457, frame.size.width, frame.size.height-457)];
        [self addSubview:tableViewBackground];
        
        tableViewBackground.backgroundColor = [UIColor clearColor];
        //tableViewBackground.alpha = 0.1;
        tableViewBackground.userInteractionEnabled = YES;
       
        table = [[UITableView alloc]initWithFrame:rect];
        table.delegate = self;
        table.dataSource = self;
        table.bounces = NO;
        table.separatorColor = [UIColor clearColor];
        [self addSubview:table];
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
//        self.alpha = 0.4;
        [table setContentInset:UIEdgeInsetsMake(27,0,0,0)];
        
//        rhythmDct = [[NSMutableDictionary alloc]init];
//        
//        [rhythmDct setObject:@"1" forKey:@"Metronome"];
//        [rhythmDct setObject:@"2" forKey:@"Rock & Country"];
//        [rhythmDct setObject:@"3" forKey:@"Hip Hop & R'n'B"];
//        [rhythmDct setObject:@"4" forKey:@"Dance"];
//        [rhythmDct setObject:@"5" forKey:@"Metal"];
//        [rhythmDct setObject:@"6" forKey:@"Flamenco"];
//        [rhythmDct setObject:@"7" forKey:@"Jazz & Blues"];
//        [rhythmDct setObject:@"8" forKey:@"Caribbean"];
//        [rhythmDct setObject:@"9" forKey:@"Latin"];
//        [rhythmDct setObject:@"10" forKey:@"Indian"];
        
        dbObj = [[DBManager alloc]init];
        rhythmArray = [dbObj getAllGenreDetails];
//        rhythmArray = [[NSMutableArray alloc]initWithObjects:@"Metronome",@"Caribbean",@"Dance",@"Flamenco",@"Indian",@"Jazz & Blues",@"Hip Hop & R'n'B",@"Latin",@"Metal",@"Rock & Country", nil];
     //   //NSLog(@"drop down is called");
        
        UISwipeGestureRecognizer *swiperecognizer;
        swiperecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpSwipe)];
        [swiperecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
        [self addGestureRecognizer:swiperecognizer];
        
        UITapGestureRecognizer *recognizer;
        recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleUpSwipe)];
        recognizer.delegate = self;
        [tableViewBackground addGestureRecognizer:recognizer];
        
        closeButton = [[UIButton alloc]initWithFrame:CGRectMake(frame.size.width-30, 30, 21, 21)];
//        closeButton.backgroundColor = [UIColor redColor];
        [closeButton setImage:[UIImage imageNamed:@"close-icon.png"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeBtnAction) forControlEvents:UIControlEventTouchUpInside];
        //[self addSubview:closeButton];
        
        //table.layer.masksToBounds = NO;
       // table.layer.shadowOffset = CGSizeMake(0, 0);
        // table.layer.shadowRadius = 0.5;
        // table.layer.shadowOpacity = 0.6;
        
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame
           heading:(NSString *)headingText{
    self = [self initWithFrame:frame];
    if (self) {
        table.backgroundColor = [UIColor clearColor];
        [self addHeading:headingText];
        
        //table.frame = CGRectMake(table.frame.origin.x, table.frame.origin.y, table.frame.size.width, table.frame.size.height+44);
    }
    return self;
}
-(void)addHeading:(NSString*)headingText{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, -5, self.frame.size.width, 39)];
    heading = [[UILabel alloc]initWithFrame:CGRectMake(0, -5, self.frame.size.width, headerView.frame.size.height)];
    heading.text = headingText;//@"Select Genre";
    [heading setFont:[UIFont fontWithName:FONT_MEDIUM size:15.5]];
    heading.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:heading];
    
    
    UIView *seprator = [[UIView alloc]initWithFrame:CGRectMake(25, headerView.frame.size.height-2, self.frame.size.width-50, 0.5)];
    seprator.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:seprator];
    
    table.tableHeaderView = headerView;
}
// close button action when user taps on 'X' button
-(void)closeBtnAction {
    [self.delegate closeDropDown];
}
// close button action when user swipes out of tableview
-(void)handleUpSwipe {
    if ([self.delegate respondsToSelector:@selector(closeDropDown)]) {
        [self.delegate closeDropDown];
    }
}
-(void)reloadTableView {
    //NSLog(@"reload tableview");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [table selectRowAtIndexPath:indexPath
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
    [self tableView:table didSelectRowAtIndexPath:indexPath];
}

#pragma mark - TableView Delegate & Datasource methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rhythmArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *ientifier = @"CellIentifier";
    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:ientifier];
    if (cell == nil) {
        cell = [[CustomCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ientifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    //    cell.textLabel.text = @"Rasool";
    GenreClass *genreObj = [rhythmArray objectAtIndex:indexPath.row];
    NSString *rowString = genreObj.genreName;
    // if user already selected table and then 
    if (_selectedString.length > 0) {
        if ([_selectedString isEqualToString:rowString]) {
            [cell.rhythmButton setTitleColor:[UIColor colorWithRed:0 green:126/255.0 blue:255/255.0 alpha:1] forState:UIControlStateNormal];
            [cell.rhythmButton.titleLabel setFont:[UIFont fontWithName:FONT_MEDIUM size:15]];
        }
        else {
            [cell.rhythmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [cell.rhythmButton.titleLabel setFont:[UIFont fontWithName:FONT_REGULAR size:15]];
            [cell.rhythmButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        }
    }
    else if (indexPath.row == 0){
        [cell.rhythmButton setTitleColor:[UIColor colorWithRed:0 green:126/255.0 blue:255/255.0 alpha:1] forState:UIControlStateNormal];
        [cell.rhythmButton.titleLabel setFont:[UIFont fontWithName:FONT_REGULAR size:15]];
        [cell.rhythmButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    }
    cell.rhythmButton.tag = indexPath.row;
    [cell.rhythmButton addTarget:self
               action:@selector(btnTapped:) forControlEvents:UIControlEventTouchDown];
    [cell.rhythmButton setTitle:rowString forState:UIControlStateNormal];
   // cell.rhythmButton.titleLabel.text = rowString;
  //  if (indexPath.row%2==0) {
        cell.backgroundColor = [UIColor clearColor];
   // }
    return cell;
}

-(void)btnTapped:(UIButton*)sender
{
    //NSLog(@"I Clicked a button %ld",(long)sender.tag);
    if (currentIndexPath != sender.tag) {
        
      //  [table deselectRowAtIndexPath:indexPath animated:YES];
        GenreClass *genreObj = [rhythmArray objectAtIndex:sender.tag];
        _selectedString = genreObj.genreName;
        //  //NSLog(@"the genre id: %@",genreObj.genreId);
        [table reloadData];
        NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:genreObj.genreId,@"genreId",@"1",@"bpmDefault",_selectedString,@"selectedString", nil];
        // //NSLog(@"the secected dct: %@",dict);
        if ([self.delegate respondsToSelector:@selector(dropDownSelectedCell:)]) {
            [self.delegate dropDownSelectedCell:dict];
        }
        currentIndexPath = (int)sender.tag;
    }else{
        if ([self.delegate respondsToSelector:@selector(dropDownSameCellSelected)]) {
            [self.delegate dropDownSameCellSelected];
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    if (screenWidth == 320) {
        return 36.5;
    }
    return 37.5;
}
@end
