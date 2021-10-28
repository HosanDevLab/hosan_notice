// Autogenerated from Pigeon (v1.0.7), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import <Foundation/Foundation.h>
@protocol FlutterBinaryMessenger;
@protocol FlutterMessageCodec;
@class FlutterError;
@class FlutterStandardTypedData;

NS_ASSUME_NONNULL_BEGIN

@class BKMinewBeaconData;

@interface BKMinewBeaconData : NSObject
@property(nonatomic, copy, nullable) NSString * uuid;
@property(nonatomic, copy, nullable) NSString * name;
@property(nonatomic, copy, nullable) NSString * major;
@property(nonatomic, copy, nullable) NSString * minor;
@property(nonatomic, copy, nullable) NSString * mac;
@property(nonatomic, strong, nullable) NSNumber * rssi;
@property(nonatomic, strong, nullable) NSNumber * batteryLevel;
@property(nonatomic, strong, nullable) NSNumber * temperature;
@property(nonatomic, strong, nullable) NSNumber * humidity;
@property(nonatomic, strong, nullable) NSNumber * txPower;
@property(nonatomic, strong, nullable) NSNumber * inRange;
@end

/// The codec used by BKApi.
NSObject<FlutterMessageCodec> *BKApiGetCodec(void);

@protocol BKApi
- (nullable NSArray<BKMinewBeaconData *> *)getScannedBeaconsWithError:(FlutterError *_Nullable *_Nonnull)error;
- (nullable NSArray<NSDictionary *> *)getScannedBeaconsAsMapWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)startScanWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)stopScanWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)enableBluetoothWithError:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void BKApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<BKApi> *_Nullable api);

NS_ASSUME_NONNULL_END
