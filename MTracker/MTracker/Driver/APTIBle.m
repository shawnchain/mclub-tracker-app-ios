//
//  APTIBle.m
//  MTracker
//
//  Created by Shawn Chain on 16/12/3.
//  Copyright © 2016年 MClub. All rights reserved.
//

#import "APTIBle.h"
#import <CoreBluetooth/CoreBluetooth.h>


typedef enum{
    IDLE = 0,
    SCANNING,
    CONNECTING,
    CONNECTED,
    DISCOVERING_SERVICE,
    DISCOVERING_CHARS,
}APTIState;

@interface APTIBle()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong) APTIBleCallback callback;
@property(nonatomic,strong) CBCentralManager *centralManager;
@property(nonatomic,strong) CBPeripheral *connectedDevice;

@property(nonatomic,strong) CBCharacteristic *tncCtrlPort;
@property(nonatomic,strong) CBCharacteristic *tncDataPort;



@property(nonatomic,strong) CBUUID *tncServiceUUID;
@property(nonatomic,strong) CBUUID *tncCtrlPortUUID;
@property(nonatomic,strong) CBUUID *tncDataPortUUID;

@property(nonatomic,strong) NSTimer *timer; // timer for the operation timeout

@property(nonatomic,assign) APTIState state;
@end

@implementation APTIBle

-(id) initWithCallback:(APTIBleCallback) cb{
    self = [super init];
    if(self){
        self.tncServiceUUID = [CBUUID UUIDWithShort:0xC001];
        self.tncCtrlPortUUID = [CBUUID UUIDWithShort:0xC002];
        self.tncDataPortUUID = [CBUUID UUIDWithShort:0xC003];
        self.callback = cb;
    }
    return self;
}

#define OPERATION_TIMEOUT 5
-(void) _startTimer{
    if(self.timer.isValid) return;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:OPERATION_TIMEOUT target:self selector:@selector(onTimeout:) userInfo:nil repeats:NO];
}

-(void)_stopTimer{
    [self.timer invalidate];
    self.timer = nil;
}

-(void) startScan{
    if(self.centralManager.isScanning) return;
    
    if(self.centralManager == nil){
        // start the bluetooth peripheral and perform the connect
        self.centralManager = [[CBCentralManager alloc] init];
        self.centralManager.delegate = self;
    }
    NSArray *servicesToDiscover = @[self.tncServiceUUID];
    [self.centralManager scanForPeripheralsWithServices:servicesToDiscover options:nil];
    self.state = SCANNING;
    [self _startTimer];
}

-(void) connect{
    [self startScan];
}

-(void) disconnect{
    // connect failed
    self.state = IDLE;
    [self _stopTimer];
    
    self.tncCtrlPort = nil;
    self.tncDataPort = nil;
    
    if(self.connectedDevice){
        self.connectedDevice.delegate = nil;
        self.connectedDevice = nil;
    }
    
    if(self.centralManager){
        if(self.centralManager.isScanning){
            [self.centralManager stopScan];
        }
        self.centralManager.delegate = nil;
        self.centralManager = nil;
    }
}

