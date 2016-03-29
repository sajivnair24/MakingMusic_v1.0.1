//
//  DBManager.m
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 16/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBManager.h"
#import "GenreClass.h"
#import "RhythmClass.h"

#import "DroneName.h"

#define DBName @"Flamenco.db"

@implementation DBManager
NSString *dbFilePath;
sqlite3 *database = nil;
//sqlite3_stmt *statement = nil;

-(DBManager*)initWithDatabaseFilename:(NSString *)dbFilename{
    self = [super init];
    if (self) {
        
        // Set the documents directory path to the documentsDirectory property.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        
        // Keep the database filename.
        self.databaseFilename = dbFilename;
        
        // Copy the database file into the documents directory if necessary.
        [self copyDatabaseIntoDocumentsDirectory];
        
    }
    return self;
}

-(void)copyDatabaseIntoDocumentsDirectory{
    // Check if the database file exists in the documents directory.
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        // The database file does not exist in the documents directory, so copy it from the main bundle now.
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
        
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            //NSLog(@"%@", [error localizedDescription]);
        }
    }
}

-(BOOL)createRecordingTable{
    
    dbFilePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    int result = 0;
    
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        char * query = "CREATE TABLE IF NOT EXISTS recording_table (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT,"
                       "inst1 INTEGER, inst2 INTEGER, inst3 INTEGER, inst4 INTEGER, vol1 INTEGER, vol2 INTEGER,"
                       "vol3 INTEGER, vol4 INTEGER, rhythm TEXT, bpm INTEGER, date TEXT, time TEXT, duration TEXT, t1 TEXT,"
                       "t2 TEXT, t3 TEXT, t4 TEXT, t1vol INTEGER, t2vol INTEGER, t3vol INTEGER, t4vol INTEGER, mergefile TEXT)";
        char * errMsg;
        result = sqlite3_exec(database, query, NULL, NULL, &errMsg);
        
        if(SQLITE_OK != result)
        {
            return NO;
        }
        
        sqlite3_close(database);
    }
    
    return YES;
}

-(BOOL)createRhythmTable{
    
    dbFilePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    int result = 0;
    
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        char * query = "CREATE TABLE IF NOT EXISTS rhythm_table (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                       "genre_id INTEGER, rhythm TEXT, beat1 TEXT, beat2 TEXT, bpm INTEGER, startbpm INTEGER,"
                       "img1 TEXT, img2 TEXT, beats INTEGER)";
        char * errMsg;
        result = sqlite3_exec(database, query, NULL, NULL, &errMsg);
        
        if(SQLITE_OK != result)
        {
            return NO;
        }
        
        sqlite3_close(database);
    }
    
    return YES;
}

-(BOOL)createGenreTable {
    
    dbFilePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    int result = 0;
    
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        char * query = "CREATE TABLE IF NOT EXISTS genre_table (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                       "genre TEXT, isDeleted INTEGER)";
        char * errMsg;
        result = sqlite3_exec(database, query, NULL, NULL, &errMsg);
        
        if(SQLITE_OK != result)
        {
            return NO;
        }
        
        sqlite3_close(database);
    }
    
    return YES;
}



