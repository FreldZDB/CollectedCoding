//
//  RootViewController.m
//  PPRemote
//
//  Created by PP on 12/25/14.
//  Copyright (c) 2014 PP. All rights reserved.
//


@implementation EncodingUDPData

/*识别结果返回代理
 @param resultArray 识别结果
 @ param isLast 表示是否最后一次结果
 */
-(void)onResults:(NSArray *)results isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [results objectAtIndex:0];
    DLog(@"%@",results);
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
        DLog(@"%@",key);
    }
    DLog(@"%@",result);
    //---------讯飞语音识别JSON数据解析---------//
    NSError * error;
    NSArray * temp = [[NSArray alloc]init];
    NSString * str = [[NSString alloc]init];
    NSData * data = [result dataUsingEncoding:NSUTF8StringEncoding];
    DLog(@"data: %@",data);
    NSDictionary * dic_result =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSArray * array_ws = [dic_result objectForKey:@"ws"];
         //遍历识别结果的每一个单词
    for (int i=0; i<array_ws.count; i++) {
            temp = [[array_ws objectAtIndex:i] objectForKey:@"cw"];
            NSDictionary * dic_cw = [temp objectAtIndex:0];
            str = [str  stringByAppendingString:[dic_cw objectForKey:@"w"]];
            DLog(@"识别结果:%@",[dic_cw objectForKey:@"w"]);
    }
    DLog(@"最终的识别结果:%@",str);
         //去掉识别结果最后的标点符号
    if ([str isEqualToString:@"。"] || [str isEqualToString:@"？"] || [str isEqualToString:@"！"]) {
        DLog(@"末尾标点符号：%@",str);
        return;
    }
    else{
        NSData *tmpData= [self encodeWithString:[NSString stringWithFormat:@"speech%@",str]];
        NSString *string=[[NSString alloc]initWithData:tmpData encoding:NSUTF8StringEncoding];
        DLog(@"%@",string);
        [tcpSocket writeData:tmpData withTimeout:-1 tag:25];
        [tcpSocket readDataWithTimeout:-1 tag:25];

    }
}
/*识别会话错误返回代理
 @ param error 错误码
 */
- (void)onError: (IFlySpeechError *) error {
    DLog(@"errorCode:%d",[error errorCode]);

}

- (NSData *)encodeWithString:(NSString *)string
{
    //DLog(@"%@",string);
    NSData* stringData = [string dataUsingEncoding:NSUTF8StringEncoding];

    NSUInteger stringLength = [stringData length];
     char *stringBytes = ( char *)[stringData bytes];
    
    NSUInteger length=stringLength+1;
    NSData *lengData = [NSData dataWithBytes: &length length: sizeof(length)];

    char *lengthBytes=malloc(sizeof(length) );
    for (int i = 0; i<4; i ++) {
        
        lengthBytes[i] =(char) length>>8*i;
        
    }
     char *keyBytes = ( char *)malloc((length+lengData.length+1) );
    keyBytes[0]='S';

    for (int i = 1; i<lengData.length+ 1; i ++) {

        keyBytes[i] = ( char)lengthBytes[i-1];
       // DLog(@"%d %d",( int)lengthBytes[i-1], keyBytes[i]);

    }
    free(lengthBytes);

    for (NSUInteger i = 1+lengData.length; i < stringLength+1+lengData.length; i ++) {
        keyBytes[i] = ( char)(stringBytes[i-1-lengData.length]);
       // DLog(@"%d",( int)keyBytes[i]);

    }
    
    keyBytes[length+lengData.length] = keyBytes[1+lengData.length];

    for (int i=1; i<length-1; i++) {

        keyBytes[length+lengData.length]=( char)(keyBytes[length+lengData.length]^keyBytes[lengData.length+1+i]);
       // DLog(@"%d 校验位==%d",(int)keyBytes[lengData.length+1+i],keyBytes[length+lengData.length]);

    }


    NSData* decodeStringData = [NSData dataWithBytes:keyBytes
                                              length:stringLength+2+lengData.length];
    free(keyBytes);
    return decodeStringData  ;
}
- (NSData *)encodeWithInt:(int )key
{
    
    NSData *keyData = [NSData dataWithBytes: &key length: sizeof(key)];
   // DLog(@"%@ %d",keyData,keyData.length);
    
    char *dataBytes=malloc(sizeof(key) );
    for (int i = 0; i<keyData.length; i ++) {
        
        dataBytes[i] =(char) key>>8*i;
        //DLog(@"%d %d",( int)dataBytes[i], key>>8*i);
        
    }
    
    
    NSUInteger length=keyData.length+1;
   
    NSData *lengData = [NSData dataWithBytes: &length length: sizeof(length)];
    //DLog(@"%@ %d",lengData,lengData.length);
    
    char *lengthBytes=malloc(sizeof(length) );
    for (int i = 0; i<lengData.length; i ++) {
        
        lengthBytes[i] =(char) length>>8*i;
       // DLog(@"%d %d",( int)lengthBytes[i], length>>8*i);
        
    }
    
     char *keyBytes = ( char *)malloc((length+lengData.length+1) );
    keyBytes[0]='K';
    
    for (int i = 1; i<lengData.length+ 1; i ++) {
        
        keyBytes[i] = ( char)lengthBytes[i-1];
        //DLog(@"%d %d",( int)lengthBytes[i-1], keyBytes[i]);
        
    }
    free(lengthBytes);
    
    for (NSUInteger i = 1+lengData.length; i < keyData.length+1+lengData.length; i ++) {
        keyBytes[i] = ( char)(dataBytes[i-1-lengData.length]);
        //DLog(@"%d",( int)keyBytes[i]);
        
    }
    
    keyBytes[length+lengData.length]=keyBytes[1+lengData.length];
    
    for (int i=1; i<length-1; i++) {
        
        keyBytes[length+lengData.length]=( char)(keyBytes[length+lengData.length]^keyBytes[lengData.length+1+i]);
        //DLog(@"%d 校验位==%d",(int)keyBytes[lengData.length+1+i],keyBytes[length+lengData.length]);
        
    }
    
    NSData* decodeStringData = [NSData dataWithBytes:keyBytes
                                              length:keyData.length+2+lengData.length];
    free(keyBytes);
    return decodeStringData  ;
}

- (NSArray*) arrayOfBytesFromData:(NSData*) data
{
    if (data.length > 0)
    {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:data.length];
        NSUInteger i = 0;
        
        for (i = 0; i < data.length; i++)
        {
            unsigned char *stringBytes = (unsigned char *)[data bytes];
            unsigned char  byteFromArray = stringBytes[i];
            [array addObject:[NSValue valueWithBytes:&byteFromArray
                                            objCType:@encode(unsigned char)]];
        }
        
        return [NSArray arrayWithArray:array];
    }
    return nil;
}

@end
