//
//  SQLiteDB.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/12/12.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import "SQLiteDB.h"

#import "sqlite3.h"

#import <sys/time.h>

@interface NSDictionary (SQLiteRow) <SQLiteRow>
@end
@interface NSMutableDictionary (SQLiteMutableCursor) <SQLiteMutableCursor>
@end

@implementation SQLiteDB


static NSString *TestColumnNames = @"ColumnNames";
static NSString *TestValues = @"Values";


NSString *QLString = @"TEXT";
NSString *QLNumber = @"NUMERIC";
NSString *QLDateTime = @"TEXT";

NSString *INTERGER_PRIMARY_KEY =@"INTEGER PRIMARY KEY";

NSString *TEXT_NOTNULL = @"TEXT NOT NULL";
NSString *TEXT_UNIQUE = @"TEXT UNIQUE";
NSString *TEXT_NOTNULL_UNIQUE = @"TEXT UNIQUE NOT NULL";
NSString *INTEGER_NOTNULL = @"INTEGER NOT NULL";
NSString *INTEGER_UNIQUE = @"INTEGER UNIQUE";
NSString *INTEGER_NOTNULL_UNIQUE = @"INTEGER UNIQUE NOT NULL";
NSString *NUMERIC_NOTNULL = @"NUMERIC NOT NULL";
NSString *NUMERIC_UNIQUE = @"NUMERIC UNIQUE";
NSString *NUMERIC_NOTNULL_UNIQUE = @"NUMERIC UNIQUE NOT NULL";
NSString *NONE_NOTNULL = @"NOT NULL";
NSString *NONE_UNIQUE = @"UNIQUE";
NSString *NONE_NOTNULL_UNIQUE = @"UNIQUE NOT NULL";

double debug_clock()
{
	double t;
	struct timeval tv;
	gettimeofday(&tv, NULL);
	t = tv.tv_sec + (double)tv.tv_usec*1e-6;
	return t;
}
void debug_log(const char *p,...)
{
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	
	if([d boolForKey:@"SQLITE_DEBUG_LOG"]) {
		va_list args;
		va_start(args, p);
		vfprintf(stderr, p, args);
	}
}
void debug_log_time(double t1, double t2)
{
	debug_log( "total time : \t%02.4lf\n",(t2) - (t1));
}

+ (NSString *) prepareStringForQuery : (NSString *) inString
{
	NSString *str;
	const char *p;
	char *q;
	
	p = [inString UTF8String];
	q = sqlite3_mprintf("%q", p);
	str = [NSString stringWithUTF8String : q];
	sqlite3_free(q);
	
	return str;
}

