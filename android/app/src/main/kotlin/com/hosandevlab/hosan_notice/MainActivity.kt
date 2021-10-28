package com.hosandevlab.hosan_notice

import android.bluetooth.BluetoothAdapter
import com.hosandevlab.hosan_notice.pigeon.Pigeon.*
import com.hosandevlab.hosan_notice.pigeon.Pigeon.Api
import com.minew.beacon.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity(), Api {
    private lateinit var mMinewBeaconManager: MinewBeaconManager
    private var rangeBeacons: MutableList<MinewBeacon> = mutableListOf()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Api.setup(flutterEngine.dartExecutor.binaryMessenger, this)
        mMinewBeaconManager = MinewBeaconManager.getInstance(this)
        mMinewBeaconManager.setDeviceManagerDelegateListener(object : MinewBeaconManagerListener {
            override fun onAppearBeacons(minewBeacons: MutableList<MinewBeacon>) {
                rangeBeacons = minewBeacons
            }

            override fun onDisappearBeacons(minewBeacons: MutableList<MinewBeacon>) {
                rangeBeacons = minewBeacons
            }

            override fun onRangeBeacons(minewBeacons: MutableList<MinewBeacon>) {
                rangeBeacons = minewBeacons
            }

            override fun onUpdateState(p0: BluetoothState?) {}

        })
    }

    override fun startScan() {
        mMinewBeaconManager.startScan()
    }

    override fun stopScan() {
        mMinewBeaconManager.stopScan()
    }

    override fun getScannedBeacons(): MutableList<MinewBeaconData> {
        val beaconData = rangeBeacons.map {
            val data = MinewBeaconData()
            data.uuid = it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_UUID).stringValue
            data.name = it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_Name).stringValue
            data.major =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_Major).stringValue
            data.minor =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_Minor).stringValue
            data.mac = it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_MAC).stringValue
            data.rssi =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_RSSI).intValue.toLong()
            data.batteryLevel =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_BatteryLevel).intValue.toLong()
            data.temperature =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_Temperature).floatValue.toDouble()
            data.humidity =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_Humidity).floatValue.toDouble()
            data.txPower =
                it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_TxPower).intValue.toLong()
            data.inRange = it.getBeaconValue(BeaconValueIndex.MinewBeaconValueIndex_InRage).isBool
            data
        }.toMutableList()

        return beaconData
    }

    override fun getScannedBeaconsAsMap(): MutableList<MutableMap<Any, Any>> {
        val beaconData = this.scannedBeacons.map {
            val beaconDataMap = mutableMapOf<String, Any>()
            beaconDataMap["uuid"] = it.uuid
            beaconDataMap["name"] = it.name
            beaconDataMap["major"] = it.major
            beaconDataMap["minor"] = it.minor
            beaconDataMap["mac"] = it.mac
            beaconDataMap["rssi"] = it.rssi
            beaconDataMap["batteryLevel"] = it.batteryLevel
            beaconDataMap["temperature"] = it.temperature
            beaconDataMap["humidity"] = it.humidity
            beaconDataMap["txPower"] = it.txPower
            beaconDataMap["inRange"] = it.inRange

            @Suppress("UNCHECKED_CAST")
            beaconDataMap as MutableMap<Any, Any>
        }.toMutableList()

        return beaconData
    }

    override fun enableBluetooth() {
        val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        val isEnabled: Boolean = bluetoothAdapter.isEnabled
        if (!isEnabled) {
            bluetoothAdapter.enable()
        }
    }
}