- (BOOL)insertDataToRecordingInDictionary:(NSDictionary*)dict
{
    int result = 0;
    [self isDBOpened];
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query = [NSString stringWithFormat:@"INSERT INTO recording (name, inst1, inst2, inst3, inst4, vol1, vol2, vol3, vol4, pan1, pan2, pan3, pan4, rhythmId, bpm, date, time, duration, t1, t2, t3, t4, t1vol, t2vol, t3vol, t4vol, t1pan, t2pan, t3pan, t4pan, mergefile, isDeleted, droneType, t1duration, t2duration, t3duration, t4duration, t1flag, t2flag, t3flag, t4flag) VALUES (\"%@\", %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, \"%@\", %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, %d, %d, %d, %d, %d, %d, \"%@\", %d,\"%@\",\"%@\",\"%@\",\"%@\",\"%@\", %d, %d, %d, %d)",[dict valueForKey:@"name"],[[dict valueForKey:@"inst1"] intValue],[[dict valueForKey:@"inst2"] intValue],[[dict valueForKey:@"inst3"] intValue],[[dict valueForKey:@"inst4"] intValue],[[dict valueForKey:@"vol1"] intValue],[[dict valueForKey:@"vol2"] intValue],[[dict valueForKey:@"vol3"] intValue],[[dict valueForKey:@"vol4"] intValue],[[dict valueForKey:@"pan1"] intValue],[[dict valueForKey:@"pan2"] intValue],[[dict valueForKey:@"pan3"] intValue],[[dict valueForKey:@"pan4"] intValue],[dict valueForKey:@"rhythmId"],[[dict valueForKey:@"bpm"] intValue],[dict valueForKey:@"date"],[dict valueForKey:@"time"],[dict valueForKey:@"duration"],[dict valueForKey:@"t1"],[dict valueForKey:@"t2"],[dict valueForKey:@"t3"],[dict valueForKey:@"t4"],[[dict valueForKey:@"t1vol"] intValue],[[dict valueForKey:@"t2vol"] intValue],[[dict valueForKey:@"t3vol"] intValue],[[dict valueForKey:@"t4vol"] intValue],[[dict valueForKey:@"t1pan"] intValue],[[dict valueForKey:@"t2pan"] intValue],[[dict valueForKey:@"t3pan"] intValue],[[dict valueForKey:@"t4pan"] intValue],[dict valueForKey:@"mergefile"],[[dict valueForKey:@"isDeleted"] intValue],[dict valueForKey:@"droneType"],[dict valueForKey:@"t1Duration"],[dict valueForKey:@"t2Duration"],[dict valueForKey:@"t3Duration"],[dict valueForKey:@"t4Duration"],[[dict valueForKey:@"t1Flag"] intValue],[[dict valueForKey:@"t2Flag"] intValue],[[dict valueForKey:@"t3Flag"] intValue],[[dict valueForKey:@"t4Flag"] intValue]];
        
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

- (BOOL)saveData1
{
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString
                             stringWithFormat:@"INSERT INTO genre (genre, rhythm, beat1, beat2, bpm, startbpm, img1, img2, beats) VALUES ('Indian', 'Reggaeton', '', '', 96, 128, '', '', 8)"];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

-(int)getRowCount:(NSString*)tableName
{
    int result, rows = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString
                             stringWithFormat:@"SELECT count(*) FROM %@", tableName];
        sqlite3_stmt *statement = NULL;
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &statement, NULL);
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(statement) == SQLITE_ROW) //get each row in loop
            {
                rows = sqlite3_column_int(statement, 0);
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }
    return rows;
    
}

