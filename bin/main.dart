import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

Socket socket;
ServerSocket serverSocket;
    
void main() {
  InitializeTCP(5556,true).startListening();
}



 /// construction of InitializeTCP [port],[send ACK]
 /// [port]: your local server port to listen for clients connection (Medical Instrument).
 /// [send ACK]: send ACK character back to the Medical Instrument. Some instruments require that to ensure data delivery.
class InitializeTCP {
  final int _port;
  final bool _sendACK;

  Socket _socket;
  ServerSocket _serverSocket;

  void startListening() async {
    var server = ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
    await server.then((ss) {
      _serverSocket = ss;
        ss.listen((s) {
        _socket = s;
          s.listen((event) {
            handleData(event);
          });
        });
    });
  }

  void handleData(Uint8List data) async{
    // decode the received data
    var incomingData = AsciiCodec().decode(data);
    print('Received: ' + _readableData(incomingData));
    switch (data.first) {
      case 00:
        // Had to add this because for some reason VS Code won't close the port when run/debug is stopped.
        print('Close character received');
        await _socket.close();
        await _serverSocket.close();     
        break;
      case 06:
        // This is an example of sending a string to the instrument.
        sendData(AsciiCodec().encode('test string'));
        break;
      case 07:
        // This is an example of sending string between characters.
        sendData([03] + AsciiCodec().encode('test string between Ascii characters') + [04]);
        break;
      default:
        // If [sendACK] is set to true, the server will reply with acknowledgement character back to the instrument. 
        if(_sendACK) sendData([06]);
    }
  }

  void sendData(List<int> data) {
    if(_socket != null) {
      _socket.add(data);
      print('Sent: ' + _readableData(AsciiCodec().decode(data)));
    }
  }

  Set low = {
    '<NUL>', '<SOH>', '<STX>', '<ETX>', '<EOT>', '<ENQ>', '<ACK>', '<BEL>',
    '<BS>', '<HT>', '<LF>', '<VT>', '<FF>', '<CR>', '<SO>', '<SI>',
    '<DLE>', '<DC1>', '<DC2>', '<DC3>', '<DC4>', '<NAK>', '<SYN>', '<ETB>',
    '<CAN>', '<EM>', '<SUB>', '<ESC>', '<FS>', '<GS>', '<RS>', '<US>'
  };

  String _readableData(String str) {
    // we use this function to convert ASCII code characters to more readable form. for example 6 or 0006 will be converted to <ACK>
    var display = '';
    str.codeUnits.forEach((element) {
      if (element < 32) {
        // element or character here is a ASCII code character
        display += low.elementAt(element);
      } else {
        // we decode other characters back to its origional form as it's a printable character. There could be another easier method for this function.
        display += AsciiCodec().decode([element]);
      }
    });
    return display;
  }

  InitializeTCP(this._port,this._sendACK);
}
