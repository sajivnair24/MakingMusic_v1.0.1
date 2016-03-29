//
//  DBManager.h
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 16/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#ifndef FlamencoRhythm_DBManager_h
#define FlamencoRhythm_DBManager_h

#import <sqlite3.h>
#import "RecordingListData.h"
#endif
@class GenreClass;

@interface DBManager : NSObject

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;

-(DBManager*)initWithDatabaseFilename:(NSString *)dbFilename;
-(void)copyDatabaseIntoDocumentsDirectory;

- (BOOL)insertDataToRecordingInDictionary:(NSDictionary*)dict;
- (BOOL)saveData1;
-(int)getRowCount:(NSString*)tableName;
-(BOOL)createRecordingTable;
-(BOOL)createGenreTable;
-(BOOL)createRhythmTable;
-(NSMutableArray *)getRhythmsFromGenre:(NSString*)genre;
-(NSMutableArray*)getRhythmRecords:(NSNumber*)genreId;
-(NSDictionary*)getAudioFileRecords;

// Created by AG.
- (BOOL)updateSingleRecordingDataWithRecordingId :(int)recId trackSequence :(int)sequence track :(NSString *)trackPath maxTrackDuration :(NSString *)duration trackDuration :(NSString *)tDuration;
- (BOOL)updateVolumesofRecordID: (NSNumber *)recordID instr1Vol :(NSNumber *)iV1 instr2Vol :(NSNumber *)iV2 instr3Vol :(NSNumber *)iV3 instr4Vol :(NSNumber *)iV4 track1Vol :(NSNumber *)tV1 trackVol2 :(NSNumber *)tV2 track3Vol :(NSNumber *)tV3
                     track4Vol :(NSNumber *)tV4;
- (BOOL)updatePanofRecordID: (NSNumber *)recordID instr1Pan :(NSNumber *)iP1 instr2Pan :(NSNumber *)iP2 instr3Pan :(NSNumber *)iP3 instr4Pan :(NSNumber *)iP4 track1Pan :(NSNumber *)tP1 trackPan2 :(NSNumber *)tP2 track3Pan :(NSNumber *)tP3
                 track4Pan :(NSNumber *)tP4;
- (BOOL)updateFlagValueOfRecordID :(NSNumber *)recordID instr1: (NSNumber *)flagInstr1 instr2: (NSNumber *)flagInstr2 instr3: (NSNumber *)flagInstr3 instr4: (NSNumber *)flagInstr4 t1: (NSNumber *)flagT1 t2: (NSNumber *)flagt2 t3: (NSNumber *)flagt3 t4: (NSNumber *)flagt4;
- (BOOL)updateDeleteRecordOfRecordID :(NSNumber *)recordID;
- (BOOL)updateRecordingNameOfRecordID :(NSNumber *)recordID updatedName :(NSString *)name;
- (NSString *)getDroneLocationFromName :(NSString *)droneName;

-(NSArray*) getDroneName;

// Rasool's Method
-(void)isDBOpened;
-(NSMutableArray *)getAllGenreDetails;
- (NSMutableArray *)getAllRecordingData;
// by AG
-(NSMutableArray*)fetchRhythmRecordsByID:(NSNumber*)rythmId;
//by nirma
-(RecordingListData *)getFirstRecordingData;
@end
