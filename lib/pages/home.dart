import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';


class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [];

  @override
  void initState() { 
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  @override
  void dispose() { 
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  _handleActiveBands( dynamic payload ){

    this.bands = (payload as List)
      .map((band) => Band.fromMap(band)).toList();

    setState(() {
      
    });

  }

  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'BandNames',
          style: TextStyle(
            color: Colors.black87
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ( socketService.serverStatus == ServerStatus.Online ) 
            ? Icon( Icons.check_circle, color: Colors.blue[300], ) 
            : Icon( Icons.offline_bolt, color: Colors.red,)
          )
        ],
      ),
      body: Column(
        children: [
          ( bands.isNotEmpty )
          ? _showGraph()
          : Text(
            'Not band',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: ( context, i ) => _bandTile(bands[i])
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        child: Icon( Icons.add ),
        onPressed: addNewBand
      ),
   );
  }

  Widget _bandTile( Band band ) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key( band.id ),
      direction: DismissDirection.startToEnd,
      onDismissed: ( direction ) => socketService.emit('delete-band', { 'id': band.id }),
      background: Container(
        padding: EdgeInsets.only( left: 8.0 ),
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Delete Band',
            style: TextStyle(
              color: Colors.white
            ),
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            band.name.substring(0,2)
          ),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(
          band.name
        ),
        trailing: Text(
          '${ band.votes }',
          style: TextStyle(
            fontSize: 20
          ),
        ),
        onTap: () => socketService.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {

    final textController = new TextEditingController();

    if( Platform.isAndroid ){

      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'New band name: '
          ),
          content: TextField(
            controller: textController,
          ),
          actions: [
            MaterialButton(
              child: Text(
                'Add'
              ),
              elevation: 5,
              textColor: Colors.blue,
              onPressed: () => addBandToList( textController.text ),
            )
          ],
        )
      );

    }


    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'New band name: '
        ),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Add'
            ),
            onPressed: () => addBandToList( textController.text ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'Dismiss'
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      )
    );

    

  }

  void addBandToList( String name) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    if( name.length > 1 ){
      // Podemos agregar
      socketService.emit('add-band', { 'name': name });

    }

    Navigator.pop(context);

  }


  // Mostrar grafica

  Widget _showGraph(){
    Map<String, double> dataMap = {};

    bands.forEach((band) {
      dataMap.putIfAbsent( band.name , () => band.votes.toDouble());
    });

    final List<Color> colorList = [
      Colors.blue[100],
      Colors.blue[300],
      Colors.teal[100],
      Colors.teal[300],
      Colors.deepPurple[100],
      Colors.deepPurple[300],
    ];

    return Container(
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
        child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 30,
        chartRadius: MediaQuery.of(context).size.width / 3.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 25,
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
        ),
        legendOptions: LegendOptions(
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

      )
    ); 

  }
  
}