-(NSMutableArray *)getRhythmsFromGenre:(NSString*)genre    // ho gaya bhai
{
    int result, genreId = 0;
    NSString *rhythm;
    NSMutableArray *rhythmArray;
    
    dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString *query  = [NSString stringWithFormat:@"SELECT id FROM genre WHERE genre = '%@'", genre];
        sqlite3_stmt *statement = NULL;
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &statement, NULL);
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                genreId = sqlite3_column_int(statement, 0);
            }
            
            query  = [NSString stringWithFormat:@"SELECT rhythm FROM rhythm WHERE genre_id = %d", genreId];
            result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &statement, NULL);
            
            if(SQLITE_OK == result)
            {
                rhythmArray = [[NSMutableArray alloc] init];
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    rhythm = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
                    [rhythmArray addObject:rhythm];
                }
            }
            
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
        else
        {
            //NSLog(@"Failed to prepare statement with rc:%d", result);
        }
    }
    return rhythmArray;
}
-(RecordingListData *)getFirstRecordingData{
    int result = 0;
     RecordingListData *recordData = [[RecordingListData alloc]init];
    [self isDBOpened];
    NSMutableArray *allTableData = [[NSMutableArray alloc] init];
    // dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    
    //result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    
    result = SQLITE_OK;
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        
        sqlite3_stmt *selectStatement;
        result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
        selectStatement = NULL;
        NSString * query =  [NSString stringWithFormat:@"SELECT recording.*, rhythm.beat1,rhythm.beat2,rhythm.lag1,rhythm.lag2 FROM recording join rhythm on recording.rhythmId = rhythm.id WHERE recording.isDeleted = 0 order by recording.id desc"];
        
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &selectStatement, NULL);
        
        if(SQLITE_OK == result)
        {
            if (sqlite3_step(selectStatement) == SQLITE_ROW)
            {
               
                
                recordData.recordID = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
                recordData.recordingName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 1)];
                recordData.instOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 2)];
                recordData.instTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 3)];
                recordData.instThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 4)];
                recordData.instFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 5)];
                recordData.volOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 6)];
                recordData.volTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 7)];
                recordData.volThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 8)];
                recordData.volFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 9)];
                recordData.panOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 10)];
                recordData.panTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 11)];
                recordData.panThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 12)];
                recordData.panFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 13)];
                
                recordData.rhythmID = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 14)];
                recordData.BPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 15)];
                recordData.dateString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 16)];
                recordData.timeString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 17)];
                recordData.durationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 18)];
                recordData.trackOne = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 19)];
                recordData.trackTwo = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 20)];
                recordData.trackThree = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 21)];
                recordData.trackFour = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 22)];
                recordData.volTrackOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 23)];
                recordData.volTrackTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 24)];
                recordData.volTrackThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 25)];
                recordData.volTrackFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 26)];
                recordData.panTrackOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 27)];
                recordData.panTrackTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 28)];
                recordData.panTrackThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 29)];
                recordData.panTrackFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 30)];
                
                recordData.mergeFile = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 31)];
                recordData.isDeleted = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 32)];
                recordData.droneType = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 33)];
                recordData.t1DurationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 34)];
                recordData.t2DurationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 35)];
                const char* t3DurationString = (const char*)sqlite3_column_text(selectStatement, 36);
                recordData.t3DurationString = t3DurationString == NULL ? @"-1":[[NSString alloc] initWithUTF8String:t3DurationString];
                const char* t4DurationString = (const char*)sqlite3_column_text(selectStatement, 37);
                recordData.t4DurationString = t4DurationString == NULL ? @"-1":[[NSString alloc] initWithUTF8String:t4DurationString];
                recordData.t1Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 38)];
                recordData.t2Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 39)];
                recordData.t3Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 40)];
                recordData.t4Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 41)];
                const char* beat1 = (const char*)sqlite3_column_text(selectStatement, 42);
                recordData.beat1 = beat1 == NULL ? @"-1":[[NSString alloc] initWithUTF8String:beat1];
                const char* beat2 = (const char*)sqlite3_column_text(selectStatement, 43);
                recordData.beat2 = beat2 == NULL ? @"-1":[[NSString alloc] initWithUTF8String:beat2];
                recordData.lag1 = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 44)];
                recordData.lag2 = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 45)];
                
                
               
                
            }
            sqlite3_finalize(selectStatement);
        }
        else
        {
            //NSLog(@"Failed to prepare statement with rc:%d", result);
        }
    }
    
    sqlite3_close(database);
    return recordData;

}
- (NSMutableArray *)getAllRecordingData   // created by AG
{
    int result = 0;
    [self isDBOpened];
    NSMutableArray *allTableData = [[NSMutableArray alloc] init];
    // dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    
    //result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    
    result = SQLITE_OK;
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        
        sqlite3_stmt *selectStatement;
        result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
        selectStatement = NULL;
        NSString * query =  [NSString stringWithFormat:@"SELECT recording.*, rhythm.beat1,rhythm.beat2,rhythm.lag1,rhythm.lag2 FROM recording join rhythm on recording.rhythmId = rhythm.id WHERE recording.isDeleted = 0 order by recording.id desc"];

        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &selectStatement, NULL);
        
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(selectStatement) == SQLITE_ROW)
            {
                RecordingListData *recordData = [[RecordingListData alloc]init];
                
                recordData.recordID = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
                recordData.recordingName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 1)];
                recordData.instOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 2)];
                recordData.instTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 3)];
                recordData.instThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 4)];
                recordData.instFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 5)];
                recordData.volOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 6)];
                recordData.volTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 7)];
                recordData.volThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 8)];
                recordData.volFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 9)];
                recordData.panOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 10)];
                recordData.panTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 11)];
                recordData.panThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 12)];
                recordData.panFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 13)];

                recordData.rhythmID = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 14)];
                recordData.BPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 15)];
                recordData.dateString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 16)];
                recordData.timeString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 17)];
                recordData.durationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 18)];
                recordData.trackOne = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 19)];
                recordData.trackTwo = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 20)];
                recordData.trackThree = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 21)];
                recordData.trackFour = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 22)];
                recordData.volTrackOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 23)];
                recordData.volTrackTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 24)];
                recordData.volTrackThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 25)];
                recordData.volTrackFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 26)];
                recordData.panTrackOne = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 27)];
                recordData.panTrackTwo = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 28)];
                recordData.panTrackThree = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 29)];
                recordData.panTrackFour = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 30)];

                recordData.mergeFile = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 31)];
                recordData.isDeleted = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 32)];
                recordData.droneType = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 33)];
                recordData.t1DurationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 34)];
                recordData.t2DurationString = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 35)];
                const char* t3DurationString = (const char*)sqlite3_column_text(selectStatement, 36);
                recordData.t3DurationString = t3DurationString == NULL ? @"-1":[[NSString alloc] initWithUTF8String:t3DurationString];
                const char* t4DurationString = (const char*)sqlite3_column_text(selectStatement, 37);
                recordData.t4DurationString = t4DurationString == NULL ? @"-1":[[NSString alloc] initWithUTF8String:t4DurationString];
                recordData.t1Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 38)];
                recordData.t2Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 39)];
                recordData.t3Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 40)];
                recordData.t4Flag = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 41)];
                const char* beat1 = (const char*)sqlite3_column_text(selectStatement, 42);
                recordData.beat1 = beat1 == NULL ? @"-1":[[NSString alloc] initWithUTF8String:beat1];
                const char* beat2 = (const char*)sqlite3_column_text(selectStatement, 43);
                recordData.beat2 = beat2 == NULL ? @"-1":[[NSString alloc] initWithUTF8String:beat2];
                recordData.lag1 = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 44)];
                recordData.lag2 = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 45)];

                
                [allTableData addObject:recordData];
                
            }
            sqlite3_finalize(selectStatement);
        }
        else
        {
            //NSLog(@"Failed to prepare statement with rc:%d", result);
        }
      }
   
   sqlite3_close(database);
   return allTableData;
}