-(void) onTimeout:(NSTimer*)timer{
    if(self.callback){
        self.callback(self,APTI_TIMEOUT,nil);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CentralManager Delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    // check if has permission
    switch (central.state) {
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManager state: unauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            //self.state = IDLE;
            NSLog(@"CBCentralManager state: powered off");
             /*
             if(self.scanHandler){
                JLCBScanHandler handler = self.scanHandler;
                // complete the scan operation
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil);
                });
                self.scanHandler = nil;
            }
             */
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManager state: powered on");
            break;
            
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManager state: unknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManager state: resetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManager state: unsupported");
            break;
        default:
            //Should not be here
            NSLog(@"Unknow state of CBCentralManager %@/%u",central,(unsigned int)central.state);
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central  didDiscoverPeripheral:(CBPeripheral *)peripheral
                                                        advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                                                                    RSSI:(NSNumber *)RSSI
{
    // do connect
    [self _stopTimer];
    [central connectPeripheral:peripheral options:nil];
    self.state = CONNECTING;
    [self _startTimer];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    // discover services
    [self _stopTimer];
    self.connectedDevice = peripheral;
    self.connectedDevice.delegate = self;
    self.state = CONNECTED;
    [self.connectedDevice discoverServices:@[self.tncServiceUUID]];
    self.state = DISCOVERING_SERVICE;
    [self _startTimer];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{

    // connect failed
    [self disconnect];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    // connection lost
    [self disconnect];
}

/////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Peripheral Delegate
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    // Update UI of the peripheral name change.
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices{
    // device changed services, eg: authenticated user could access more services
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error{
    // Update UI for the RSSI changes
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    if(error){
        NSLog(@"Error discover service: %@",error);
        return;
    }

    for(CBService *svc in peripheral.services){
        if([svc.UUID isEqual:self.tncServiceUUID]){
            // got the service by uuid
            [self _stopTimer];
            //self.tncService = svc;
            // discover characters
            [peripheral discoverCharacteristics:@[self.tncDataPortUUID,self.tncCtrlPortUUID] forService:svc];
            self.state = DISCOVERING_CHARS;
            [self _startTimer];
            return;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    if(error){
        NSLog(@"Error discover characters: %@",error);
        return;
    }
    
    for(CBCharacteristic *chr in service.characteristics){
        if([chr.UUID isEqual:self.tncCtrlPort]){
            self.tncCtrlPort = chr;
            // subscribe for the notifications
            [service.peripheral setNotifyValue:YES forCharacteristic:chr];
        }else if([chr.UUID isEqual:self.tncDataPort]){
            self.tncDataPort = chr;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if(error){
        NSLog(@"Error read value from character %@",characteristic);
        return;
    }
    
    if([characteristic.UUID isEqual:self.tncCtrlPortUUID]){
        // the ctrl port notification for received frame
        
        NSUInteger rxFrameCount = [characteristic uint32Value];
        if(rxFrameCount > 0 && self.tncDataPort){
            // start read the data port value
            [self.connectedDevice readValueForCharacteristic:self.tncDataPort];
            NSLog(@"Received tnc rx frame count: %lu",rxFrameCount);
        }else{
            NSLog(@"Received tnc ctrl value: %@",[characteristic stringValue]);
        }
        
    }else if([characteristic.UUID isEqual:self.tncDataPortUUID]){
        // the data port notification
        if(self.callback){
            self.callback(self,APTI_NO_ERROR,characteristic.value);
        }
    }
}

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if(error){
        NSLog(@"Error write value for character %@",characteristic);
        return;
    }
}

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
}

/*!
 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
}

/*!
 *  @method peripheral:didUpdateValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CB Extensions
@implementation CBCharacteristic (APTIBle)

-(NSString*) stringValue{
    NSData *data = self.value;
    if(!data){
        return nil;
    }
    return [NSString stringWithCString:data.bytes encoding:NSASCIIStringEncoding];
}

-(NSUInteger)uint32Value{
    NSUInteger i = 0;
    
    NSData *data = self.value;
    if(!data|| data.length != 4) return 0;
    
    char* bytes = (char*)data.bytes;
    i = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
    return i;
}

@end

@implementation CBUUID (APTIBle)

+(CBUUID*)UUIDWithShort:(unsigned short) value{
    //FIXME swap the byte order ?
    unsigned short value2 = ((value <<8 & 0xff00) | (value >>8 & 0xff)) & 0xffff;
    NSData *data = [NSData dataWithBytes:&value2 length:2];
    return [self UUIDWithData:data];
}

-(unsigned short) shortValue{
    unsigned short v = 0;
    NSData *data = self.data;
    if(data.length ==2){
        char *c = (char*)data.bytes;
        v = ((*(c) << 8) | (*(c+1))) & 0xffff;
    }
    return v;
}
@end