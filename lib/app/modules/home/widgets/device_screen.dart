import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'scan_result_tile.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key key, @required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (BluetoothCharacteristic c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () async {
                      await c.read();
                    },
                    onWritePressed: () async {
                      // print(_getRandomBytes());
                      try {
                        await c.write(
                          Uint8List.fromList([1, 1]),
                          withoutResponse: false,
                        );
                        log('escrita realizada com sucesso!');

                        // await c.read().then((value) {
                        //   print('leitura');
                        //   print(value);
                        // });
                      } catch (e) {
                        log('Erro ao escrever ' + e.toString());
                      }
                    },
                    onNotificationPressed: () async {
                      try {
                        await c.setNotifyValue(true);
                      } catch (e) {
                        log('Erro ao notificar ' + e.toString());
                      }
                    },
                    // descriptorTiles: c.descriptors
                    //     .map(
                    //       (d) => DescriptorTile(
                    //         descriptor: d,
                    //         onReadPressed: () => d.read(),
                    //         onWritePressed: () async {
                    //           try {
                    //             await d.write(
                    //               Uint8List.fromList([0, 2]),
                    //             );
                    //           } catch (e) {
                    //             print(e);
                    //           }
                    //         },
                    //       ),
                    //     )
                    //     .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () async {
                    await device.connect();
                  };
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                onPressed: onPressed,
                child: Text(
                  text,
                  style: Theme.of(context)
                      .primaryTextTheme
                      .button
                      ?.copyWith(color: Colors.white),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () async {
                            // await setConfigs;
                            List<BluetoothService> services =
                                await device.discoverServices();
                            await _setDescriptorConfig(services);
                          }),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async => await device.requestMtu(185),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(children: _buildServiceTiles(snapshot.data));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDescriptorConfig(List<BluetoothService> services) async {
    // BluetoothCharacteristic notifyCharacteristic;
    // BluetoothCharacteristic writeCharacteristic;

    // if (Platform.isAndroid) {
    try {
      log('iniciando negociacao do mtu');
      await device
          .requestMtu(23)
          .timeout(Duration(seconds: 2))
          .then((value) async {
        device.mtu.listen((event) {
          log('MTU negociado com sucesso: Size-> ' + event.toString());
        });
      }).catchError((onError) {
        log('Error ' + onError.toString());
      });
    } catch (e) {
      log('erro ao negociar o MTU' + e.toString());
    }
    // }

    services.forEach(
      (service) {
        if (service.uuid.toString().contains('1808')) {
          service.characteristics.forEach(
            (characteristic) async {
              if (characteristic.uuid.toString().contains('2a18')) {
                print('Caracteristica 2a18');
                try {
                  await characteristic.descriptors.first.write([0, 1]);
                  log('Descriptor configurado com sucesso!!');
                } catch (e) {
                  log('Erro ao configurar o descriptor 2902 da caracteristica' +
                      '\n' +
                      e.toString());
                }
                try {
                  log('configurando notificações');
                  // await characteristic
                  //     .setNotifyValue(true)
                  //     .timeout(Duration(seconds: 1));
                  Future.delayed(Duration(seconds: 2));
                } catch (e) {
                  log('Erro ao notificar a caracteristica 2a18 ' +
                      e.toString());
                }
              }
              // if (characteristic.uuid.toString().contains('2a52')) {
              //   print('Caracteristica 2a52');

              //   try {
              //     log('configurando descriptor 2a52');
              //     // await characteristic.descriptors.first
              //     //     .write(Uint8List.fromList([1, 00]))
              //     //     .timeout(Duration(seconds: 1));
              //     Future.delayed(Duration(seconds: 2));
              //   } catch (e) {
              //     log('Erro ao criar a indicação do descriptor ' +
              //         e.toString());
              //   }
              //   try {
              //     print('Escrevendo RACP...');
              //     // await characteristic
              //     //     .write(Uint8List.fromList([1, 00]))
              //     //     .timeout(Duration(seconds: 1));
              //     Future.delayed(Duration(seconds: 2));
              //   } catch (e) {
              //     log('Erro ao notificar a caracteristica 2a52 ' +
              //         e.toString());
              //   }
              // }
            },
          );
        }
      },
    );
    // await descriptor.write([1, 0]).timeout(Duration(seconds: 2)).then(
    //       (value) => descriptor.value.listen(
    //         (event) {
    //           log('Valor do descriptor ' + event.toString());
    //         },
    //       ),
    //     );
  }
}
// print('Configurando o dispositivo...');

//segundo loop para garantir que a caracteristica 2a52 seja escrita primeiro

// device.services.forEach(
//   (listServices) {
//     listServices.forEach(
//       (service) {
//         if (service.uuid.toString().contains('1808')) {
//           service.characteristics.forEach(
//             (characteristic) async {
//               if (characteristic.uuid.toString().contains('2a18')) {
//                 print('Caracteristica 2a18');
//                 print('configurando notificações');
//                 try {
//                   await characteristic.setNotifyValue(true);
//                 } catch (e) {
//                   log('Erro ao notificar a caracteristica 2a18 ' +
//                       e.toString());
//                 }
//               }
//             },
//           );
//         }
//       },
//     );
//   },
// );
// device.services.forEach(
//   (listServices) {
//     listServices.forEach(
//       (service) {
//         if (service.uuid.toString().contains('1808')) {
//           service.characteristics.forEach(
//             (characteristic) async {
//               // log(characteristic.uuid.toString());
//               if (characteristic.uuid.toString() ==
//                   '00002a52-0000-1000-8000-00805f9b34fb') {
//                 print('Caracteristica 2a52');
//                 print('realizando escrita de RACP');
//                 await Future.delayed(Duration(seconds: 2));
//                 try {
//                   await characteristic.write([1, 1]);
//                   characteristic.value.listen((event) {});
//                 } catch (e) {
//                   log('Erro ao escrever para a caracteristica 2a52 ' +
//                       e.toString());
//                 }
//               }
//             },
//           );
//         }
//       },
//     );
//   },
// );