- (BOOL)updateRecordingNameOfRecordID :(NSNumber *)recordID updatedName :(NSString *)name
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString stringWithFormat:@"UPDATE recording set name = '%@' WHERE id = %@",name,recordID];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

- (BOOL)updateVolumesofRecordID: (NSNumber *)recordID instr1Vol :(NSNumber *)iV1 instr2Vol :(NSNumber *)iV2 instr3Vol :(NSNumber *)iV3 instr4Vol :(NSNumber *)iV4 track1Vol :(NSNumber *)tV1 trackVol2 :(NSNumber *)tV2 track3Vol :(NSNumber *)tV3
                     track4Vol :(NSNumber *)tV4
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString stringWithFormat:@"UPDATE recording set vol1 = %@,vol2 = %@, vol3 = %@, vol4 = %@, t1vol = %@, t2vol = %@, t3vol = %@, t4vol = %@ WHERE id = %@",iV1,iV2,iV3,iV4,tV1,tV2,tV3,tV4,recordID];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

- (BOOL)updatePanofRecordID: (NSNumber *)recordID instr1Pan :(NSNumber *)iP1 instr2Pan :(NSNumber *)iP2 instr3Pan :(NSNumber *)iP3 instr4Pan :(NSNumber *)iP4 track1Pan :(NSNumber *)tP1 trackPan2 :(NSNumber *)tP2 track3Pan :(NSNumber *)tP3
                     track4Pan :(NSNumber *)tP4
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString stringWithFormat:@"UPDATE recording set pan1 = %@,pan2 = %@, pan3 = %@, pan4 = %@, t1pan = %@, t2pan = %@, t3pan = %@, t4pan = %@ WHERE id = %@",iP1,iP2,iP3,iP4,tP1,tP2,tP3,tP4,recordID];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

- (BOOL)updateFlagValueOfRecordID :(NSNumber *)recordID instr1: (NSNumber *)flagInstr1 instr2: (NSNumber *)flagInstr2 instr3: (NSNumber *)flagInstr3 instr4: (NSNumber *)flagInstr4 t1: (NSNumber *)flagT1 t2: (NSNumber *)flagt2 t3: (NSNumber *)flagt3
    t4: (NSNumber *)flagt4
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString stringWithFormat:@"UPDATE recording set inst1 = %@,inst2 = %@, inst3 = %@, inst4 = %@, t1flag = %@, t2flag = %@, t3flag = %@, t4flag = %@ WHERE id = %@",flagInstr1,flagInstr2,flagInstr3,flagInstr4,flagT1,flagt2,flagt3,flagt4,recordID];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

- (BOOL)updateDeleteRecordOfRecordID :(NSNumber *)recordID
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query  = [NSString stringWithFormat:@"UPDATE recording set isDeleted = 1 WHERE id = %@",recordID];
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}


