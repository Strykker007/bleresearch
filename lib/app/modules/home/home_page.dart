import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'home_store.dart';
import 'widgets/device_screen.dart';
import 'widgets/scan_result_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ModularState<HomePage, HomeStore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roshe BlueSync'),
        elevation: 0,
      ),
      body: _buildDevicesStream,
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () => FlutterBlue.instance.startScan(
                timeout: Duration(seconds: 5),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildServiceOff({BluetoothState state}) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            ),
          ],
        ),
      ),
    );
  }

  Widget get _buildDevicesStream {
    return StreamBuilder(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return _buildFindDevices;
        }
        return _buildServiceOff(state: state);
      },
    );
  }

  Widget get _buildFindDevices {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: Colors.green,
            child: Text('Connected Devices:'),
          ),
          StreamBuilder<List<BluetoothDevice>>(
            stream: Stream.periodic(
              Duration(seconds: 2),
            ).asyncMap((_) => FlutterBlue.instance.connectedDevices),
            initialData: [],
            builder: (c, snapshot) => Column(
              children: snapshot.data
                  .map(
                    (d) => ListTile(
                      title: Text(d.name),
                      subtitle: Text(d.id.toString()),
                      trailing: StreamBuilder<BluetoothDeviceState>(
                        stream: d.state,
                        initialData: BluetoothDeviceState.disconnected,
                        builder: (c, snapshot) {
                          if (snapshot.data == BluetoothDeviceState.connected) {
                            return RaisedButton(
                              child: Text('OPEN'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DeviceScreen(device: d),
                                ),
                              ),
                            );
                          }
                          return Text(snapshot.data.toString());
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            child: Text('Available Devices:'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => FlutterBlue.instance.startScan(
                timeout: Duration(seconds: 4),
              ),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: RefreshIndicator(
                  onRefresh: () => FlutterBlue.instance.startScan(
                    timeout: Duration(seconds: 4),
                  ),
                  child: StreamBuilder<List<ScanResult>>(
                    stream: FlutterBlue.instance.scanResults,
                    initialData: [],
                    builder: (c, snapshot) => Column(
                      children: snapshot.data.map((r) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: ScanResultTile(
                                result: r,
                              ),
                            ),
                            RaisedButton(
                              child: Text('CONNECT'),
                              color: Colors.green,
                              textColor: Colors.white,
                              onPressed: () async {
                                r.device.connect(
                                  autoConnect: false,
                                );

                                // r.device
                                //     .discoverServices()
                                //     .timeout(Duration(seconds: 5))
                                //     .whenComplete(
                                //       () async => await Future.delayed(
                                //         Duration(seconds: 3),
                                //         () async => await _setconfigs(r.device),
                                //       ),
                                //     );

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return DeviceScreen(device: r.device);
                                      // return Scaffold(
                                      //   appBar: AppBar(
                                      //     title: Text('Teste'),
                                      //   ),
                                      // );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> _setconfigs(BluetoothDevice device) async {
  //   // BluetoothCharacteristic notifyCharacteristic;
  //   // BluetoothCharacteristic writeCharacteristic;
  //   BluetoothDescriptor descriptor;

  //   if (Platform.isAndroid) {
  //     try {
  //       log('iniciando negociacao do mtu');
  //       await device
  //           .requestMtu(23)
  //           .timeout(Duration(seconds: 2))
  //           .then((value) async {
  //         device.mtu.listen((event) {
  //           log('MTU negociado com sucesso: Size-> ' + event.toString());
  //         });
  //       }).catchError((onError) {
  //         log('Error ' + onError.toString());
  //       });
  //     } catch (e) {
  //       log('erro ao negociar o MTU' + e.toString());
  //     }
  //   }

  //   await Future.delayed(
  //     Duration(seconds: 2),
  //     () {
  //       device.services.forEach(
  //         (listServices) {
  //           listServices.forEach(
  //             (service) {
  //               if (service.uuid.toString().contains('1808')) {
  //                 service.characteristics.forEach(
  //                   (characteristic) async {
  //                     if (characteristic.uuid.toString().contains('2a18')) {
  //                       print('Caracteristica 2a18');

  //                       try {
  //                         log('configurando descriptor 2a18' +
  //                             characteristic.descriptors.first.uuid.toString());
  //                         descriptor = characteristic.descriptors.first;
  //                       } catch (e) {
  //                         log('Erro ao configurar o descriptor ' +
  //                             e.toString());
  //                       }
  //                       try {
  //                         log('configurando notificações');
  //                         // await characteristic
  //                         //     .setNotifyValue(true)
  //                         //     .timeout(Duration(seconds: 1));
  //                         Future.delayed(Duration(seconds: 2));
  //                       } catch (e) {
  //                         log('Erro ao notificar a caracteristica 2a18 ' +
  //                             e.toString());
  //                       }
  //                     }
  //                     if (characteristic.uuid.toString().contains('2a52')) {
  //                       print('Caracteristica 2a52');

  //                       try {
  //                         log('configurando descriptor 2a52');
  //                         // await characteristic.descriptors.first
  //                         //     .write(Uint8List.fromList([1, 00]))
  //                         //     .timeout(Duration(seconds: 1));
  //                         Future.delayed(Duration(seconds: 2));
  //                       } catch (e) {
  //                         log('Erro ao criar a indicação do descriptor ' +
  //                             e.toString());
  //                       }
  //                       try {
  //                         print('Escrevendo RACP...');
  //                         // await characteristic
  //                         //     .write(Uint8List.fromList([1, 00]))
  //                         //     .timeout(Duration(seconds: 1));
  //                         Future.delayed(Duration(seconds: 2));
  //                       } catch (e) {
  //                         log('Erro ao notificar a caracteristica 2a52 ' +
  //                             e.toString());
  //                       }
  //                     }
  //                   },
  //                 );
  //               }
  //             },
  //           );
  //         },
  //       );
  //     },
  //   );
  //   // await descriptor.write([1, 0]).timeout(Duration(seconds: 2)).then(
  //   //       (value) => descriptor.value.listen(
  //   //         (event) {
  //   //           log('Valor do descriptor ' + event.toString());
  //   //         },
  //   //       ),
  //   //     );
  // }
}