- (id) initWithDatabasePath : (NSString *) path
{
	if (self = [super init]) {
		[self setDatabaseFile : path];
		reservedQueries = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[self close];
	[mPath release];
	[reservedQueries release];
	
	[super dealloc];
}

- (NSString *) lastError
{
	if (!mDatabase) return nil;
	
	return [NSString stringWithUTF8String : sqlite3_errmsg(mDatabase)];
}
- (NSInteger) lastErrorID
{
	if (!mDatabase) return 0;
	
	return sqlite3_errcode(mDatabase);
}

- (void) setDatabaseFile : (NSString *) path
{
	id temp = mPath;
	mPath = [path copy];
	[temp release];
	
	[self open];
}
- (NSString *) databasePath
{
	return [NSString stringWithString : mPath];
}

- (sqlite3 *) rowDatabase
{
	return mDatabase;
}

- (BOOL) open
{
	const char *filepath = [mPath fileSystemRepresentation];
	NSInteger result;
	
	if ([self isDatabaseOpen]) {
		return YES;
	}
	
	UTILDebugWrite(@"Start Open database.");
	result = sqlite3_open_v2(filepath, &mDatabase, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	if(result != SQLITE_OK) {
		NSLog(@"Can not open database. \nFile -> %@.\nError Code : %ld", mPath, (long)result);
		[mPath release];
		mPath = nil;
		mDatabase = NULL;
		
		return NO;
	}
	
	_isOpen = YES;
	
	return YES;
}
- (NSInteger) close
{
	NSInteger result = NO;
	const NSInteger challengeTime = 1000;
	NSInteger count = 0;
	
	[reservedQueries removeAllObjects];
	
	if (mDatabase) {
		UTILDebugWrite(@"Start Closing database.");
		sqlite3_stmt *pStmt;
		while( (pStmt = sqlite3_next_stmt(mDatabase, 0))!=0 ){
			sqlite3_finalize(pStmt);
		}
		do {
			result = sqlite3_close(mDatabase);
			count++;
		} while (result == SQLITE_BUSY && count < challengeTime);
		if(count == challengeTime) {
			NSLog(@"give up! can not close database.");
		}
		mDatabase = NULL;
		
		UTILDebugWrite(@"End Closing database.");
	}
	
	_isOpen = NO;
	
	return result;
}
- (BOOL) isDatabaseOpen
{
	return _isOpen;
}

id <SQLiteRow> makeRowFromSTMT(sqlite3_stmt *stmt, NSArray *columns)
{
	CFMutableDictionaryRef result;
	NSInteger i, columnCount = sqlite3_column_count(stmt);
	
	result = CFDictionaryCreateMutable(kCFAllocatorDefault,
									   columnCount,
									   &kCFTypeDictionaryKeyCallBacks,
									   &kCFTypeDictionaryValueCallBacks);
	if(!result) return nil;
	
	for (i = 0; i < columnCount; i++) {
		//		const char *columnName = sqlite3_column_name(stmt, i);
		const unsigned char *value = sqlite3_column_text(stmt, i);
		id v = nil;
		
		if (value) {
			v = (id)CFStringCreateWithCString(kCFAllocatorDefault,
											  (const char*)value,
											  kCFStringEncodingUTF8);
		}
		if (v) {
			CFDictionaryAddValue(result, CFArrayGetValueAtIndex((CFArrayRef)columns, i), v);
			CFRelease(v);
		}
	}
	
	return [(id)result autorelease];
}

NSArray *columnsFromSTMT(sqlite3_stmt *stmt)
{
	CFMutableArrayRef result;
	NSInteger i, columnCount = sqlite3_column_count(stmt);
	
	result = CFArrayCreateMutable(kCFAllocatorDefault,
								  columnCount,
								  &kCFTypeArrayCallBacks);
	if(!result) return nil;
	
	for (i = 0; i < columnCount; i++) {
		const char *columnName = sqlite3_column_name(stmt, i);
		CFStringRef colStr;
		CFMutableStringRef lowerColStr; 
		
		colStr = CFStringCreateWithCString(kCFAllocatorDefault,
										   columnName,
										   kCFStringEncodingUTF8);
		lowerColStr = CFStringCreateMutableCopy(kCFAllocatorDefault,
												CFStringGetLength(colStr),
												colStr);
		CFStringLowercase(lowerColStr, CFLocaleGetSystem());
		CFArrayAppendValue(result, lowerColStr);
		CFRelease(colStr);
		CFRelease(lowerColStr);
	}
	
	return [(id)result autorelease];
}

NSArray *valuesForSTMT(sqlite3_stmt *stmt, NSArray *culumns)
{
	NSInteger result;
	BOOL finishFetch = NO;
	id <SQLiteRow> dict;
	CFMutableArrayRef values;
	
	values = CFArrayCreateMutable(kCFAllocatorDefault,
								  0,
								  &kCFTypeArrayCallBacks);
	if(!values) return nil;
	
	NSInteger busyCount = 0;
	do {
		BOOL updateCursor = NO;
		
		result = sqlite3_step(stmt);
		
		switch (result) {
			case SQLITE_BUSY :
				busyCount++;
				break;
			case SQLITE_OK :
			case SQLITE_DONE :
				finishFetch = YES;
				busyCount = 0;
				break;
			case SQLITE_ROW :
				updateCursor = YES;
				busyCount = 0;
				break;
			case SQLITE_SCHEMA:
				continue;
			default :
				//				sqlite3_finalize(stmt);
				CFRelease(values);
				return nil;
				break;
		}
		
		if (updateCursor) {
			dict = makeRowFromSTMT(stmt, culumns);
			if (dict) {
				CFArrayAppendValue(values, dict);
			}
		}
		
		if(busyCount>1000) {
			fprintf(stderr, "Give up! sqlite3_step() return SQLITE_BUSY thousand times.\n");
			CFRelease(values);
			return nil;
		}
		
	} while (!finishFetch);
	
	return [(id)values autorelease];
}

id<SQLiteMutableCursor> cursorFromSTMT(sqlite3_stmt *stmt)
{
	id columns, values;
	id<SQLiteMutableCursor> cursor;
	
	double time00, time01;

	time00 = debug_clock();
	columns = columnsFromSTMT(stmt);
	values = valuesForSTMT(stmt, columns);
	time01 = debug_clock();
	debug_log_time(time00, time01);
	
	if(!columns || !values) {
		return nil;
	}
	cursor = [NSMutableDictionary dictionaryWithObjectsAndKeys : columns, TestColumnNames,
		values, TestValues, nil];
	
	return cursor;
}

- (id <SQLiteMutableCursor>) cursorForSQL : (NSString *) sqlString
{
	const char *sql;
	sqlite3_stmt *stmt;
	NSInteger result;
	id <SQLiteMutableCursor> cursor;
	
	if (!mDatabase) {
		return nil;
	}
	if (!sqlString) {
		return nil;
	}
	
	sql = [sqlString UTF8String];
	
	result = sqlite3_prepare_v2(mDatabase, sql, strlen(sql) , &stmt, &sql);
	if(result != SQLITE_OK) return nil;
	
	debug_log("send query %s\n", [sqlString UTF8String]);
	
	cursor = cursorFromSTMT(stmt);
	sqlite3_finalize(stmt);
	
	return cursor;
}

- (id <SQLiteMutableCursor>) performQuery : (NSString *) sqlString
{
	return [self cursorForSQL : sqlString];
}

- (SQLiteReservedQuery *) reservedQuery : (NSString *) sqlString
{
	return [SQLiteReservedQuery sqliteReservedQueryWithQuery : sqlString usingSQLiteDB : self];
}
@end

@implementation SQLiteDB (DatabaseAccessor)

- (NSArray *) tables
{
	id cursor;
	id sql = [NSString stringWithFormat: @"%s", 
		"SELECT name FROM sqlite_master WHERE type = 'table' OR type = 'view'	\
	UNION	\
	SELECT name FROM sqlite_temp_master	\
	WHERE type = 'table' OR type = 'view'"];
	
	cursor = [self cursorForSQL : sql];
	
	return [cursor valuesForColumn : @"Name"];
}
- (BOOL) beginTransaction
{
	if (_transaction) {
		NSLog(@"Already begin transaction.");
		
		return NO;
	}
	
	_transaction = YES;
	
	[self performQuery : @"BEGIN"];
	
	return [self lastErrorID] == 0;
}
- (BOOL) commitTransaction
{
	if (!_transaction) {
		NSLog(@"Not begin transaction.");
		
		return NO;
	}
	
	_transaction = NO;
	
	[self performQuery : @"COMMIT"];
	
	return [self lastErrorID] == 0;
}
- (BOOL) rollbackTransaction
{
	if (!_transaction) {
		NSLog(@"Not begin transaction.");
		
		return NO;
	}
	
	_transaction = NO;
	
	[self performQuery : @"ROLLBACK"];
	
	return [self lastErrorID] == 0;
}

// do nothing. for compatible QuickLite.
- (BOOL) save { return YES; }

- (NSString *) defaultValue : (id) inValue forDatatype : (NSString *) datatype
{
	NSString *defaultValue = nil;
	
	if(!inValue || inValue == [NSNull null]) {
		return nil;
	}
	
	if(!datatype || (id)datatype == [NSNull null]) {
		defaultValue =  [[self class] prepareStringForQuery : [inValue stringValue]];
	}
	
	NSRange range;
	NSString *lower = [datatype lowercaseString];
	if(!lower) return nil;
	
	range = [lower rangeOfString : @"text"];
	if(range.length != 0) {
		defaultValue = [NSString stringWithFormat: @"'%@'", [[self class] prepareStringForQuery : [inValue stringValue]]];
	}
	
	range = [lower rangeOfString : @"integer"];
	if(range.length != 0) {
		defaultValue =  [NSString stringWithFormat: @"%ld", (long)[inValue integerValue]];
	}
	
	range = [lower rangeOfString : @"numelic"];
	if(range.length != 0) {
		defaultValue =  [NSString stringWithFormat: @"%0.0f", [inValue doubleValue]];
	}
	
	if(defaultValue) {
		return [NSString stringWithFormat: @"DEFAULT %@", defaultValue];
	}
	
	return nil;
}

- (NSString *) checkConstraint : (id) checkConstraint
{
	if(!checkConstraint || checkConstraint == [NSNull null]) {
		return nil;
	}
	
	return [NSString stringWithFormat: @"CHECK(%@)", checkConstraint];;
}

- (BOOL) createTemporaryTable : (NSString *) table
					  columns : (NSArray *) columns
					datatypes : (NSArray *) datatypes
				defaultValues : (NSArray *) defaultValues
			  checkConstrains : (NSArray *) checkConstrains
				  isTemporary : (BOOL) isTemporary
{
	NSUInteger i;
	NSUInteger columnCount = [columns count];
	NSMutableString *sql;
	BOOL useDefaultValues = NO;
	BOOL useCheck = NO;
	
	if (columnCount != [datatypes count]) return NO;
	if (columnCount == 0) return NO;
	
	useDefaultValues = defaultValues ? YES :NO;
	if(useDefaultValues && columnCount != [defaultValues count]) return NO;
	useCheck = checkConstrains ? YES :NO;
	if(useDefaultValues && columnCount != [checkConstrains count]) return NO;
	
	sql = [NSMutableString stringWithFormat: @"CREATE %@ TABLE %@ (",
				 isTemporary ? @"TEMPORARY" : @"", table];
	
	for (i = 0; i < columnCount; i++) {
		[sql appendFormat: @"%@ %@", [columns objectAtIndex : i], [datatypes objectAtIndex : i]];
		if(useDefaultValues) {
			NSString *d = [self defaultValue: [defaultValues objectAtIndex : i ]
								forDatatype : [datatypes objectAtIndex : i]];
			if(d) {
				[sql appendFormat: @" %@", d];
			}
		}
		if(useCheck) {
			NSString *c = [self checkConstraint : [checkConstrains objectAtIndex : i ]];
			if(c && (id)c != [NSNull null]) {
				[sql appendFormat: @" %@", c];
			}
		}
		
		if (i != columnCount - 1) {
			[sql appendString : @","];
		}
	}
	[sql appendString : @") "];
	
	[self performQuery : sql];
	
	return [self lastErrorID] == 0;
}


- (BOOL) createTable : (NSString *) table
	     withColumns : (NSArray *) columns
	    andDatatypes : (NSArray *) datatypes
	     isTemporary : (BOOL) isTemporary
{
	return [self createTemporaryTable : table
							  columns : columns
							datatypes : datatypes
						defaultValues : nil
					  checkConstrains : nil
						  isTemporary : NO];
}
- (BOOL) createTable : (NSString *) table withColumns : (NSArray *) columns andDatatypes : (NSArray *) datatypes
{
	return [self createTable : table
				 withColumns : columns
				andDatatypes : datatypes
				 isTemporary : NO];
}
- (BOOL) createTable : (NSString *) table
			 columns : (NSArray *) columns
		   datatypes : (NSArray *) datatypes
	   defaultValues : (NSArray *)defaultValues
	 checkConstrains : (NSArray *)checkConstrains
{
	return [self createTemporaryTable : table
							  columns : columns
							datatypes : datatypes
						defaultValues : defaultValues
					  checkConstrains : checkConstrains
						  isTemporary : NO];
}
- (BOOL) createTemporaryTable : (NSString *) table
				  withColumns : (NSArray *) columns
			     andDatatypes : (NSArray *) datatypes
{
	return [self createTable : table
				 withColumns : columns
				andDatatypes : datatypes
				 isTemporary : YES];
}
- (BOOL) createTemporaryTable : (NSString *) table
					  columns : (NSArray *) columns
					datatypes : (NSArray *) datatypes
				defaultValues : (NSArray *)defaultValues
			  checkConstrains : (NSArray *)checkConstrains
{
	return [self createTemporaryTable : table
							  columns : columns
							datatypes : datatypes
						defaultValues : defaultValues
					  checkConstrains : checkConstrains
						  isTemporary : YES];
}

- (NSString *)indexNameForColumn:(NSString *)column inTable:(NSString *)table
{
	return [NSString stringWithFormat:@"%@_%@_INDEX", table, column];
}
- (BOOL) createIndexForColumn : (NSString *) column inTable : (NSString *) table isUnique : (BOOL) isUnique
{
	NSString *sql;
	
	sql = [NSString stringWithFormat: @"CREATE %@ INDEX %@ ON %@ ( %@ ) ",
				isUnique ? @"UNIQUE" : @"",
				[self indexNameForColumn:column inTable:table], 
				table, column];
	
	[self performQuery : sql];
	
	return [self lastErrorID] == 0;
}

- (BOOL) deleteIndexForColumn:(NSString *)column inTable:(NSString *)table
{
	NSString *sql;
	
	sql = [NSString stringWithFormat: @"DROP INDEX %@",
		[self indexNameForColumn:column inTable:table]];
	
	[self performQuery : sql];
	
	return [self lastErrorID] == 0;
}

@end

@implementation SQLiteDB (ResercedQuerySupport)

- (SQLiteReservedQuery *)reservedQueryWithKey:(NSString *)key
{
	return [reservedQueries objectForKey:key];
}

- (void)setReservedQuery:(SQLiteReservedQuery *)query forKey:(NSString *)key
{
	[reservedQueries setObject:query forKey:key];
}

@end

@implementation SQLiteReservedQuery

+ (id) sqliteReservedQueryWithQuery : (NSString *) sqlString usingSQLiteDB : (SQLiteDB *) db
{
	id result = [db reservedQueryWithKey:sqlString];
	if(result) return result;
	
	return [[[self alloc] initWithQuery : sqlString usingSQLiteDB : db] autorelease];
}

- (id) initWithQuery : (NSString *) sqlString usingSQLiteDB : (SQLiteDB *) db
{
	self = [super init];
	
	if (self) {
		
		id stockedQuery = [db reservedQueryWithKey:sqlString];
		if(stockedQuery) {
			[self autorelease];
			return [stockedQuery retain];
		}
		
		const char *sql = [sqlString UTF8String];
		NSInteger result;
		
		result = sqlite3_prepare_v2([db rowDatabase], sql, strlen(sql) , &m_stmt, &sql);
		if (result != SQLITE_OK) goto fail;
		
		[db setReservedQuery:self forKey:sqlString];
		
		debug_log("create statment %s\n", [sqlString UTF8String]);
	}
	
	debug_log("#### CREATE RESERVED STATMENT ####\n");
	
	return self;
	
fail :
		[self release];
	return nil;
}

- (void) dealloc
{
	sqlite3_finalize(m_stmt);
	
	debug_log("#### DELETE RESERVED STATMENT ####\n");
	
	[super dealloc];
}

void objectDeallocator(void *obj)
{
	//	NSLog(@"??? DEALLOC ???");
}
- (id <SQLiteMutableCursor>) cursorForBindValues : (NSArray *) bindValues
{
	NSInteger error;
	NSInteger paramCount;
	NSUInteger i, valuesCount;
	id value;
	
	id <SQLiteMutableCursor> cursor;
	
	error = sqlite3_reset(m_stmt);
	if (SQLITE_OK != error) return nil;
	error = sqlite3_clear_bindings(m_stmt);
	if (SQLITE_OK != error) return nil;
	
	valuesCount = [bindValues count];
	paramCount = sqlite3_bind_parameter_count(m_stmt);
	if (valuesCount != paramCount) {
		NSLog(@"Missmatch bindValues count!!");
		return nil;
	}
	for (i = 0; i < valuesCount; i++) {
		value = [bindValues objectAtIndex : i];
		
		if ([value isKindOfClass : [NSNumber class]]) {
			NSInteger intValue = [value integerValue];
			error = sqlite3_bind_int(m_stmt, i+1, intValue);
			if (SQLITE_OK != error) return nil;
		} else if ([value isKindOfClass : [NSString class]]) {
			const char *str = [value UTF8String];
			error = sqlite3_bind_text(m_stmt, i+1, str, strlen(str) , objectDeallocator);
			if (SQLITE_OK != error) return nil;
		} else if (value == [NSNull null]) {
			error = sqlite3_bind_null(m_stmt, i+1);
			if (SQLITE_OK != error) return nil;
		} else {
			NSLog(@"cursorForBindValues : NOT supported type.");
			return nil;
		}
	}
	
	cursor = cursorFromSTMT(m_stmt);
	
	error = sqlite3_reset(m_stmt);
	if(error != SQLITE_OK) {
		NSLog(@"fail sqlite3_reset().");
	}
	
	return cursor;
}

static inline BOOL setNullIfNil(sqlite3_stmt *m_stmt, NSInteger i, id obj, NSInteger *outError)
{
	NSInteger error = SQLITE_OK;
	if(!obj || obj == [NSNull null]) {
		error = sqlite3_bind_null(m_stmt, i);
		if(outError) *outError = error;
		return YES;
	}
	
	return NO;
}
#define fString 's'
#define fInt 'i'
#define fDouble 'd'
#define fNull 'n'
#define fNInt 'j'
#define fNDouble 'e'
- (id <SQLiteMutableCursor>)cursorWithFormat:(const char *)format, ...
{
	NSInteger error;
	NSUInteger i;	
	id <SQLiteMutableCursor> cursor;
	
	error = sqlite3_reset(m_stmt);
	if (SQLITE_OK != error) return nil;
	error = sqlite3_clear_bindings(m_stmt);
	if (SQLITE_OK != error) return nil;
		
	va_list ap;
	id s;
	NSInteger d;
	double fd;
	
	va_start(ap, format);
	i = 0;
	while(*format) {
		i++;
		switch(*format++) {
			case fString:
				s = va_arg(ap, NSString *);
				if(!setNullIfNil(m_stmt, i, s, &error)) {
					const char *str = [s UTF8String];
					error = sqlite3_bind_text(m_stmt, i, str, strlen(str) , objectDeallocator);
				}
				break;
			case fInt:
				d = va_arg(ap, NSInteger);
				error = sqlite3_bind_int(m_stmt, i, d);
				break;
			case fDouble:
				fd = va_arg(ap, double);
				error = sqlite3_bind_double(m_stmt, i, fd);
				break;
			case fNull:
				error = sqlite3_bind_null(m_stmt, i);
				break;
			case fNInt:
				s = va_arg(ap, NSNumber *);
				if(!setNullIfNil(m_stmt, i, s, &error)) {
					d = [s integerValue];
					error = sqlite3_bind_int(m_stmt, i, d);
				}
				break;
			case fNDouble:
				s = va_arg(ap, NSNumber *);
				if(!setNullIfNil(m_stmt, i, s, &error)) {
					fd = [s doubleValue];
					error = sqlite3_bind_double(m_stmt, i, fd);
				}
				break;
			default:
				NSLog(@"cursorForBindValues : NOT supported type.");
				error = -1;
				break;
		}
		if(SQLITE_OK != error) goto fail;
	}
	va_end(ap);
	
	cursor = cursorFromSTMT(m_stmt);
	
	error = sqlite3_reset(m_stmt);
	
	return cursor;
	
fail:{
	va_end(ap);
//	error = sqlite3_reset(m_stmt);
	return nil;
}
}
@end

@implementation NSDictionary (SQLiteRow)
- (NSUInteger) columnCount
{
	return [self count];
}
- (NSArray *) columnNames
{
	return [self allKeys];
}
- (id) valueForColumn : (NSString *) column
{
	NSString *lower = [column lowercaseString];
	id result = [self objectForKey : lower];
	return result ? result : [NSNull null];
}
@end

@implementation NSMutableDictionary (SQLiteCursor)

- (NSUInteger) columnCount
{
	return [[self objectForKey : TestColumnNames] count];
}
- (NSArray *) columnNames
{
	return [self objectForKey : TestColumnNames];
}

- (NSUInteger) rowCount
{
	return [[self objectForKey : TestValues] count];
}
- (id) valueForColumn : (NSString *) column atRow : (NSUInteger) row
{
	id lower = [column lowercaseString];
	return [[self rowAtIndex : row] valueForColumn : lower];
}
- (NSArray *) valuesForColumn : (NSString *) column;
{
	id lower = [column lowercaseString];
	NSMutableArray *result;
	NSUInteger i, rowCount = [self rowCount];
	
	if (rowCount == 0 || [self columnCount] == 0) return nil;
	
	result = [NSMutableArray arrayWithCapacity : rowCount];
	for (i = 0; i < rowCount; i++) {
		id value = [self valueForColumn : lower atRow : i];
		if (value) {
			[result addObject : value];
		}
	}
	
	return result;
}
- (id <SQLiteRow>) rowAtIndex : (NSUInteger) row
{
	return [[self arrayForTableView] objectAtIndex : row];
}
- (NSArray *) arrayForTableView
{
	id result = [self objectForKey : TestValues];
	
	if (!result) {
		result = [NSMutableArray array];
		[self setObject : result forKey : TestValues];
	}
	
	return result;
}

- (BOOL) appendRow : (id <SQLiteRow>) row
{
	if ([row columnCount] != [self columnCount]) return NO;
	if (![[row columnNames] isEqual : [self columnNames]]) return NO;
	
	[(NSMutableArray *)[self arrayForTableView] addObject : row];
	
	return YES;
}
- (BOOL) appendCursor : (id <SQLiteCursor>) cursor
{
	if ([cursor columnCount] != [self columnCount]) return NO;
	if (![[cursor columnNames] isEqual : [self columnNames]]) return NO;
	
	[(NSMutableArray *)[self arrayForTableView] addObjectsFromArray : [cursor arrayForTableView]];
	
	return YES;
}

@end