- (BOOL)updateSingleRecordingDataWithRecordingId :(int)recId trackSequence :(int)sequence track :(NSString *)trackPath maxTrackDuration :(NSString *)duration trackDuration :(NSString *)tDuration
{
    [self isDBOpened];
    int result = 0;
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString * query;
        
        switch (sequence) {
            case 1:
                query  = [NSString stringWithFormat:@"UPDATE recording set t1 = '%@', duration = '%@', t1duration = '%@' WHERE id = %d",trackPath,duration,tDuration,recId];
                break;
            case 2:
                query  = [NSString stringWithFormat:@"UPDATE recording set t2 = '%@', duration = '%@', t2duration = '%@' WHERE id = %d",trackPath,duration,tDuration, recId];
                break;
            case 3:
                query  = [NSString stringWithFormat:@"UPDATE recording set t3 = '%@', duration = '%@', t3duration = '%@' WHERE id = %d",trackPath,duration,tDuration, recId];
                break;
            case 4:
                query  = [NSString stringWithFormat:@"UPDATE recording set t4 = '%@', duration = '%@', t4duration = '%@' WHERE id = %d",trackPath,duration,tDuration, recId];
                break;
                
            default:
                break;
        }
        
        char * errMsg;
        result = sqlite3_exec(database, [query UTF8String] ,NULL, NULL, &errMsg);
        if(SQLITE_OK != result)
        {
            //NSLog(@"Failed to insert record  rc:%d, msg=%s", result, errMsg);
        }
        sqlite3_close(database);
    }
    return result;
}

//BY AG
-(NSMutableArray*)fetchRhythmRecordsByID:(NSNumber*)rythmId
{
    int result;
    NSMutableArray *allTableData = [[NSMutableArray alloc] init];
    [self isDBOpened];
    // dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        
        sqlite3_stmt *selectStatement;
        NSString* query = [NSString stringWithFormat:@"SELECT * FROM rhythm WHERE id = %@ and isDeleted = 0", rythmId];
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &selectStatement, NULL);
        
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(selectStatement) == SQLITE_ROW)
            {
                RhythmClass *rhythmClass = [[RhythmClass alloc]init];
                
                rhythmClass.rhythmId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
                rhythmClass.rhythmGenreId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 1)];
                rhythmClass.rhythmName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 2)];
                rhythmClass.rhythmBeatOne = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 3)];
                rhythmClass.rhythmBeatTwo = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 4)];
                rhythmClass.rhythmBPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 5)];
                rhythmClass.rhythmStartBPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 6)];
                rhythmClass.rhythmInstOneImage = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 7)];
                rhythmClass.rhythmInstTwoImage = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 8)];
                rhythmClass.rhythmBeatsCount = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 9)];
                rhythmClass.rhythmPosition = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 10)];
                rhythmClass.rhythmIsDeleted = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 11)];
                
                [allTableData addObject:rhythmClass];
            }
        }
        sqlite3_finalize(selectStatement);
        sqlite3_close(database);
    }
    return allTableData;
}

-(NSMutableArray*)getRhythmRecords:(NSNumber*)genreId
{
    int result;
    NSMutableArray *allTableData = [[NSMutableArray alloc] init];
    [self isDBOpened];
   // dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        sqlite3_stmt *selectStatement;
        NSString* query = [NSString stringWithFormat:@"SELECT * FROM rhythm WHERE genre_id = %@ and isDeleted = 0", genreId];
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &selectStatement, NULL);
            
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(selectStatement) == SQLITE_ROW)
            {
                RhythmClass *rhythmClass = [[RhythmClass alloc]init];
                
                rhythmClass.rhythmId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
                rhythmClass.rhythmGenreId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 1)];
                rhythmClass.rhythmName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 2)];
                rhythmClass.rhythmBeatOne = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 3)];
                rhythmClass.rhythmBeatTwo = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 4)];
                rhythmClass.rhythmBPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 5)];
                rhythmClass.rhythmStartBPM = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 6)];
                rhythmClass.rhythmInstOneImage = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 7)];
                rhythmClass.rhythmInstTwoImage = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(selectStatement, 8)];
                rhythmClass.rhythmBeatsCount = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 9)];
                rhythmClass.rhythmPosition = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 10)];
                rhythmClass.rhythmIsDeleted = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 11)];
                rhythmClass.lag1 = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 12)];
                [allTableData addObject:rhythmClass];
            }
        }
        sqlite3_finalize(selectStatement);
        sqlite3_close(database);
    }
    return allTableData;
}

-(NSDictionary*)getAudioFileRecords
{
    int result, rows = 0;
    NSDictionary *recordingDataDictionary;
    dbFilePath = @"/Users/sajivnair/Downloads/Flamenco.db";
    result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        rows = [self getRowCount:@"recording_table"];
        if(rows > 0)
        {
            NSString * query;
            sqlite3_stmt *statement;
            
            for(int i = rows; i > 0; i--)
            {
                query  = [NSString stringWithFormat:@"SELECT * FROM recording WHERE id = %d", i];
                statement = NULL;
                result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &statement, NULL);
                if(SQLITE_OK == result)
                {
                    while (sqlite3_step(statement) == SQLITE_ROW)
                    {
                        NSString *name = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                        int inst1 = sqlite3_column_int(statement, 2);
                        int inst2 = sqlite3_column_int(statement, 3);
                        int inst3 = sqlite3_column_int(statement, 4);
                        int inst4 = sqlite3_column_int(statement, 5);
                        int vol1 = sqlite3_column_int(statement, 6);
                        int vol2 = sqlite3_column_int(statement, 7);
                        int vol3 = sqlite3_column_int(statement, 8);
                        int vol4 = sqlite3_column_int(statement, 9);
                        
                        NSString *rhythm = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 10)];
                        int bpm = sqlite3_column_int(statement, 11);
                        
                        NSString *date = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 12)];
                        
                        NSString *time = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 13)];
                        
                        NSString *duration = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 14)];
                        
                        NSString *track1 = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 15)];
                        
                        NSString *track2 = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 16)];
                        
                        NSString *track3 = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 17)];
                        
                        NSString *track4 = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 18)];
                        
                        int t1vol = sqlite3_column_int(statement, 19);
                        int t2vol = sqlite3_column_int(statement, 20);
                        int t3vol = sqlite3_column_int(statement, 21);
                        int t4vol = sqlite3_column_int(statement, 22);
                        
                        NSString *mergeFile = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 23)];
                        
                        int del = sqlite3_column_int(statement, 24);
                        
                        recordingDataDictionary =[NSDictionary dictionaryWithObjectsAndKeys:name, @"name",                                               [NSNumber numberWithInteger:inst1], @"inst1", [NSNumber numberWithInteger:inst2], @"inst2", [NSNumber numberWithInteger:inst3], @"inst3", [NSNumber numberWithInteger:inst4], @"inst4", [NSNumber numberWithInteger:vol1], @"vol1", [NSNumber numberWithInteger:vol2], @"vol2", [NSNumber numberWithInteger:vol3], @"vol3", [NSNumber numberWithInteger:vol4], @"vol4", rhythm, @"rhythm", [NSNumber numberWithInteger:bpm], @"bpm", date, @"date", time, @"time", duration, @"duration", track1, @"t1", track2, @"t2", track3, @"t3", track4, @"t4", [NSNumber numberWithInteger:t1vol], @"t1vol", [NSNumber numberWithInteger:t2vol], @"t2vol", [NSNumber numberWithInteger:t3vol], @"t3vol", [NSNumber numberWithInteger:t4vol], @"t4vol", mergeFile, @"mergeFile", [NSNumber numberWithInteger:del], @"isDeleted", nil];
                                                  
                     }
                    sqlite3_finalize(statement);
                    sqlite3_close(database);
                }
                else
                {
                    //NSLog(@"Failed to prepare statement with rc:%d", result);
                }
            }
        }
    }
    return recordingDataDictionary;
}

-(NSArray*) getDroneName{
    @try {
        [self isDBOpened];
        NSMutableArray *allDroneName = [[NSMutableArray alloc] init];
        sqlite3_stmt *selectStatement;
        const char *sql;
        
        sql = "select * from drone order by sequence";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectStatement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
      //  //NSLog(@"sql - %s",sql);
        
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            
            DroneName *droneClass = [[DroneName alloc]init];
            
            droneClass.droneId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
            droneClass.droneName = [[NSString alloc]initWithUTF8String:(char *)sqlite3_column_text(selectStatement,1)];
            droneClass.droneLocation = [[NSString alloc]initWithUTF8String:(char *)sqlite3_column_text(selectStatement,2)];
            droneClass.droneSequence = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 3)];
            
            [allDroneName addObject:droneClass];
        }
        sqlite3_finalize(selectStatement);
        sqlite3_close(database);
        
        return allDroneName;
    }
    @catch (NSException *exception) {
        //NSLog(@"Error Occured in dao_SECTIONS::getAllSectionDetails: %@",exception);
        
    }
}


#pragma mark-
// Rasool method Implementation

-(void)isDBOpened
{
    @try {
        NSError *error = [[NSError alloc]init];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:DBName];
        dbFilePath = path;
      //  //NSLog(@"path - %@",path);
        int success = [fileManager fileExistsAtPath:path];
        
        if (!success) {
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DBName];
            //NSLog(@"dafualtPath = %@",defaultDBPath);
            success = [fileManager copyItemAtPath:defaultDBPath toPath:path error:&error];
            if (!success) {
                NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
            }
        }
        if (success) {
            // Open the database. The database was prepared outside the application.
            if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) {
                //
             //   //NSLog(@"DB Opened");
            } // Even though the open failed, call close to properly clean up resources.
            else {
                sqlite3_close(database);
                NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
                // Additional error handling, as appropriate...
                //return NULL;
            }
        }
        // [error release];
    }
    @catch (NSException *exception) {
        //NSLog(@"Error Occured in DBManager::isDBOpened: %@",exception);
     //   NSString *str = [NSString stringWithFormat:@"Error Occured in dao_SECTIONS::isDBOpened: %@",exception];
        //        [self commonDaoSectionErrorMessage:str error:nil];
    }
}

-(NSMutableArray *)getAllGenreDetails
{
    @try {
        [self isDBOpened];
        NSMutableArray *allTableData = [[NSMutableArray alloc] init];
        sqlite3_stmt *selectStatement;
        const char *sql;
        
//        sql = [[NSString stringWithFormat:@"SELECT * FROM %@",tableName] UTF8String];
        
        sql = "select * from genre where isDeleted = 0 order by position";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectStatement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
        
     //   //NSLog(@"sql - %s",sql);
        
       
            while (sqlite3_step(selectStatement) == SQLITE_ROW) {
                
                //Store the data in local variables from the sqlite database.
                //            model_SECTIONS *model_SECTIONS_OBJECT = [[model_SECTIONS alloc]init];
                //            //Fetching Column Data
                //
                GenreClass *genreClass = [[GenreClass alloc]init];
                
                genreClass.genreId = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 0)];
                genreClass.genreName = [[NSString alloc]initWithUTF8String:(char *)sqlite3_column_text(selectStatement,1)];
                genreClass.genreIsDeleted = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 2)];
                genreClass.genrePosition = [[NSNumber alloc]initWithInteger:sqlite3_column_int(selectStatement, 3)];
                
                [allTableData addObject:genreClass];
                
                
             // while
        }
    
        ////NSLog(@"allSectionRecords - %@",allSectionRecords);
        sqlite3_finalize(selectStatement);
        sqlite3_close(database);
        
        return allTableData;
    }
    @catch (NSException *exception) {
        //NSLog(@"Error Occured in dao_SECTIONS::getAllSectionDetails: %@",exception);

    }
}
// Get drone path for specific drone type
- (NSString *)getDroneLocationFromName :(NSString *)droneName
{
    int result = 0;
    [self isDBOpened];
    NSString *droneLocation = [[NSString alloc] init];
    
    result = SQLITE_OK;
    if (SQLITE_OK != result)
    {
        sqlite3_close(database);
        //NSLog(@"Failed to open db connection");
    }
    else
    {
        sqlite3_stmt *selectStatement;
        result = sqlite3_open_v2([dbFilePath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_READWRITE , NULL);
        selectStatement = NULL;
        NSString * query =  [NSString stringWithFormat:@"SELECT location FROM drone WHERE name = '%@'",droneName];
        
        result = sqlite3_prepare_v2(database, [query UTF8String] , -1, &selectStatement, NULL);
        
        if(SQLITE_OK == result)
        {
            while (sqlite3_step(selectStatement) == SQLITE_ROW)
            {
                droneLocation = [[NSString alloc]initWithUTF8String:(char *)sqlite3_column_text(selectStatement,0)];
            }
            sqlite3_finalize(selectStatement);
        }
        else
        {
            //NSLog(@"Failed to prepare statement with rc:%d", result);
        }
    }
    
    sqlite3_close(database);
    return droneLocation;
}
@end